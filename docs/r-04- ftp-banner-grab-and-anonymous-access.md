# Activity: FTP Banner Grab and Anonymous Access Enumeration

## Summary

Manual and automated protocol interaction against the FTP service on port 21, distinct from the ProFTPD 1.3.3c supply-chain backdoor exploit documented in `e- 01-proftpd-1.3.3c-backdoor.md`. This activity covers direct banner grabbing and a check for anonymous login, which is a separate misconfiguration from the trojanised-tarball RCE: anonymous access being permitted is an information-disclosure and access-control weakness in its own right, independent of whether the specific ProFTPD build is backdoored. Anonymous login was found to be permitted, granting read access to a home directory containing a note file that references another location in the environment. This activity also compares multiple tools and techniques for reaching the same or related findings (interactive `ftp` client, `curl`, and several nmap NSE scripts), including documenting cases where automated NSE detection failed to corroborate findings that manual interaction had already reliably confirmed.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | ProFTPD 1.3.3c, port 21/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nc, ftp, curl, nmap NSE (`ftp-anon`, `ftp-syst`, `ftp-bounce`, `ftp-proftpd-backdoor`), Metasploit (`auxiliary/scanner/ftp/ftp_version`, `auxiliary/scanner/ftp/ftp_anonymous`) |

## Reconnaissance

### Step 1: Manual banner grab

```bash
nc -nv 192.168.144.200 21
```

```
Connection to 192.168.144.200 21 port [tcp/*] succeeded!
220 ProFTPD 1.3.3c Server (outstandingmailbox) [192.168.144.200]
```

Connecting directly with `nc` (netcat) rather than an FTP client or nmap's version-detection script demonstrates that a service's identifying banner is often available simply by opening a raw TCP connection and reading what the server sends unprompted, no authentication or protocol-specific tooling required. This confirms the ProFTPD 1.3.3c version already identified by nmap in `r- 02-reconnaissance-and-service-enumeration.md`, directly from the service itself rather than via a scanner's inference.

**Observation:** the banner includes a custom server name, `outstandingmailbox`, in place of (or alongside) the actual system hostname. This does not correspond to the target's real hostname (`cav-csf-linux`, confirmed in earlier exploitation activities) and appears to be cosmetic scenario flavour text configured into the ProFTPD `ServerName` directive rather than a meaningful technical finding. Worth noting for completeness, but not something requiring further investigation.

### Step 2: Anonymous login check

```bash
ftp 192.168.144.200
```

```
Connected to 192.168.144.200.
220 ProFTPD 1.3.3c Server (outstandingmailbox) [192.168.144.200]
Name (192.168.144.200:kali): anonymous
331 Anonymous login ok, send your complete email address as your password
Password:
230 Greetings! Welcome to the server.
Remote system type is UNIX.
Using binary mode to transfer files.
```

