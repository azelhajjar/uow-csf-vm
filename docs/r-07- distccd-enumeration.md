# Activity: distccd Enumeration

## Summary

Reconnaissance and enumeration of the distcc distributed compiler daemon on port 3632, performed in the order a real assessment would follow: starting from manual protocol interaction with no prior knowledge of the service's vulnerability history, discovering what nmap NSE tooling actually exists for this service before assuming which script to reach for, running a safe, scoped default script pass, and only then deliberately invoking a CVE-specific detection/exploitation script as an informed final step. This activity also documents a genuine nmap crash encountered when using an overly broad script category, and the scoping lesson that follows from it. This is the enumeration phase that precedes and motivates `e-06- distcc-cve-2004-2687.md`.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.131 |
| Service | distccd, port 3632/tcp |
| Attacker | Kali, 192.168.144.129 |
| Tooling | nc, nmap NSE (`default` category, `distcc-cve2004-2687`) |

## Reconnaissance

### Step 1: Manual protocol probe

Unlike FTP or SSH, distcc does not send a cleartext identifying banner on connection; its wire protocol is a compact binary/token-based format rather than a human-readable greeting. To test this directly rather than assuming it, a raw TCP connection was opened and a distcc protocol token was sent manually:

```bash
echo -e "DIST00000001" | nc -nv -q2 192.168.144.131 3632
```

```
Connection to 192.168.144.131 3632 port [tcp/*] succeeded!
```

The TCP connection succeeded, confirming the port is genuinely open and accepting connections, but no data was returned in response to the manually crafted token. This is itself a useful, if unremarkable, finding: distccd does not respond usefully to naive manual interaction the way a text-based protocol like FTP does, and correctly speaking its protocol would require either the real `distcc` client, a purpose-built script, or a tool (such as the eventual NSE exploit script) that understands its exact wire format. This is recorded as the expected, negative-but-informative result of attempting the simplest possible manual interaction before moving to more capable tooling.

### Step 2: Discovering available NSE tooling before assuming which script to use

Rather than immediately reaching for a named vulnerability-detection script (which would require already knowing, from prior research, exactly which CVE to look for), the correct methodological step at this stage is to first establish what NSE scripts actually exist for this service:

```bash
ls -l /usr/share/nmap/scripts/ | grep -i distcc
```

```
-rw-r--r-- 1 root root  3519 Apr  9 10:18 distcc-cve2004-2687.nse
```

Only one distcc-related script exists in this nmap installation. Before running it, its documentation and script category were checked:

```bash
nmap --script-help distcc-cve2004-2687
```

```
distcc-cve2004-2687
Categories: exploit intrusive vuln
https://nmap.org/nsedoc/scripts/distcc-cve2004-2687.html
  Detects and exploits a remote code execution vulnerability in the distributed
  compiler daemon distcc. The vulnerability was disclosed in 2002, but is still
  present in modern implementation due to poor configuration of the service.
```

**This is an important finding in its own right.** The script's categories are `exploit`, `intrusive`, and `vuln`, not merely `vuln` or `safe`. In nmap's own script categorisation scheme, `exploit` and `intrusive` scripts are explicitly not considered passive or safe reconnaissance actions; the script's own description confirms it both *detects and exploits* the vulnerability, meaning simply running it is already an active exploitation attempt, not a neutral information-gathering step. This distinguishes it clearly from genuinely passive detection scripts (such as the `ssh2-enum-algos` or `nfs-showmount` scripts used in earlier activities), and means this script should be reached for deliberately, once a specific reason to suspect this vulnerability exists, rather than run reflexively as a first move against any distcc service encountered.

### Step 3: Broad default/discovery script pass — and a genuine tool failure

To continue the reconnaissance-appropriate approach (general enumeration before targeted vulnerability checks), a broader script pass was attempted using nmap's `default` and `discovery` categories together:

```bash
nmap -sV -p 3632 --script default,discovery 192.168.144.131
```

