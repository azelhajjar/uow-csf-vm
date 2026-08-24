# Activity: CUPS Full RCE Chain (CVE-2024-47176 / CVE-2024-47076 / CVE-2024-47175 / CVE-2024-47177)

## Summary

Full exploitation of the 2024 CUPS RCE chain, building on the detection-stage confirmation in the corresponding reconnaissance activity. The chain works by announcing a fake printer to the vulnerable `cups-browsed` daemon, which then queries an attacker-controlled fake IPP server for that printer's attributes. Because the IPP attributes returned are written unsanitised into a generated PPD file, a crafted attribute value can inject a `FoomaticRIPCommandLine` directive, which `foomatic-rip` will execute as an arbitrary shell command the next time a print job is sent to that printer. This gives unauthenticated remote code execution as the user running `cups-browsed`.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.131 |
| Vulnerable components | cups-browsed 1.28.17-3, libcupsfilters1 1.28.17-3, cups-filters 1.28.17-3 (all pre-`+deb12u1`) |
| Attacker | Kali, 192.168.144.129 |
| CVEs chained | CVE-2024-47176 (unauth UDP trigger), CVE-2024-47076 (unsanitised IPP attribute validation), CVE-2024-47175 (unsanitised PPD generation), CVE-2024-47177 (FoomaticRIPCommandLine command execution) |

## Vulnerability Chain

1. **CVE-2024-47176**: `cups-browsed` binds to `UDP 0.0.0.0:631` and trusts any source. A crafted browse packet naming an attacker-controlled URL as a "printer" causes `cups-browsed` to issue a `Get-Printer-Attributes` IPP request to that URL. Confirmed working in the reconnaissance activity.
2. **CVE-2024-47076**: `libcupsfilters`' `cfGetPrinterAttributes5()` does not validate the IPP attributes returned by that (attacker-controlled) server.
3. **CVE-2024-47175**: `libppd`'s `ppdCreatePPDFromIPP2()` writes those unvalidated attributes directly into a generated PPD file with no sanitisation, allowing a crafted attribute value (ending in a quote and newline) to inject entirely new PPD directives.
4. **CVE-2024-47177**: the injected `*FoomaticRIPCommandLine` directive is executed verbatim by `foomatic-rip` whenever a print job is sent to that printer, giving arbitrary command execution.

The publicly documented injection technique (confirmed by evilsocket's original advisory and independently reproduced by multiple researchers) uses an attribute such as `printer-make-and-model` with a value like:

```
HP 0.00"
*FoomaticRIPCommandLine: "COMMAND"
*cupsFilter2 : "application/pdf application/vnd.cups-postscript 0 foomatic-rip"
```

The leading `"` closes the legitimate PPD field early; the newline starts a new PPD directive line entirely under attacker control.

## Building the Malicious IPP Server

Hand-crafting the raw IPP binary protocol response byte-by-byte is intricate (attribute tags, value-length prefixes, charset/language framing) and error-prone to do reliably from scratch. Use a proper IPP server library rather than raw sockets. The most reliable, widely-referenced educational implementation for this exact chain is `0xCZR1/PoC-Cups-RCE-CVE-exploit-chain` on GitHub, which implements the fake IPP responder correctly using Python's `pysimpleipp`/`ippserver`-style approach with the `PrinterPwned` class specifically designed to inject a malicious `FoomaticRIPCommandLine`.

Since this VM needs internet access to clone it, do this while still on NAT (before switching back to host-only for the actual attack):

```bash
git clone https://github.com/0xCZR1/PoC-Cups-RCE-CVE-exploit-chain.git
cd PoC-Cups-RCE-CVE-exploit-chain
pip install -r requirements.txt --break-system-packages
```

Review the script's `PrinterPwned` class before running it and set the command you want executed on the target (for a safe, easily verified proof, something like `touch /tmp/CUPS_RCE_PWNED` or `id > /tmp/cups_poc_id.txt` rather than anything destructive), then switch back to host-only networking and run it against the target following the script's own instructions (it will handle both sending the initial UDP trigger packet and standing up the fake IPP server to answer the resulting callback).

## Triggering Execution

The RCE only fires once the malicious printer actually receives a print job, this cannot be triggered remotely by the attacker; something on the target must print to the newly-created queue. For teaching purposes, this last step can be demonstrated locally on the target (simulating what an unwitting user would do) with:

```bash
lpr -P <malicious-queue-name> /etc/hostname
```

substituting whatever queue name the PoC created (visible via `lpstat -p` on the target once the fake printer has been registered).

## Evidence

After the print job is sent, confirm code execution occurred by checking for the proof file specified in the injected command:

```bash
ls -la /tmp/CUPS_RCE_PWNED
```

or, for a command that captures identity information:

```bash
cat /tmp/cups_poc_id.txt
```

The command executes as the user running `cups-browsed` (check with `systemctl status cups-browsed` to confirm the running user, typically `root` if the service runs as a system daemon, though this should be verified directly on the target rather than assumed).

## Outcome

Confirms full unauthenticated remote code execution via the chained CVE-2024-47176/47076/47175/47177 vulnerability set, from an unauthenticated network position with no prior access or credentials required, contingent only on a print job being sent to the malicious queue.

## Remediation

- Upgrade `cups-filters`, `cups-browsed`, and `libcupsfilters1` to `1.28.17-3+deb12u1` or later (already the case on any unmodified Debian 12 system as of September 2024).
- Remove `cups-browsed` entirely on systems that do not need to auto-discover shared network printers.
- Restrict `BrowseRemoteProtocols` to exclude the legacy `cups` protocol.
- Firewall UDP/631 from untrusted network segments.

## Teaching Notes

This is a strong Level 7 capstone exercise: it requires chaining four distinct CVEs across three separate components, understanding IPP as a protocol, understanding how a generated configuration file (PPD) can become a code-execution primitive when attacker-controlled data is written into it unsanitised, and recognising that the final trigger step is out of the attacker's direct control (a print job must occur), a good discussion point on the practical limits of "unauthenticated RCE" claims, some vulnerabilities require a specific victim action even when no credentials are needed.

## Lab Dependencies

**Prerequisite exploit(s):** Confirmed detection-stage vulnerability from the corresponding reconnaissance activity
**Required starting access:** Network access to the target; NAT temporarily for cloning the PoC tooling
**Starting account:** None
**Resulting access:** Command execution as the `cups-browsed` process user
**Suggested teaching level:** Level 7
