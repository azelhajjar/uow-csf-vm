# Activity: Netlogon / Zerologon Reconnaissance

## Summary

Reconnaissance of the Netlogon-related RPC/SMB surface on the Windows domain controller `uow-csf-dc` (`192.168.144.200`), and a non-destructive check for the Zerologon authentication vulnerability (CVE-2020-1472). This is the final Windows DC reconnaissance item in the current build sequence. DC identity and service-exposure reconnaissance has been performed and is recorded below with genuine output; the RPC endpoint mapper enumeration confirms the Netlogon RPC interface is exposed, and the non-destructive Zerologon check has now been run, using two independent tools. The result is negative and corroborated: `uow-csf-dc` does not respond as vulnerable, and CVE-2020-1472 is not validated against this target.

## Environment

| Item | Value |
|---|---|
| Target | `uow-csf-dc.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` |
| NetBIOS domain | `UOWCSF` |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | `dig`, `nmap`, `nmblookup`, `smbclient`, `impacket-rpcdump`, `zerologon_tester.py`, `zer0dump` |

## Lab Dependencies

- Prerequisite: none beyond network reachability to `192.168.144.200`; this is unauthenticated reconnaissance, consistent with `r-19`.
- Starting access: none.
- Resulting access: N/A (reconnaissance only). Confirms DC identity and core service exposure; no elevated access gained.
- Feeds into: a possible exploitation write-up (working title `e-23`), to be created only once exploit validation evidence exists.
- Suggested teaching level: Level 7.

## Reconnaissance

### DC DNS resolution

```bash
dig @192.168.144.200 uow-csf-dc.uow-csf.internal
```

```
; <<>> DiG 9.20.26-1-Debian <<>> @192.168.144.200 uow-csf-dc.uow-csf.internal
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 15955
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;uow-csf-dc.uow-csf.internal.   IN      A
;; ANSWER SECTION:
uow-csf-dc.uow-csf.internal. 3600 IN    A       192.168.144.200
;; Query time: 4 msec
;; SERVER: 192.168.144.200#53(192.168.144.200) (UDP)
;; WHEN: Wed Sep 02 06:12:58 BST 2026
;; MSG SIZE  rcvd: 72
```

Confirms `uow-csf-dc.uow-csf.internal` resolves authoritatively to `192.168.144.200`.

### Core DC service exposure

```bash
nmap -p 53,88,135,139,389,445,464,593,636,3268,3269 -sV 192.168.144.200
```

```
Starting Nmap 7.99 ( https://nmap.org ) at 2026-09-02 06:13 +0100
Nmap scan report for uow-intranet.uow-csf.internal (192.168.144.200)
Host is up (0.0019s latency).
PORT     STATE SERVICE       VERSION
53/tcp   open  domain        Simple DNS Plus
88/tcp   open  kerberos-sec  Microsoft Windows Kerberos (server time: 2026-09-02 05:13:09Z)
135/tcp  open  msrpc         Microsoft Windows RPC
139/tcp  open  netbios-ssn   Microsoft Windows netbios-ssn
389/tcp  open  ldap          Microsoft Windows Active Directory LDAP (Domain: uow-csf.internal, Site: Default-First-Site-Name)
445/tcp  open  microsoft-ds?
464/tcp  open  kpasswd5?
593/tcp  open  ncacn_http    Microsoft Windows RPC over HTTP 1.0
636/tcp  open  tcpwrapped
3268/tcp open  ldap          Microsoft Windows Active Directory LDAP (Domain: uow-csf.internal, Site: Default-First-Site-Name)
3269/tcp open  tcpwrapped
MAC Address: 00:0C:29:89:B3:B8 (VMware)
Service Info: Host: UOW-CSF-DC; OS: Windows; CPE: cpe:/o:microsoft:windows
Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 6.81 seconds
```

