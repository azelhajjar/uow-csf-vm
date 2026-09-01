# Activity: SMTP Enumeration

## Summary

Reconnaissance of the newly added Postfix mail service, using nmap NSE scripts as the primary discovery method before manual protocol confirmation. Confirms the server operates as an open relay and discloses its supported commands and capabilities, and investigates two separate, genuine NSE reliability problems encountered along the way: `smtp-enum-users` initially appearing to enumerate accounts that don't exist on this system at all (a wordlist/argument-naming issue, resolved), and then, once resolved, reporting a definitively rejected username as a valid hit anyway (a genuine script false-positive, not resolved, and documented as such).

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | Postfix (Debian/GNU), port 25/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nmap NSE (`smtp-commands`, `smtp-open-relay`, `smtp-enum-users`, `smtp-vuln-cve2010-4344`, `smtp-vuln-cve2011-1720`, `smtp-vuln-cve2011-1764`), nc (manual confirmation) |

## Reconnaissance

### Step 1: Discovering available NSE tooling

```bash
ls -l /usr/share/nmap/scripts/ | grep -i smtp
```

```
smtp-brute.nse
smtp-commands.nse
smtp-enum-users.nse
smtp-ntlm-info.nse
smtp-open-relay.nse
smtp-strangeport.nse
smtp-vuln-cve2010-4344.nse
smtp-vuln-cve2011-1720.nse
smtp-vuln-cve2011-1764.nse
```

A substantial SMTP script set exists, three scripts were selected as directly relevant to this activity: `smtp-commands` (banner/capability enumeration), `smtp-open-relay` (dedicated relay testing), and `smtp-enum-users` (account enumeration). The three CVE-specific scripts were also run for completeness, since they cost little to check even without a specific prior reason to suspect those exact vulnerabilities.

### Step 2: Banner and capability enumeration

```bash
nmap -p 25 --script smtp-commands 192.168.144.200
```

```
|_smtp-commands: mail.uow-csf.internal, PIPELINING, SIZE 10240000, VRFY, ETRN, STARTTLS, ENHANCEDSTATUSCODES, 8BITMIME, DSN, SMTPUTF8, CHUNKING
```

Confirms the server's identity and advertised capabilities in a single query, including `VRFY` being listed as supported (though, as established later in this activity and corroborating `e-17`, `VRFY` itself proves unreliable for genuine enumeration on this Postfix build).

### Step 3: Open relay detection

```bash
nmap -p 25 --script smtp-open-relay 192.168.144.200
```

```
|_smtp-open-relay: Server is an open relay (16/16 tests)
```

A clean, unambiguous positive result: 16 out of 16 relay tests succeeded. Unlike several NSE scripts encountered elsewhere in this project, this one worked correctly and reliably on the first attempt, providing fast, high-confidence confirmation of the finding later demonstrated manually in `e-17- smtp-open-relay-and-user-enumeration.md`.

### Step 4: User enumeration, first attempt (misleading default result)

```bash
nmap -p 25 --script smtp-enum-users 192.168.144.200
```

```
| smtp-enum-users:
|   root
|   admin
|   administrator
|   webadmin
|   sysadmin
|   netadmin
|   guest
|   user
|   web
|_  test
```

**This result is misleading and should not be trusted at face value.** None of the ten reported usernames correspond to any real account on this target (the actual accounts are `analyst`, `webops`, `backupsvc`, `druid`, `distccd`, `aberrant_distance`, `uow-admin`, `student`). This output is simply the script's built-in generic default wordlist being reported back, not genuine findings specific to this host, since no target-specific username list was supplied.

### Step 5: Supplying a real username list (argument-naming detour)

To test against actual known accounts, a small target-specific wordlist was created:
```bash
printf "analyst\nwebops\nbackupsvc\nnonexistentuser123\n" > /tmp/real_users.txt
```

An initial attempt to point the script at this file failed silently (still returning the default wordlist) using an incorrectly guessed argument name:
```bash
nmap -p 25 --script smtp-enum-users --script-args smtp-enum-users.methods=RCPT,smtp-enum-users.userdb=/tmp/real_users.txt 192.168.144.200
```

Checking the script's actual source confirmed the correct argument:
```bash
grep -i "unpwdb\|require" /usr/share/nmap/scripts/smtp-enum-users.nse
```
```
local unpwdb = require "unpwdb"
local status, nextuser = unpwdb.usernames()
```

The script uses nmap's shared `unpwdb` library, whose standard argument is the unprefixed `userdb`, not a script-specific `smtp-enum-users.userdb`. Correcting this:
```bash
nmap -p 25 --script smtp-enum-users --script-args userdb=/tmp/real_users.txt 192.168.144.200
```
```
| smtp-enum-users:
|   analyst
|   webops
|   backupsvc
|_  nonexistentuser123
```

