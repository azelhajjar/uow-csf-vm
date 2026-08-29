# Activity: DNS Zone Transfer

## Summary

Exploitation of the unauthenticated AXFR zone transfer confirmed in `r-17- dns-enumeration.md`, using the disclosed internal naming scheme to inform and prioritise further reconnaissance across the rest of the environment.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.132 |
| Service | BIND9 9.18.49, `uow-csf.internal` zone |
| Attacker | Kali, 192.168.144.129 |
| Tooling | dig |

## Vulnerability

`named.conf.local` defines the zone with `allow-transfer { any; };`, permitting zone transfer requests from any client. Correct practice restricts this to the specific IP addresses of legitimate secondary DNS servers only. This is CWE-200 (Exposure of Sensitive Information), specifically DNS zone transfer misconfiguration, not a software vulnerability; BIND9 itself is current and functioning exactly as configured.

## Exploitation

**On Kali**, the transfer itself:

```bash
dig @192.168.144.132 uow-csf.internal AXFR
```

Full output already documented in `r-17- dns-enumeration.md`. The exploitation step here is using this disclosed information effectively, rather than the query itself, which is trivial.

**Interpreting and acting on the disclosed records:**

- **`files.uow-csf.internal`, `print.uow-csf.internal`, `mail.uow-csf.internal`, `www.uow-csf.internal`** all resolve to the same host, confirming this single machine runs the Samba share, CUPS print server, and mail service, corroborating findings already established in `r-14`/`e-13`, `r-12`/`e-12` and `r-18`/`e-17`. A student without prior knowledge of this VM's other services would gain a fast, reliable map of what's running where simply from these names, rather than needing to rediscover each service independently through port scanning alone.
- **`dc01.uow-csf.internal` → 192.168.144.200`** discloses the presence and expected address of a domain controller, valuable forward-looking intelligence even before that machine exists or is reachable: an attacker (or a student planning further attacks) now knows to watch for and prioritise this address once it becomes active, and knows the organisation is (or will be) running Active Directory.
- **`vpn-internal.uow-csf.internal` → 192.168.144.150`** and **`backup-legacy.uow-csf.internal` → 192.168.144.151`** point to addresses not currently reachable on this network segment. Confirming this:

```bash
nmap -p- -T4 192.168.144.150 192.168.144.151
```

Both hosts do not respond (not part of the current lab topology). This is itself a useful, correctly-interpreted negative result: the DNS records reveal the organisation's *intended* or *documented* internal naming scheme, which does not necessarily mean every named host is currently live or reachable from the attacker's position. Real assessments frequently encounter this exact situation, DNS zone data reflecting infrastructure that is planned, decommissioned, or simply on a different network segment, and correctly recording "record exists, host currently unreachable" rather than either ignoring the finding or assuming compromise is a meaningful professional distinction.

### Status note: the `dc01` record since this activity was written

The observations above are recorded exactly as made at the time, when no domain controller existed. That has since changed, and two points now need resolving before this activity is used with students:

- The Windows domain controller is built and live at `192.168.144.200`, so the `dc01` record is no longer a lead pointing at empty space. The address is correct, but the DC's actual hostname is `uow-csf-dc`, not `dc01`. Low priority, and correcting it would require re-supplying the Linux VM, so the practical choice is to retain `dc01` as a deliberately stale legacy record (realistic in its own right, and a reasonable teaching point about DNS records outliving the systems they named) or fold a correction into a future re-supply.
- The DC now serves its own AD-integrated zone for `uow-csf.internal`, so both machines hold the zone. This is an accepted deliberate split rather than a fault, and it does not affect this activity: the `dig @<linux-vm> ... AXFR` query is answered by the Linux VM's own BIND9 instance, so the exercise runs identically whether or not the Windows VM is powered on. Students can complete it on the Linux VM alone. Any future change to the DNS arrangement must preserve the `allow-transfer { any; }` misconfiguration, since this activity depends on it entirely. See `ad-integration.md`.

## Outcome

Confirmed full internal DNS zone disclosure via unauthenticated AXFR, providing a complete map of the organisation's known internal hostnames and their corresponding services, including confirmation of infrastructure not yet directly reachable (a domain controller, VPN, and legacy backup system). This information materially accelerates and focuses further reconnaissance across the rest of the environment.

## Remediation

- Restrict `allow-transfer` to the specific IP addresses of legitimate secondary DNS servers only, or `allow-transfer { none; }` if no secondary transfers are required at all.
- Consider TSIG (transaction signatures) for any legitimate zone transfers that are required, providing cryptographic authentication between primary and secondary servers rather than relying on IP-based restriction alone.
- Review the zone for any records that should not be publicly/internally queryable at all (e.g. records for decommissioned or highly sensitive internal systems) and consider whether they belong in a separate, more tightly restricted zone or view.

## Teaching Notes

This activity is a strong demonstration of DNS reconnaissance value beyond the technical mechanics of the AXFR query itself: the real skill being taught is correctly interpreting what a disclosed zone means, distinguishing currently-live infrastructure from documented-but-unreachable infrastructure, and using naming conventions to build a mental map of an organisation before touching most of its systems directly. Students should come away treating a successful zone transfer as the beginning of a reconnaissance phase, prioritising further investigation, not the end of one.

## Lab Dependencies

**Prerequisite exploit(s):** `r-17- dns-enumeration.md`
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Complete internal DNS zone disclosure; no shell or further system access directly
**Provides access for:** Corroborates `r-12`/`e-12` (CUPS) and `r-14`/`e-13` (Samba); the `dc01` record now points at the built Windows AD VM at `192.168.144.200`, subject to the hostname mismatch in the status note above; `vpn-internal` and `backup-legacy` remain open, currently-unreachable leads
**Suggested teaching level:** Level 5-6