Attempting the username `anonymous` (the FTP protocol's standard convention for unauthenticated access, per RFC 1635) succeeded immediately, with the server's own response explicitly confirming `Anonymous login ok`. No real credential or complete email address was required as the password despite the prompt's wording; a blank password was accepted. This is a distinct misconfiguration (CWE-284, Improper Access Control, arising from anonymous access being enabled at all) from the ProFTPD 1.3.3c backdoor documented separately, and would remain a finding even against a non-backdoored, fully patched ProFTPD build.

### Step 3: Enumerating accessible content

```
ftp> ls -la
229 Entering Extended Passive Mode (|||64307|)
150 Opening ASCII mode data connection for file list
drwxr-xr-x   2 anon     anon         4096 Aug 22 03:46 .
drwxr-xr-x   2 anon     anon         4096 Aug 22 03:46 ..
-rw-r--r--   1 anon     anon          220 May 15  2017 .bash_logout
-rw-r--r--   1 anon     anon         3526 May 15  2017 .bashrc
-rw-r--r--   1 anon     anon         5290 Jul 12  2023 .face
lrwxrwxrwx   1 anon     anon            5 Jul 12  2023 .face.icon -> .face
-rw-r--r--   1 anon     anon          807 Apr 18  2019 .profile
-rw-r--r--   1 anon     anon          179 Aug 23 04:19 note
226 Transfer complete
```

The anonymous FTP root is a dedicated `anon` home directory. Most of the visible files (`.bash_logout`, `.bashrc`, `.face`, `.face.icon`, `.profile`) are standard Debian skeleton dotfiles, consistent with default account creation rather than anything deliberately placed for this exercise. One file stands out: `note`, with a modification date (23 Aug) far more recent than the others, indicating it was deliberately added as part of the scenario rather than being a default artefact.

### Step 4: Retrieving and reading the note

```
ftp> get note
local: note remote: note
229 Entering Extended Passive Mode (|||43691|)
150 Opening BINARY mode data connection for note (179 bytes)
226 Transfer complete
```

```
ftp> more note
Migration of the legacy application is still pending.
The old database export has been moved to the shared backup location.
Please remove it once the migration has been verified.
```

This is a deliberately placed information-disclosure artefact: the note references a "database export" having been "moved to the shared backup location," which reads as a scenario clue pointing toward another part of the environment. This connection is confirmed: the note is intentionally designed to point toward the NFS share investigated in `e- 02-nfs-anonymous-credential-exposure.md`, which is where the "old database export" (in practice, the backup files disclosing the `backupsvc` credential) is actually found. This is a deliberate cross-service breadcrumb: a student enumerating FTP anonymously should be led toward investigating NFS next, rather than the two services being unrelated islands in the scenario design.

## Additional Enumeration: NSE Scripts and Alternate Tooling

The manual `nc`/`ftp` approach above is one valid method of FTP enumeration; the following demonstrates several alternative and complementary approaches, comparing what each reveals and, importantly, where automated scripts fail to detect a condition that manual interaction had already confirmed.

### NSE: `ftp-anon`

```bash
nmap -p 21 --script ftp-anon 192.168.144.200
```

```
PORT   STATE SERVICE
21/tcp open  ftp
```

**Notable result: `ftp-anon` reported nothing.** This script is specifically designed to check for anonymous FTP access and report it in its output when successful, yet no anonymous-access line appears here, despite anonymous login having already been confirmed manually and reliably in Steps 2–4 above. This is a genuine, documented discrepancy between automated script detection and manual verification, and is a useful teaching moment in its own right: an NSE script producing no output for a condition that is demonstrably true should never be taken as proof that condition is false. Possible causes include script version/timing behaviour, an interaction quirk with this specific ProFTPD build's anonymous login banter (which requests "your complete email address" as the password, a slightly non-standard prompt that could affect how some clients or scripts negotiate the exchange), or an nmap/NSE version-specific issue. This was not root-caused further, but the discrepancy itself is the important finding to document: automated tooling did not corroborate a result that manual protocol interaction had already reliably established.

### NSE: `ftp-bounce`

```bash
nmap -p 21 --script ftp-bounce 192.168.144.200
```

```
NSE: [ftp-bounce] Couldn't resolve scanme.nmap.org, scanning 10.0.0.1 instead.
NSE: [ftp-bounce] PORT response: 500 Illegal PORT command
PORT   STATE SERVICE
21/tcp open  ftp
```

This script tests for the classic FTP bounce vulnerability, where an FTP server's active-mode `PORT` command can be abused to make the server itself initiate connections to arbitrary third-party hosts, effectively using the FTP server as an unwitting network proxy/scanner. By default the script attempts to test connectivity toward `scanme.nmap.org` (Nmap's own public test host) and, when that hostname could not be resolved from this isolated lab network (as expected, since the lab segment has no internet access), fell back to testing against a placeholder address (`10.0.0.1`). The server's response, `500 Illegal PORT command`, indicates ProFTPD rejected the malformed/bounce-style `PORT` command outright.

**Important environmental caveat:** this lab network is deliberately configured as host-only, with no route to the internet whatsoever. This is a considered ethical and pedagogical decision: it ensures that nothing a student does against this target VM can ever reach or affect real internet infrastructure, and it keeps every exercise fully contained within the controlled lab environment. However, it means this specific `ftp-bounce` test did not run under the conditions it was designed for. The script's normal behaviour assumes a real, externally-resolvable target IP (`scanme.nmap.org`) to test the bounce against; here, DNS resolution failed entirely (there being no DNS path out of the lab segment), and the script silently substituted a fallback placeholder address (`10.0.0.1`) that has no real relationship to this environment. A genuinely remote attacker, positioned outside the target's network with working DNS resolution and a real reachable third-party host to specify, might observe different behaviour from the target, this was not tested, and should not be assumed to necessarily produce the same `500 Illegal PORT command` response. **This result should therefore be treated as inconclusive rather than a confirmed, environment-independent negative finding.** It reflects how ProFTPD responded to a malformed/fallback `PORT` command under this lab's specific isolated network conditions, not necessarily how it would respond to a genuine third-party bounce attempt from a real remote position. Testing that condition properly would require either a controlled, ethically-sanctioned external test environment (deliberately out of scope for this teaching lab) or a manually crafted `PORT` command comparison from within the existing lab segment, neither of which was pursued here given the lab's intentional isolation.