All eleven scanned ports are open: DNS (53), Kerberos (88), the RPC endpoint mapper (135), NetBIOS session service (139), LDAP (389), SMB (445, unversioned by nmap's probe), kpasswd (464), RPC-over-HTTP (593), LDAPS and the Global Catalog SSL port (636, 3269, both reported as `tcpwrapped`), and the Global Catalog LDAP port (3268). This is the expected AD DS/DNS/Kerberos/LDAP service set for a domain controller and is consistent with the service exposure already established against this DC in `r-19`/`w-01`. `nmap` reverse-resolved the host as `uow-intranet.uow-csf.internal`, the intranet hostname already documented in `r-22`, rather than `uow-csf-dc`; this is a PTR/reverse-lookup naming detail, not a discrepancy in the DC's identity, which the DNS query above and the NetBIOS lookup below both confirm independently.

### SMB/NetBIOS identity

```bash
nmblookup -A 192.168.144.200
```

```
Looking up status of 192.168.144.200
        UOW-CSF-DC      <00> -         B <ACTIVE>
        UOWCSF          <00> - <GROUP> B <ACTIVE>
        UOWCSF          <1c> - <GROUP> B <ACTIVE>
        UOW-CSF-DC      <20> -         B <ACTIVE>
        UOWCSF          <1b> -         B <ACTIVE>
        MAC Address = 00-0C-29-89-B3-B8
```

Confirms the NetBIOS computer name `UOW-CSF-DC` and the NetBIOS domain name `UOWCSF`, including the `<1b>` domain master browser and `<1c>` domain controller group records, consistent with the canonical identity already established for this DC.

```bash
smbclient -L //192.168.144.200/ -N
```

```
Anonymous login successful
        Sharename       Type      Comment
        ---------       ----      -------
Reconnecting with SMB1 for workgroup listing.
do_connect: Connection to 192.168.144.200 failed (Error NT_STATUS_RESOURCE_NAME_NOT_FOUND)
Unable to connect with SMB1 -- no workgroup available
```

Anonymous SMB login succeeds but returns no visible shares over SMB2+, and the SMB1 fallback used for workgroup listing fails outright, expected since SMB1 is not offered by this DC. This does not disclose any share names or content.

### RPC endpoint mapper exposure

```bash
impacket-rpcdump -target-ip 192.168.144.200 192.168.144.200
```

Ran successfully (Impacket v0.14.0.dev0), returning 673 endpoints in total. The full listing is not reproduced here; only the Netlogon/MS-NRPC-relevant entry is summarised:

```
Protocol: [MS-NRPC]: Netlogon Remote Protocol
Provider: netlogon.dll
UUID    : 12345678-1234-ABCD-EF00-01234567CFFB v1.0
Bindings:
          ncacn_ip_tcp:192.168.144.200[49672]
          ncacn_ip_tcp:192.168.144.200[49670]
          ncacn_np:\\UOW-CSF-DC[\pipe\81abb827213c66ea]
          ncacn_http:192.168.144.200[49669]
          ncacn_ip_tcp:192.168.144.200[49666]
          ncacn_np:\\UOW-CSF-DC[\pipe\lsass]
[*] Received 673 endpoints.
```

MS-NRPC (Netlogon Remote Protocol) is exposed via `netlogon.dll`, identified by UUID `12345678-1234-ABCD-EF00-01234567CFFB` v1.0. Its `ncacn_ip_tcp` bindings on `192.168.144.200` include the dynamic RPC ports `49672` and `49670` (also `49666`, shared with the LSA/SAM/DRS interfaces), alongside an RPC-over-HTTP binding on `49669` and named-pipe bindings over SMB. This confirms the Netlogon RPC interface is reachable over the network, the precondition for the Zerologon check below; it does not by itself indicate whether the Zerologon flaw is present.

### Zerologon vulnerability check

```bash
python3 zerologon_tester.py UOW-CSF-DC 192.168.144.200
```

```
Performing authentication attempts...
=====================================
Attack failed. Target is probably patched.
```

The checker's repeated authentication attempts against `uow-csf-dc` failed. This is a negative result: the non-destructive check does not reproduce the CVE-2020-1472 authentication bypass, and the target is probably patched. No exploitation was performed or attempted.

### Corroborating check (zer0dump)

```bash
python3 zer0dump.py 192.168.144.200
```

```
Namespace(target='192.168.144.200', silver=False, target_da=None, port=445, target_machine=None)
Performing authentication attempts...
192.168.144.200
UOW-CSF-DC
==========
Attack failed. Target is probably patched.
```

A second, independent tool (`zer0dump`) was run against the same target as a corroborating check. It also failed with the same "probably patched" result, matching the `zerologon_tester.py` outcome above. Netlogon/MS-NRPC remains reachable, but CVE-2020-1472 is not validated against `uow-csf-dc` by either tool.

## Outcome

Reconnaissance confirms `uow-csf-dc` is reachable at `192.168.144.200`, resolves correctly by DNS, and exposes the expected AD DS/DNS/Kerberos/LDAP service set (DNS, Kerberos, RPC endpoint mapper, NetBIOS session, LDAP, SMB, kpasswd, RPC-over-HTTP, Global Catalog), with NetBIOS identity confirmed as `UOW-CSF-DC` in the `UOWCSF` domain. Anonymous SMB login succeeds but discloses no shares. RPC endpoint mapper enumeration (`impacket-rpcdump`) confirms MS-NRPC (Netlogon Remote Protocol) is exposed on `192.168.144.200`, with `ncacn_ip_tcp` bindings including dynamic ports `49672` and `49670`. The non-destructive Zerologon check has been run with two independent tools (`zerologon_tester.py` and `zer0dump`), both of which failed: `uow-csf-dc` does not respond as vulnerable to CVE-2020-1472, and the target is probably patched. This is a negative reconnaissance finding, corroborated across tools.

## Teaching Notes

- Zerologon (CVE-2020-1472) is a critical authentication bypass in the Netlogon Remote Protocol (MS-NRPC); confirming exposure and checking for the flaw are the reconnaissance-stage questions this activity addresses.
- A non-destructive checker distinguishes reconnaissance from exploitation: it confirms whether the flaw is present without executing an attack. Exploit execution is outside the scope of this file.
- On this Kali install, Impacket's example scripts are provided under `impacket-<name>` names (e.g. `impacket-rpcdump`), not as bare `<name>.py` commands; `rpcdump.py` is not present and is not an available command in this lab image.
- The RPC endpoint mapper returning 673 endpoints, most unrelated to Netlogon, is a reminder that this stage of reconnaissance is broad by nature: the useful signal (the MS-NRPC entry and its bindings) has to be picked out of a large amount of routine RPC-service noise, rather than the mapper only reporting what's relevant.
- A negative checker result is itself a valid reconnaissance finding: it does not motivate an exploitation write-up, and none is created for this activity.
- Corroborating a negative result with a second, independently-implemented tool strengthens confidence in the finding beyond what a single checker provides, the same reasoning that motivates cross-validation elsewhere in this project.
- As with other Windows DC reconnaissance in this project (`r-19`), findings here are recorded honestly rather than assumed; the Zerologon check failed, so `uow-csf-dc` does not demonstrate the CVE-2020-1472 flaw in this build.