### Step 6: A second, genuine NSE reliability problem

**This result also requires scrutiny rather than being accepted directly.** `nonexistentuser123` is deliberately fake, included specifically as a negative control, yet it appears in the script's output identically to the three genuinely real accounts. Manual testing (see Step 7, and `e-17`) already independently confirmed the real server response to `RCPT TO: nonexistentuser123@uow-csf.internal` is `550 5.1.1 ... User unknown in local recipient table`, an explicit rejection. Debug output confirms the script itself labels this as a `RCPT`-method success regardless:
```bash
nmap -p 25 --script smtp-enum-users --script-args userdb=/tmp/real_users.txt -d 192.168.144.200 2>&1 | grep -i "RCPT"
```
```
|   RCPT, analyst
|   RCPT, webops
|   RCPT, backupsvc
|_  RCPT, nonexistentuser123
```

**This is a genuine false-positive bug in `smtp-enum-users` on this Postfix configuration, not an argument-naming or wordlist issue.** Unlike Step 4-5's resolvable problem, this one was not resolved through correct configuration; the script itself misreports a definitively rejected recipient as a valid finding. This is recorded honestly as a script reliability limitation, consistent with the broader pattern of NSE inconsistency already documented across this project (see `r-04- ftp-banner-grab-and-anonymous-access.md`): automated tooling can produce false positives just as readily as false negatives, and every automated finding, especially ones with real consequences (acting on a supposedly valid username), should be independently corroborated before being trusted.

### Step 7: Manual RCPT TO confirmation

To resolve the discrepancy definitively, manual protocol interaction was used, the same reliable technique already established:

```bash
nc -nv 192.168.144.200 25
```
```
HELO test.local
MAIL FROM: attacker@evil.com
RCPT TO: analyst@uow-csf.internal
RCPT TO: nonexistentuser123@uow-csf.internal
```
```
250 2.1.5 Ok
550 5.1.1 <nonexistentuser123@uow-csf.internal>: Recipient address rejected: User unknown in local recipient table
```

This confirms manual interaction gives the correct, trustworthy result (`analyst` valid, `nonexistentuser123` explicitly rejected) precisely where the NSE script's own summary output did not. `analyst`, `webops`, and `backupsvc` are the genuinely confirmed real accounts; `nonexistentuser123`'s appearance in the NSE output should be disregarded as the script's false positive.

### Step 8: CVE-specific checks

```bash
nmap -p 25 --script smtp-vuln-cve2010-4344,smtp-vuln-cve2011-1720,smtp-vuln-cve2011-1764 192.168.144.200
```

```
| smtp-vuln-cve2010-4344:
|_  The SMTP server is not Exim: NOT VULNERABLE
```

A clean, trustworthy negative result, correctly identifying that this server (Postfix) is not the vulnerable software (Exim) the check targets, rather than failing silently or ambiguously. The other two scripts produced no output, consistent with them also targeting software/conditions not present on this Postfix build.

## Outcome

Confirmed a working open relay via a reliable NSE script (`smtp-open-relay`, 16/16 tests, corroborating the manual demonstration in `e-17`). SMTP user enumeration required manual `RCPT TO` interaction to fully trust, `smtp-enum-users` needed correct argument configuration to move past its generic default wordlist, and even once correctly configured, produced a genuine false positive for a deliberately fake control username that manual testing definitively disproved. Three real local accounts were confirmed: `analyst`, `webops`, `backupsvc`.

## Remediation

See `e-17- smtp-open-relay-and-user-enumeration.md` for full remediation guidance.

## Teaching Notes

This activity contains two distinct tool-reliability lessons worth separating clearly for students: first, an NSE script can appear to fail simply because of an incorrect or unknown argument name (`smtp-enum-users.userdb` vs. the correct `userdb`), resolved by reading the script's own source rather than guessing; second, and more importantly, an NSE script can be correctly configured and still produce a genuine false positive, which no amount of argument-tuning fixes, only independent manual verification catches. Students should come away distinguishing these two failure modes clearly: "I'm using the tool wrong" is fixable by reading documentation or source; "the tool itself is wrong" requires a completely different technique to catch and correct.

## What is SMTP?

SMTP (Simple Mail Transfer Protocol) is the protocol used to send email between mail servers across the internet, and Postfix is one of the most widely deployed SMTP server implementations on Linux. Because SMTP predates modern security concerns and was designed for an era of mutually trusting mail servers, features like relaying (forwarding mail on behalf of another server) and recipient verification were built with far less restrictive defaults than would be considered acceptable today, which is exactly why open relay and user enumeration remain persistent, real-world-relevant misconfiguration classes even on current, fully patched mail server software.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Confirmed valid local account names via NSE and manual enumeration
**Provides access for:** Precedes `e-17- smtp-open-relay-and-user-enumeration.md`
**Suggested teaching level:** Level 5-6