### NSE: `ftp-proftpd-backdoor`

```bash
nmap -p 21 --script ftp-proftpd-backdoor 192.168.144.200
```

```
PORT   STATE SERVICE
21/tcp open  ftp
```

**Notable result: this script also reported nothing**, despite the target being confirmed, via the actual Metasploit exploitation in `e-01- proftpd-1.3.3c-backdoor.md`, to be running the genuinely backdoored ProFTPD 1.3.3c build. This is the same class of finding as the `ftp-anon` result above: an NSE script specifically designed to detect this exact vulnerability produced no positive detection, even though the vulnerability is proven to exist and to be exploitable on this target. This is an important, deliberately preserved negative result for teaching purposes: it demonstrates concretely that **a clean NSE vulnerability-scan result must never be treated as proof of absence**. The backdoor's actual trigger mechanism (a hidden FTP command sequence, distinct from ordinary protocol behaviour) may not be reliably detected by this particular script's implementation, its check may rely on server behaviour or timing that didn't align with this build, or the script itself may be outdated relative to how the backdoor manifests. Whatever the specific cause, the practical lesson is the same one already established with the DistCC Metasploit module in `e-06- distcc-cve-2004-2687.md`: a single tool's negative result does not settle the question of exploitability, and the only way to be certain is what was actually done in `e-01`, direct exploitation and evidence of a resulting root shell.

### NSE: `ftp-syst`

```bash
nmap -p 21 --script ftp-syst 192.168.144.200
```

```
PORT   STATE SERVICE
21/tcp open  ftp
```

**A third silent NSE result.** `ftp-syst` sends the FTP `SYST` command to retrieve the server's declared system/OS type, ordinarily a simple, low-risk banner-grab-style script with no reason to fail. Its silent output here, alongside `ftp-anon` and `ftp-proftpd-backdoor` above, establishes a **pattern rather than an isolated anomaly**: of the four FTP-specific NSE scripts tested against this target, three produced no output whatsoever, and only `ftp-bounce` returned a genuine, interpretable result (a negative one). This is a significant enough pattern to warrant its own note in the Outcome and Teaching Notes below, rather than treating each silent script as an unrelated one-off.

### Alternate manual tool: `curl`

```bash
curl -v ftp://192.168.144.200/ --user anonymous:
```

```
*   Trying 192.168.144.200:21...
* Established connection to 192.168.144.200 (192.168.144.200 port 21) from 192.168.144.129 port 55678
< 220 ProFTPD 1.3.3c Server (outstandingmailbox) [192.168.144.200]
> USER anonymous
< 331 Anonymous login ok, send your complete email address as your password
> PASS
< 230 Greetings! Welcome to the server.
> PWD
< 257 "/" is the current directory
* Entry path is '/'
> EPSV
< 229 Entering Extended Passive Mode (|||38722|)
> TYPE A
< 200 Type set to A
> LIST
< 150 Opening ASCII mode data connection for file list
-rw-r--r--   1 anon     anon          179 Aug 23 04:19 note
< 226 Transfer complete
* Connection #0 to host 192.168.144.200:21 left intact
```

`curl` with `--user anonymous:` (empty password after the colon) achieves the identical result to the interactive `ftp` client used earlier, confirmed anonymous login, directory listing showing the `note` file, in a single non-interactive command suitable for scripting or automation, rather than requiring a live interactive session. The `-v` (verbose) flag is what exposes the underlying FTP protocol exchange (`>` lines are commands curl sent, `<` lines are the server's responses), which is otherwise hidden by curl's default quiet output. This is a good demonstration that `curl` is not just an HTTP tool, it supports the FTP protocol natively, and can be a faster, more scriptable alternative to an interactive FTP client for straightforward tasks such as confirming anonymous access or retrieving a specific known file, though the interactive `ftp` client remains more convenient for open-ended exploration of an unfamiliar directory structure.

**Summary of this comparison:** anonymous FTP access, confirmed reliably and repeatably via three independent methods (interactive `ftp` client, `curl`, and manual observation), was **not** detected by nmap's own dedicated `ftp-anon` NSE script in this instance. More broadly, three of the four FTP NSE scripts tested against this specific ProFTPD 1.3.3c build (`ftp-anon`, `ftp-proftpd-backdoor`, `ftp-syst`) produced no output at all, while the fourth (`ftp-bounce`) did produce a result, but one whose reliability is itself limited by this lab's deliberate host-only network isolation, since the test could not run against a real, externally-resolvable third-party host as designed. This consistent pattern across multiple unrelated scripts suggests something about this particular server's protocol implementation or response timing is not well handled by this version of nmap's FTP NSE script family, rather than each script independently happening to fail for unrelated reasons. This directly illustrates why manual protocol interaction remains an essential skill alongside automated tooling, particularly during initial reconnaissance where a false negative from a single script, or from an entire family of related scripts, could cause a real finding to be missed entirely if those scripts' results were the only checks performed, and why environmental context (such as a lab's deliberate network isolation) must always be factored into how a given tool's output is interpreted.

