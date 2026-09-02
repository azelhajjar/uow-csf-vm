# AD Integration

## Purpose

This document records the integration between the CAV-CSF Linux VM and the CAV-CSF Windows Active Directory VM.

The Linux VM remains the main general-purpose vulnerable services target. The Windows VM provides the Active Directory, DNS, Kerberos, SMB, and later AD CS learning environment.

## Status

Superseded framing: this document was originally written before either the Windows DC or the Linux domain join existed, and described the integration as planned. That is now stale. Windows Phase 1 is complete, the DC is live at `192.168.144.200`, and the Linux master is static at `192.168.144.100` and joined to `uow-csf.internal`. The sections below separate confirmed working state from remaining design decisions.

## Current VM Roles

### Linux VM

- Hostname: `cav-csf-linux`
- IP address: `192.168.144.100` (final static master address)
- Role: general vulnerable Linux/service target

### Windows AD VM

- VMware VM name: `cav-csf-windows`
- Windows hostname: `uow-csf-dc`
- IP address: `192.168.144.200`
- Domain: `uow-csf.internal`
- FQDN: `uow-csf-dc.uow-csf.internal`
- NetBIOS name: `UOWCSF`
- Roles: AD DS and DNS
- Build state: Phase 1 baseline complete and validated, see `w-01-windows-ad-baseline-design.md`. Phase 2 is now substantially built and validated: Kerberoasting (`svc-web`, `e-18`), AS-REP roasting (`helpdesk01`, `e-19`), and DCSync domain replication rights abuse (`backup.operator`, `r-21`/`e-21`, the Windows Phase 2 capstone); the IIS intranet (`r-22`) and FTP service discovery (`r-23`); and a WordPress/IIS service (`w-01` section 15, `e-22`). `DnsAdmins` group-membership abuse was dropped, not included in Phase 2.

## Confirmed Working

- The master Linux VM has been joined to `uow-csf.internal` using `realmd` and `sssd`, via a dedicated `svc-linux-auth` service account.
- Domain user login to the Linux VM is confirmed working.
- Home directory auto-creation on first domain login is confirmed working.
- Windows 7 and Windows 10 clients join the domain and authenticate correctly, tested with `uowcsf\analyst`.

## Resolved Decisions

- **Should the Linux VM fully join `uow-csf.internal`, or only resolve and reference it?** Resolved: full join, completed via `realmd`/`sssd`. This supersedes the earlier constraint in this document that a full join should be deferred until a specific teaching purpose justified it.

## DNS Authority: Split, Tested, Accepted

Both machines hold a zone for `uow-csf.internal`. The Linux VM runs BIND9 authoritative for it, serving the infrastructure and web application records in `db.uow-csf.internal`, and the DC holds an AD-integrated primary zone for the same name, auto-populated with the SRV records AD requires.

This is a deliberate split rather than a fault, and it has been validated in the configuration that matters most: **all five web application platforms were tested with the Windows VM powered off and confirmed working.** The Linux VM continues to serve its own zone independently and does not depend on the DC being reachable.

The teaching pattern is what makes this the right trade-off. Students work on the Linux VM alone for the great majority of the curriculum; the Windows VM is used in one Level 6 module and one Level 7 module. Optimising the Linux VM for standalone operation therefore matches how the lab is actually used, and the Linux VM has already been supplied to the lab technician for the lab repository, so it is effectively frozen unless there is a strong reason to re-supply it.

Two consequences to keep in mind rather than fix:

- AD SRV lookups (`_ldap._tcp`, `_kerberos._tcp`) are served by the DC, so any Kerberos-dependent exercise driven from the Linux side needs the Windows VM running. That is expected for the two modules that use it.
- The deliberate `allow-transfer { any; }` misconfiguration on the Linux BIND9 instance is the basis of `e-16` and must survive any future change here.

Related record mismatch, low priority: the Linux zone advertises `dc01.uow-csf.internal → 192.168.144.200`, but the DC's hostname is `uow-csf-dc`. The address is right, the name is not. Either retain `dc01` as a deliberately stale legacy entry, which is realistic, or correct it during the next scheduled re-supply of the Linux VM.

## DNS Expectations

For the two modules that use both VMs, the Linux VM should be able to resolve:

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

Linux-to-DC DNS and reachability checks were previously recorded as outstanding in `w-01-windows-ad-baseline-design.md`, but the successful Linux domain join confirms the required integration path works. They remain relevant only to the two modules that use both VMs, and any Kerberos-dependent exercise should still be validated with both machines running.

## Resolved by Testing

- **Should Linux use the Windows DC as its primary DNS server?** No. The Linux VM keeps its own resolution, which is what allows it to work standalone.
- **Should DNS fallback remain available when the Windows VM is offline?** Effectively yes, and confirmed by test: all five web application platforms work with the Windows VM powered off.

## Remaining Open Decisions

- Which Linux services should contain breadcrumbs pointing to AD?
- Should Kerberos/LDAP/SSSD exercises be part of the core lab or an advanced extension? The join itself is done, so this is now a question about exercise design rather than capability.
- Should SMB integration be Linux-to-Windows, Windows-to-Linux, or both?
- Should Kali and both VMs share an NTP source? Clock skew silently breaks Kerberos exercises, so this needs settling before any cross-machine Kerberos activity is added.

## Next Build Step

Windows AD Phase 2, the deliberate vulnerability layer, is now substantially built and validated (see Build state above); `w-01-windows-ad-baseline-design.md` section 10 retains the original design/testing notes for reference. The remaining integration decisions are the ones listed above: Linux-side AD breadcrumbs, the SMB integration direction, and a shared NTP source for any future cross-machine Kerberos exercises.
