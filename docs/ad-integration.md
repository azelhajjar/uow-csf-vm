# AD Integration

## Purpose

This document records the integration between the CAV-CSF Linux VM and the CAV-CSF Windows Active Directory VM.

The Linux VM remains the main general-purpose vulnerable services target. The Windows VM provides the Active Directory, DNS, Kerberos, SMB, and later AD CS learning environment.

## Status

Superseded framing: this document was originally written before either the Windows DC or the domain join existed, and described the whole integration as planned. Both have since been built. The sections below now separate what is confirmed working from what is still an open decision.

## Current VM Roles

### Linux VM

- Hostname: `cav-csf-linux`
- IP address: `192.168.144.100` (intended final address; the master VM is currently at `192.168.144.130` pending the static IP migration tracked in `services-README.md`)
- Role: general vulnerable Linux/service target

### Windows AD VM

- VMware VM name: `cav-csf-windows`
- Windows hostname: `uow-csf-dc`
- IP address: `192.168.144.200`
- Domain: `uow-csf.internal`
- FQDN: `uow-csf-dc.uow-csf.internal`
- NetBIOS name: `UOWCSF`
- Roles: AD DS and DNS
- Build state: Phase 1 baseline built and validated, see `w-01-windows-ad-baseline-design.md`. No deliberate vulnerabilities applied yet.

## Confirmed Working

- The master Linux VM has been joined to `uow-csf.internal` using `realmd` and `sssd`, via a dedicated `svc-linux-auth` service account.
- Domain user login to the Linux VM is confirmed working.
- Home directory auto-creation on first domain login is confirmed working.
- Windows 7 and Windows 10 clients join the domain and authenticate correctly, tested with `uowcsf\analyst`.

## Resolved Decisions

- **Should the Linux VM fully join `uow-csf.internal`, or only resolve and reference it?** Resolved: full join, completed via `realmd`/`sssd`. This supersedes the earlier constraint in this document that a full join should be deferred until a specific teaching purpose justified it.

## Blocking Open Decision: DNS Authority

Both machines now claim authority for `uow-csf.internal`. The Linux VM runs BIND9 authoritative for the zone, serving the infrastructure and web application records in `db.uow-csf.internal`, and the DC holds an AD-integrated primary zone for the same name, auto-populated with the SRV records AD requires.

This is not currently reconciled, and it constrains the remaining DNS questions below rather than being independent of them:

- Pointing the Linux resolver at the DC breaks the five web application records (`webgoat`, `webwolf`, `dvwa`, `shepherd`, `juiceshop`) unless they are recreated in AD DNS.
- Leaving the Linux VM self-resolving means AD SRV lookups do not resolve from it, which limits any Kerberos-dependent exercise run from the Linux side.

Candidate approaches, none yet chosen: conditional forwarding of `_msdcs` and SRV lookups to the DC while BIND9 keeps the application records; replicating the application records into the AD-integrated zone and retiring the BIND9 authority; or an explicit split-horizon design documented as intentional.

Constraint on any solution: the deliberate `allow-transfer { any; }` misconfiguration on the Linux BIND9 instance is the basis of `e-16` and must survive whatever is decided.

Related record mismatch: the Linux zone advertises `dc01.uow-csf.internal → 192.168.144.200`, but the DC's hostname is `uow-csf-dc`. The address is right, the name is not. Either correct the record or document `dc01` as a deliberately retained stale entry.

## DNS Expectations

Once the authority question above is resolved, the Linux VM should be able to resolve:

```text
uow-csf-dc.uow-csf.internal
uow-csf.internal
_ldap._tcp.dc._msdcs.uow-csf.internal
_kerberos._tcp.uow-csf.internal
```

Expected DC IP:

```text
192.168.144.200
```

Linux-to-DC DNS and reachability checks are recorded as still outstanding in `w-01-windows-ad-baseline-design.md`. They cannot be meaningfully completed before the authority decision is made.

## Remaining Open Decisions

- Should Linux use the Windows DC as its primary DNS server? Dependent on the authority decision above.
- Should DNS fallback remain available when the Windows VM is offline? Relevant because the five web application platforms are reachable by hostname only while the Linux zone resolves.
- Which Linux services should contain breadcrumbs pointing to AD?
- Should Kerberos/LDAP/SSSD exercises be part of the core lab or an advanced extension? The join itself is done, so this is now a question about exercise design rather than capability.
- Should SMB integration be Linux-to-Windows, Windows-to-Linux, or both?
- Should Kali and both VMs share an NTP source? Clock skew silently breaks Kerberos exercises, so this needs settling before any cross-machine Kerberos activity is added.

## Next Build Step

Windows AD Phase 2, the deliberate vulnerability layer, is designed but not built. Proposed techniques and their prerequisites are in `w-01-windows-ad-baseline-design.md` section 10. Consistent with this project's methodology, none of them are treated as working until reproduced empirically and written up.