## Outcome

Confirmed anonymous FTP access is enabled on the target, independent of the ProFTPD 1.3.3c backdoor vulnerability documented separately. Anonymous access grants read access to a small home directory containing standard account skeleton files and one deliberately placed note file, whose content is an intentional cross-service breadcrumb pointing toward the anonymous NFS export documented in `e- 02-nfs-anonymous-credential-exposure.md`, where the referenced "old database export" and the `backupsvc` credential are actually located.

Separately, of four FTP-specific nmap NSE scripts tested against this service (`ftp-anon`, `ftp-syst`, `ftp-bounce`, `ftp-proftpd-backdoor`), three produced no output at all despite two of them (`ftp-anon`, `ftp-proftpd-backdoor`) checking for conditions independently confirmed to be true on this target. `ftp-bounce` was the only script to return an interpretable result, but that result itself is inconclusive rather than a confirmed negative, given the lab's deliberate host-only network isolation, which prevented the script from resolving its intended real-world test target and forced it to substitute an arbitrary fallback address. A follow-up cross-check using Metasploit's `auxiliary/scanner/ftp/ftp_anonymous` module successfully and immediately detected the anonymous access that nmap's `ftp-anon` script had missed, confirming the finding is genuine and reliably detectable by capable tooling in general, and narrowing the earlier detection-gap conclusion specifically to nmap's own script implementation rather than to automated FTP enumeration as a whole. This is recorded as a significant finding about the limitations of specific automated tools against this server build, not as a separate vulnerability.

## Remediation

- Disable anonymous FTP access entirely unless there is a specific, deliberate business requirement for it; ProFTPD's `<Anonymous>` configuration block should be removed or explicitly disabled.
- Never store notes, credentials, or references to other systems/locations in a directory accessible to unauthenticated or anonymous users, regardless of how innocuous the reference appears; this is precisely the kind of information disclosure that assists an attacker in mapping out further attack paths.
- Independent of anonymous access, ProFTPD should be upgraded from the backdoored 1.3.3c release; see `e- 01-proftpd-1.3.3c-backdoor.md` for that separate finding and remediation.

## Teaching Notes

This activity is a good demonstration that a single service can carry multiple, independent findings at different severities: the ProFTPD backdoor (`e- 01`) is a critical, unauthenticated-to-root vulnerability, while anonymous access being enabled is a lower-severity but still genuine access-control weakness that would exist and matter even on a fully patched, non-backdoored FTP server. Students should learn to enumerate and document each weakness on its own merits rather than treating a service as "done" once the most severe finding has been identified.

The `note` file is also a useful example of information disclosure through unstructured, human-authored content (as opposed to a leaked credential file or configuration), and of the value in actually reading everything accessible during enumeration rather than only checking for obviously named or high-value files.

This activity also demonstrates deliberate attack-chain design: rather than treating each service in isolation, this scenario intentionally links FTP enumeration to NFS enumeration via a narrative clue, encouraging students to follow leads across services rather than exhaustively scanning every port with no sense of connection between findings. `e- 02-nfs-anonymous-credential-exposure.md` should ideally be read as the natural next step after this activity, discovered via the note's reference rather than purely through independent port scanning.

Perhaps the most important lesson in this activity is the **NSE detection gap** documented in the Additional Enumeration section, and its subsequent resolution via a different tool: `ftp-anon`, `ftp-syst`, and `ftp-proftpd-backdoor` all failed to produce output entirely, with the first checking for a condition confirmed true on this target both manually and via Metasploit's equivalent module. Students should take away a clear, memorable principle from this: automated scanning and NSE scripts are valuable for speed and coverage across many hosts, but a clean, empty, or missing result from a script, or even from several related scripts within the same tool, must never be treated as proof that a vulnerability or misconfiguration is absent. Critically, this activity also demonstrates the correct follow-up action when such a gap is found: rather than simply concluding "this vulnerability doesn't exist" or "this class of tooling is broadly unreliable," cross-checking with an independently-implemented tool (here, Metasploit's `ftp_anonymous` module) either confirms or refutes the original manual finding, and narrows down precisely which tool or script was at fault, rather than casting doubt on automated enumeration in general. This mirrors and reinforces the same lesson already established with the Metasploit DistCC module in `e-06- distcc-cve-2004-2687.md`, but demonstrates it here at the reconnaissance stage rather than the exploitation stage, and shows the full diagnostic loop, manual confirmation, automated tool failure, and automated tool cross-check success, rather than stopping at the initial discrepancy.

