# AD Integration

## Purpose

This document records the planned integration between the CAV-CSF Linux VM and the CAV-CSF Windows Active Directory VM.

The Linux VM remains the main general-purpose vulnerable services target. The Windows VM provides the Active Directory, DNS, Kerberos, SMB, and later AD CS learning environment.

## Current VM Roles

### Linux VM

- Hostname: `cav-csf-linux`
- IP address: `192.168.144.100`
- Role: general vulnerable Linux/service target

### Windows AD VM

- VMware VM name: `cav-csf-windows`
- Windows hostname: `uow-csf-dc`
- IP address: `192.168.144.200`
- Domain: `uow-csf.internal`
- FQDN: `uow-csf-dc.uow-csf.internal`
- NetBIOS name: `UOWCSF`
- Roles: AD DS and DNS

## Integration Direction

The Linux VM should integrate with the Windows domain environment once the Windows VM is stable.

Initial integration should focus on:

- DNS resolution between Linux and Windows.
- Linux awareness of the AD domain.
- References to the Windows DC through realistic service clues.
- Optional later Kerberos/LDAP/SSSD integration if it supports the teaching design.

## DNS Expectations

The Linux VM should be able to resolve:

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

## Possible Linux Integration Options

Possible later options include:

- Configure Linux resolver to use the Windows DC for `uow-csf.internal`.
- Add static fallback entries where appropriate for offline lab reliability.
- Join the Linux VM to the AD domain using SSSD/realmd.
- Use Kerberos-aware services or client tools.
- Add SMB references or shares that connect Linux and Windows activity paths.

## Important Constraint

Do not assume full Linux domain join is required until the teaching purpose is clear.

The first integration target is reliable name resolution and realistic cross-VM discovery. Full AD join should only be added if it supports a specific lab activity.

## Open Decisions

- Should the Linux VM fully join `uow-csf.internal`, or only resolve and reference it?
- Should Linux use the Windows DC as its primary DNS server?
- Should DNS fallback remain available when the Windows VM is offline?
- Which Linux services should contain breadcrumbs pointing to AD?
- Should Kerberos/LDAP/SSSD be part of the core lab or an advanced extension?
- Should SMB integration be Linux-to-Windows, Windows-to-Linux, or both?