# Activity: DNS Enumeration

## Summary

Reconnaissance of the newly added internal DNS service, confirming it serves an authoritative zone (`uow-csf.internal`) for this organisation's infrastructure, and that a full unauthenticated zone transfer (AXFR) discloses every record in the zone, including internal hostnames not otherwise directly discoverable.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.132 |
| Service | BIND9 9.18.49, port 53/tcp+udp |
| Attacker | Kali, 192.168.144.129 |
| Tooling | dig |

## Reconnaissance

### Step 1: Port confirmation

```bash
nmap -sV -p 53 192.168.144.132
```

Confirms `53/tcp` and `53/udp` open, new ports not present in the original `r-02` baseline, running BIND 9.18.49.

### Step 2: Basic name resolution

```bash
dig @192.168.144.132 uow-csf.internal NS
```

```
;; ANSWER SECTION:
uow-csf.internal.       604800  IN      NS      ns1.uow-csf.internal.
```

Confirms the server is authoritative for a zone named `uow-csf.internal`, discoverable simply by querying it directly once the domain name is known or guessed (e.g. from other reconnaissance, such as hostnames referenced elsewhere on the network).

```bash
dig @192.168.144.132 print.uow-csf.internal A
```

```
;; ANSWER SECTION:
print.uow-csf.internal. 604800  IN      A       192.168.144.132
```

Confirms individual record lookups work normally; `print.uow-csf.internal` correctly resolves to the target, consistent with the CUPS print server already identified on this host.

### Step 3: Zone transfer (AXFR)

```bash
dig @192.168.144.132 uow-csf.internal AXFR
```

```
uow-csf.internal.       604800  IN      SOA     ns1.uow-csf.internal. admin.uow-csf.internal. 1 604800 86400 2419200 604800
uow-csf.internal.       604800  IN      NS      ns1.uow-csf.internal.
backup-legacy.uow-csf.internal. 604800 IN A     192.168.144.151
dc01.uow-csf.internal.  604800  IN      A       192.168.144.200
files.uow-csf.internal. 604800  IN      A       192.168.144.132
mail.uow-csf.internal.  604800  IN      A       192.168.144.132
ns1.uow-csf.internal.   604800  IN      A       192.168.144.132
print.uow-csf.internal. 604800  IN      A       192.168.144.132
vpn-internal.uow-csf.internal. 604800 IN A      192.168.144.150
www.uow-csf.internal.   604800  IN      A       192.168.144.132
```

**This is the core finding.** A single, entirely unauthenticated `AXFR` query returns the complete zone, every hostname the organisation has defined, in one response. This is a fundamentally different, and far more efficient, reconnaissance technique than guessing or brute-forcing individual subdomain names one at a time: instead of trying `www`, `mail`, `vpn`, `backup`, etc. and hoping for a hit, the entire naming scheme is handed over in a single query.

Two entries stand out as genuinely valuable leads beyond the already-known services: `dc01.uow-csf.internal` (suggesting a domain controller, presumably part of a Windows AD environment not yet directly reachable or built) and `vpn-internal`/`backup-legacy` (suggesting infrastructure the organisation has, that isn't otherwise announced anywhere else on the network). A zone transfer can reveal the *existence* and *naming conventions* of internal systems even when those specific hosts aren't currently reachable, itself valuable intelligence about the target organisation's infrastructure and internal naming habits.

The `dc01` observation above is recorded as it stood when this activity was run. The Windows domain controller has since been built at that address, under the hostname `uow-csf-dc` rather than `dc01`; see the status note in `e-16- dns-zone-transfer.md` for the resulting record-naming and zone-authority items still to be resolved. `vpn-internal` and `backup-legacy` remain unreachable as described.

### Step 4: Corroborating via NSE

```bash
ls -l /usr/share/nmap/scripts/ | grep -i dns
```

A large DNS script family exists; `dns-zone-transfer` is the direct NSE equivalent of the manual `dig AXFR` technique already used in Step 3.

```bash
nmap -p 53 --script dns-zone-transfer --script-args dns-zone-transfer.domain=uow-csf.internal 192.168.144.132
```

```
| dns-zone-transfer:
| uow-csf.internal.                SOA  ns1.uow-csf.internal. admin.uow-csf.internal.
| uow-csf.internal.                NS   ns1.uow-csf.internal.
| backup-legacy.uow-csf.internal.  A    192.168.144.151
| dc01.uow-csf.internal.           A    192.168.144.200
...
```

This script worked correctly and reproduced the identical zone content already confirmed via `dig`, good corroboration between two independent tools. A harmless `NSE: Skipping 'dns-zone-transfer' prerule, 'dnszonetransfer.server' argument is missing` warning appears alongside the result; this relates to an unrelated pre-scan hostname-discovery step the script optionally supports and does not affect the actual zone-transfer test, which ran and succeeded regardless.

## Outcome

Confirmed BIND9 is configured with `allow-transfer { any; }`, permitting any client to request a full zone transfer without authentication. This disclosed the organisation's complete internal DNS zone in a single query, including references to infrastructure (a domain controller, VPN, legacy backup system) beyond the services already directly identified on this host.

## Remediation

See `e-16- dns-zone-transfer.md` for full remediation guidance.

## Teaching Notes

Zone transfer misconfiguration is one of the longest-standing, still commonly found DNS issues in real assessments, DNS was originally designed assuming zone transfers between trusted primary/secondary servers, and `allow-transfer` defaulting to overly permissive or unset values has caused this exact class of disclosure for decades. This activity is a good demonstration of the efficiency gained by a single well-placed technique (AXFR) versus the alternative (subdomain brute-forcing with a wordlist), and a good prompt to discuss why DNS, despite being one of the internet's oldest and most fundamental protocols, still regularly produces serious real-world findings.

## What is DNS?

DNS (Domain Name System) is the internet's naming system, translating human-readable hostnames (like `print.uow-csf.internal`) into the numeric IP addresses computers actually use to communicate. Every organisation with its own network typically runs internal DNS servers to manage its own private naming scheme, letting staff and systems refer to internal resources by memorable names rather than raw IP addresses. Because DNS servers are designed to answer queries from many different systems, and because internal DNS zones often reflect an organisation's entire internal naming and infrastructure layout, a misconfigured DNS server can become one of the single richest sources of reconnaissance information available to an attacker.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Full disclosure of the internal DNS zone
**Provides access for:** Precedes `e-16- dns-zone-transfer.md`; the `dc01` record now correlates to the built Windows AD VM at `192.168.144.200` (hostname mismatch noted in `e-16`), while `vpn-internal`/`backup-legacy` remain open leads for future correlation once corresponding services/VMs exist
**Suggested teaching level:** Level 5