The `ftp-bounce` result, by contrast, illustrates a different and equally important lesson: not every script that produces output should be trusted at face value either. Environmental factors specific to this lab, its deliberate host-only isolation from the internet, meant the script could not run its test against a real third-party target as intended, and silently substituted an arbitrary fallback address instead. Recognising when a tool's output is shaped by the test environment rather than by the target's actual behaviour is itself an important diagnostic skill, arguably as important as recognising when a script has silently failed to detect something real, as seen with `ftp-anon`, `ftp-syst`, and `ftp-proftpd-backdoor` above. Both cases point to the same underlying principle: understand what a tool is actually doing and under what conditions, rather than treating its output as an unconditional verdict.

### Cross-check: Metasploit auxiliary scanner modules

To further test whether the NSE detection gap was specific to nmap's script implementation or reflective of some genuine oddity in the target's FTP response behaviour, the equivalent Metasploit auxiliary scanner modules were run against the same service.

```
use auxiliary/scanner/ftp/ftp_version
set RHOSTS 192.168.144.200
run
```

```
[+] 192.168.144.200:21    - FTP Banner: '220 ProFTPD 1.3.3c Server (outstandingmailbox) [192.168.144.200]\x0d\x0a'
[*] 192.168.144.200:21    - Scanned 1 of 1 hosts (100% complete)
```

This simply confirms the same banner already captured manually in Step 1, with no discrepancy.

```
use auxiliary/scanner/ftp/ftp_anonymous
set RHOSTS 192.168.144.200
run
```

```
[+] 192.168.144.200:21    - Anonymous Read-only access ()
[+] 192.168.144.200:21    - Directory listing stored to: /home/kali/.msf4/loot/20260824043223_default_192.168.144.200_ftp.anonymous_862038.txt
[*] 192.168.144.200:21    - Scanned 1 of 1 hosts (100% complete)
```

**This resolves the detection gap identified earlier with nmap's `ftp-anon` script.** Metasploit's `ftp_anonymous` module correctly and immediately detected anonymous access, explicitly reporting `Anonymous Read-only access`, and additionally saved the resulting directory listing to a local loot file for later reference, a convenience the manual `ftp`/`curl` approaches did not provide automatically. This confirms the anonymous-access finding is genuine and reliably detectable by automated tooling in general; the earlier `ftp-anon` NSE script's silent failure was therefore specific to that particular script or nmap version/implementation, not evidence of some broader oddity in how this ProFTPD build responds to automated anonymous-login probing. This is an important refinement of the earlier finding: rather than concluding "automated FTP anonymous-detection is unreliable against this target" in general, the more precise and now better-supported conclusion is "this specific nmap NSE script failed on this target, but an equivalent, independently-implemented Metasploit module succeeded without issue." This distinction matters for how confidently either tool's results should be trusted in future engagements against similar targets.

## Lab Dependencies

**Prerequisite exploit(s):** None (works from a fresh, unauthenticated FTP connection)
**Required starting access:** Network access to the target from Kali
**Starting account:** None (anonymous FTP)
**Resulting access:** Anonymous FTP read access to a limited home directory; no shell or credential obtained directly
**Provides access for:** Intentionally leads toward `e- 02-nfs-anonymous-credential-exposure.md`; the `note` file's "shared backup location" is the NFS export investigated there, where the `backupsvc` credential is recovered
**Suggested teaching level:** Level 5 (manual protocol interaction, anonymous service access as a distinct finding from CVE-based exploitation, and the value of thorough content enumeration)

## What is FTP?

FTP (File Transfer Protocol) is one of the oldest internet protocols still in common use, designed simply to upload and download files between a client and a server. It predates modern security practices by decades: in its plain/unencrypted form, credentials and file contents are sent in cleartext, and many FTP servers support an "anonymous" login mode intended for public file distribution. Despite its age, FTP servers are still frequently found in real organisations for legacy file-transfer workflows, making misconfigurations like open anonymous access a genuinely common real-world finding.