This scan **did not complete successfully**. It produced a long sequence of output from numerous `broadcast-*` and `targets-*` scripts (multicast/mDNS discovery, IPv6 neighbour solicitation, and protocol-specific broadcast probes for OSPF, EIGRP, PIM, IGMP, and KNX gateway discovery, among others), several of which independently failed with `ERROR: Script execution failed`, and the scan ultimately crashed nmap itself with an internal assertion failure:

```
nmap: nse_nsock.cc:381: void callback(nsock_pool, nsock_event, void*): Assertion `lua_status(L) == LUA_YIELD' failed.
Aborted
```

**This is a genuine and important finding about the `discovery` NSE category, not a distraction from the target enumeration.** Despite the scan being scoped to a single target IP and a single port (`-p 3632 192.168.144.131`), the `discovery` category pulled in scripts that operate at the *local network segment* level rather than respecting the specified target scope, sending broadcast and multicast probes across the entire subnet (visible in the output referencing other hosts on the segment, including the Kali attacker's own interface and the master VM). Several of these subnet-wide scripts failed outright, and the combination ultimately crashed the nmap process entirely before any distcc-specific results were returned.

The practical lesson: broad, category-based NSE invocations (`--script default,discovery` or similar) do not necessarily respect the target scope implied by the command's IP/port arguments, and can have unpredictable side effects, up to and including crashing the scanning tool itself, well beyond the intended target. This is a real operational risk worth understanding before running broad script categories in any environment, lab or otherwise, particularly one where unintended broadcast traffic could have side effects on other systems sharing the segment.

### Step 4: Corrected, properly scoped default script pass

Following the crash, the scan was re-run using only the `default` category (dropping `discovery` entirely), which contains nmap's curated set of scripts intended to be safe and reasonably scoped to the actual target:

```bash
nmap -sV -p 3632 --script default 192.168.144.131
```

```
PORT     STATE SERVICE VERSION
3632/tcp open  distccd distccd v1 ((Debian 12.2.0-14+deb12u1) 12.2.0)
```

This completed cleanly and without incident, though it produced no distcc-specific script output beyond the standard `-sV` version detection banner already established in `r-02- reconnaissance-and-service-enumeration.md`. This confirms that none of the scripts in the `default` category specifically target distcc, which is expected given that only one distcc-related NSE script exists at all in this nmap installation (`distcc-cve2004-2687`, established in Step 2), and it is not a member of the `default` category (its categories being `exploit`, `intrusive`, `vuln`, as already noted).

### Step 5: Deliberate, informed use of the CVE-specific script

Having now confirmed the exact service version (`distccd v1`, Debian 12.2.0-14+deb12u1) via safe, scoped default scanning, and having separately identified through research/prior knowledge that older, permissively-configured distcc daemons are subject to CVE-2004-2687 (a weak-configuration class vulnerability rather than a memory-safety bug, as documented in `e-06- distcc-cve-2004-2687.md`), running the dedicated detection script becomes a deliberate, justified next step rather than a first guess:

```bash
nmap -p 3632 --script distcc-cve2004-2687 192.168.144.131
```

```
PORT     STATE SERVICE
3632/tcp open  distccd
| distcc-cve2004-2687:
|   VULNERABLE:
|   distcc Daemon Command Execution
|     State: VULNERABLE (Exploitable)
|     IDs:  CVE:CVE-2004-2687
|     Risk factor: High  CVSSv2: 9.3 (HIGH) (AV:N/AC:M/Au:N/C:C/I:C/A:C)
|       Allows executing of arbitrary commands on systems running distccd 3.1 and
|       earlier. The vulnerability is the consequence of weak service configuration.
|
|     Disclosure date: 2002-02-01
|     Extra information:
|
|     uid=121(distccd) gid=65534(nogroup) groups=65534(nogroup)
|
|     References:
|       https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2004-2687
|       https://distcc.github.io/security.html
|_      https://nvd.nist.gov/vuln/detail/CVE-2004-2687
```

Because this script's category includes `exploit`, its "VULNERABLE (Exploitable)" verdict is not a passive inference, the `Extra information: uid=121(distccd) ...` line shows the script actually executed a command (`id`, evidently) on the target and captured its real output, meaning this single command both detected the vulnerability and demonstrated code execution simultaneously. This is functionally the same category of action as the full exploitation already documented in `e-06`, just condensed into a single automated NSE invocation rather than the manual reverse-shell workflow used there.

The `--show-hosts`-style `distcc` standalone client tool (`distcc --help`) was also reviewed for completeness, confirming it is designed for legitimate distributed-compilation use (specifying compiler hosts via `$DISTCC_HOSTS` or a hosts file) rather than offering any built-in exploitation capability; the actual vulnerability lies in the daemon's willingness to accept and execute an arbitrary "compiler" invocation from any client, not in any feature of the standard client tool itself.

## Outcome

Confirmed distccd v1 (Debian 12.2.0-14+deb12u1) is running and, per the dedicated NSE detection/exploitation script, genuinely vulnerable and exploitable via CVE-2004-2687, consistent with the full manual exploitation already documented in `e-06- distcc-cve-2004-2687.md`. Separately, this activity surfaced two process-level findings independent of distcc itself: distccd does not respond to naive manual protocol probing (expected, given its binary wire format), and nmap's `discovery` script category, when combined with `default` and used without careful scoping, caused a genuine tool crash by pulling in subnet-wide broadcast/multicast scripts unrelated to the specified target.

## Remediation

See `e-06- distcc-cve-2004-2687.md` for full remediation guidance on the distcc misconfiguration itself. No additional remediation applies from the enumeration methodology; the nmap crash observed in Step 3 is a tooling/methodology consideration for the assessor rather than a target-side finding.

## Teaching Notes

This activity is a deliberate corrective to a common shortcut: jumping straight to a named CVE-specific script without first establishing, through general reconnaissance, that there is reason to suspect that specific vulnerability. A student who already "knows the answer" (because the target's other documented exploits reference CVE-2004-2687) can be tempted to skip directly to `distcc-cve2004-2687`, but a genuine unknown-target assessment would not have that foreknowledge, and should instead progress through manual protocol interaction, discovering what tooling is actually available (rather than assuming a script name), safe/scoped general scanning, and only then targeted, deliberate vulnerability-specific tooling, understanding fully that such a tool (given its `exploit`/`intrusive` categorisation) is not a passive check.

The nmap crash in Step 3 is equally important as a standalone lesson: broad script categories like `discovery` are not automatically safe or properly scoped just because a specific target IP and port were provided on the command line, and can produce unpredictable, even destabilising, results extending beyond the intended target. Students should understand that `--script default` alone is generally a safer default choice than combining it with `discovery`, and that any broad category should be tested cautiously, ideally in isolation, before being used as part of a routine workflow.

## Lab Dependencies

**Prerequisite exploit(s):** None (all reconnaissance steps run unauthenticated; Step 5 constitutes light exploitation via the NSE script's own command-execution proof, distinct from but consistent with the full exploitation in `e-06`)
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Command execution as `distccd` (uid 121) demonstrated via the NSE script's self-test in Step 5; no interactive shell obtained in this activity (see `e-06- distcc-cve-2004-2687.md` for the full reverse-shell exploitation)
**Provides access for:** Precedes and directly motivates the full exploitation documented in `e-06- distcc-cve-2004-2687.md`
**Suggested teaching level:** Level 6–7 (correct sequencing of general-to-specific enumeration, understanding NSE script categorisation and risk, and a real example of tooling failure from improperly scoped script categories)

## What is distcc?

distcc is a tool that speeds up software compilation by distributing the work of compiling code across multiple machines on a network, rather than relying on a single machine's CPU. A machine running `distccd` (the distcc daemon) accepts compilation jobs from other machines and returns the compiled results. It is mostly used in software development environments (e.g. build farms) rather than typical business infrastructure, but where it does exist, its core design, accepting and executing arbitrary compiler invocations from the network, makes it a historically significant source of remote code execution vulnerabilities when not properly restricted.
