# Activity: Host Discovery

## Summary

Basic host discovery against the target segment, confirming the target is live and reachable before any port scanning takes place, and identifying other hosts present on the same network segment for scope awareness. This is the first active reconnaissance step, following `r- 01-passive-reconnaissance-not-applicable.md` (which established that passive/OSINT techniques do not apply to this isolated lab environment) and preceding `r- 02-reconnaissance-and-service-enumeration.md` (the port scanning and service enumeration activity).

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Attacker | Kali VM on the same host-only lab network |
| Segment | 192.168.144.0/24 |
| Tooling | ping, arp-scan |

## Reconnaissance

### Step 1: ICMP reachability check

```bash
ping -c 4 192.168.144.200
```

```
PING 192.168.144.200 (192.168.144.200) 56(84) bytes of data.
64 bytes from 192.168.144.200: icmp_seq=1 ttl=64 time=0.405 ms
64 bytes from 192.168.144.200: icmp_seq=2 ttl=64 time=0.953 ms
64 bytes from 192.168.144.200: icmp_seq=3 ttl=64 time=1.07 ms
64 bytes from 192.168.144.200: icmp_seq=4 ttl=64 time=1.65 ms
--- 192.168.144.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3031ms
rtt min/avg/max/mdev = 0.405/1.020/1.651/0.442 ms
```

`-c 4` sends exactly four ICMP echo requests rather than pinging indefinitely. All four requests received a reply with 0% packet loss, confirming the target host is up and responding to ICMP. The `ttl=64` value is consistent with a Linux target (Linux typically defaults to a TTL of 64, versus 128 for Windows and 255 for many network devices), providing an early, low-confidence hint about the target OS before any further fingerprinting.

Sub-millisecond to low-millisecond round-trip times confirm the target is on the same local network segment as the attacker, consistent with the lab's flat 192.168.144.0/24 topology.

### Step 2: ARP scan of the local segment

```bash
sudo arp-scan --interface=eth0 192.168.144.0/24
```

```
Interface: eth0, type: EN10MB, MAC: 00:0c:29:1d:5a:65, IPv4: 192.168.144.129
WARNING: Cannot open MAC/Vendor file ieee-oui.txt: Permission denied
WARNING: Cannot open MAC/Vendor file mac-vendor.txt: Permission denied
Starting arp-scan 1.10.0 with 256 hosts (https://github.com/royhills/arp-scan)
192.168.144.200 00:0c:29:94:44:82       (Unknown)
192.168.144.1   00:50:56:c0:00:01       (Unknown)
192.168.144.200 00:0c:29:94:44:82       (Unknown) (DUP: 2)
192.168.144.200 00:0c:29:e5:ff:81       (Unknown)
192.168.144.254 00:50:56:fd:7d:c1       (Unknown)
23 packets received by filter, 0 packets dropped by kernel
Ending arp-scan 1.10.0: 256 hosts scanned in 2.035 seconds (125.80 hosts/sec). 4 responded
```

`--interface=eth0` specifies the Kali attacker's network interface to scan from (confirmed as `192.168.144.129`, matching the attacker IP used throughout this engagement). The `/24` CIDR sweeps the entire local subnet via ARP requests, which is a reliable way to enumerate live hosts on a local segment regardless of whether they respond to ICMP, since ARP operates below the IP layer and any host that wants to communicate on the local network must respond to ARP requests for its own address.

**Tooling note:** the two `WARNING: Cannot open MAC/Vendor file` lines indicate `arp-scan`'s local OUI (Organisationally Unique Identifier) vendor database files are not readable by the current user, most likely a file permissions issue on the Kali attacker box itself (unrelated to the target). This means vendor names could not be resolved from the MAC address prefixes, and every host is reported as `(Unknown)` rather than showing a manufacturer name. This is a Kali-side tooling limitation, not a target-side finding, and does not affect the validity of the host discovery itself. Correcting it (e.g. `sudo chmod` on the vendor files, or reinstalling `arp-scan`'s OUI data) would be worthwhile for future engagements but was not pursued here since it wasn't required to complete this activity.

Four distinct hosts responded on the segment:

| IP | MAC Address | Identity (from other project context) |
|---|---|---|
| 192.168.144.1 | 00:50:56:c0:00:01 | VMware virtual network gateway/host-only adapter (typical VMware `.1` gateway MAC prefix `00:50:56`) |
| 192.168.144.200 | 00:0c:29:e5:ff:81 | Master CAV-CSF VM (reference only; never exploited) |
| 192.168.144.200 | 00:0c:29:94:44:82 | Target: disposable exploitation VM |
| 192.168.144.254 | 00:50:56:fd:7d:c1 | Likely a VMware NAT/DHCP service address (typical VMware `.254` reserved address, MAC prefix `00:50:56` again indicating a VMware-generated virtual interface rather than a physical host) |

The target (`192.168.144.200`) appearing twice with a `(DUP: 2)` annotation is expected `arp-scan` behaviour when a host replies more than once within the scan window (commonly caused by switch/network timing rather than indicating two separate physical hosts); it is the same single host both times, confirmed by the identical MAC address `00:0c:29:94:44:82`.

Both `00:0c:29:...` MAC prefixes (on `.130` and `.131`) are VMware's standard OUI for VM network adapters, consistent with both being VMware Workstation guest VMs as expected from the project's environment (`session-continuation-prompt-23-08.md`), while the `00:50:56:...` prefixes on `.1` and `.254` are VMware's separately allocated OUI range used for virtual network infrastructure (host-only gateway and NAT services) rather than guest VMs themselves.

## Outcome

Confirmed the target (192.168.144.200) is live and reachable via both ICMP and ARP. Identified the full set of hosts present on the local lab segment: the Kali attacker itself, the target disposable VM, the master reference VM (192.168.144.200, out of scope for exploitation per project rules), and two VMware-generated virtual network infrastructure addresses (gateway and NAT/DHCP service). No hosts outside the expected lab topology were discovered.

## Remediation

Not applicable; this is a reconnaissance activity against an intentionally accessible lab target, not a production environment assessment.

## Teaching Notes

This activity demonstrates two complementary discovery techniques and why both are useful:

- **ICMP ping** is simple and fast but can be blocked by firewall rules (`icmp` is frequently filtered on production networks), so a lack of ping response does not necessarily mean a host is down.
- **ARP scanning** operates at a lower network layer and cannot be blocked by host-based firewalls in the way ICMP can (a host must respond to ARP to participate in the local network at all), making it a more reliable discovery method on a local segment, though it is inherently limited to hosts on the same broadcast domain and cannot be used across routed network boundaries.

The MAC vendor OUI lookup failure is also a small but realistic example of a tooling/environment issue a student might encounter, and demonstrates that a tool producing a warning does not necessarily invalidate its core findings, the host discovery itself remained fully successful despite the vendor database being unavailable.

## Lab Dependencies

**Prerequisite exploit(s):** `r- 01-passive-reconnaissance-not-applicable.md` (methodology context)
**Required starting access:** Network access to the 192.168.144.0/24 segment from Kali
**Starting account:** None
**Resulting access:** N/A (discovery/informational activity)
**Provides access for:** Precedes `r- 02-reconnaissance-and-service-enumeration.md` (port scanning and service identification)
**Suggested teaching level:** Level 5 (fundamental host discovery techniques and the distinction between ICMP-based and ARP-based discovery)
