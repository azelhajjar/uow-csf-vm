# Active Directory Integration

## Purpose

The Linux VM must be capable of joining a separate Windows Server Active Directory domain as a genuine member server.

The same completed Linux VM is used for Linux-only teaching and for advanced cross-platform activities. There is no separate AD-enabled Linux edition.

The canonical runtime and student-delivery rules are defined in `docs/runtime-and-delivery-model.md`.

## Planned Capabilities

- DNS integration;
- Kerberos;
- `realmd`;
- SSSD;
- Samba;
- AD user and group resolution;
- selected AD-authenticated SSH access;
- selected AD-authenticated SMB access;
- AD service account used by a Linux application or service;
- cross-platform credential-discovery opportunity;
- Linux-to-Windows activity;
- Windows-to-Linux activity.

## Design Constraints

- Linux-only activities must continue to work when the Windows AD VM is not running.
- AD-dependent services should fail cleanly when the domain is unavailable.
- AD-linked credentials and cross-platform paths are instructor/internal information.
- Runtime users, groups, shares, services and paths must use plausible organisational names. Do not expose `APxx`, `cav-csf`, challenge numbers or module labels as runtime naming conventions.
- Cross-platform weaknesses may use misconfiguration, credential exposure or genuine software vulnerabilities as appropriate.
- Do not add student-facing reset mechanisms. Students begin from a fresh completed VM image.

## Teaching Uses

### Linux Member Server Enumeration

Students may identify that the Linux VM is domain joined and enumerate relevant Kerberos, DNS, SSSD, Samba and identity information.

### AD-Authenticated SSH or SMB

Selected AD users/groups may authenticate to Linux services where this supports advanced teaching.

### AD Service Account Exposure

A Linux application/service may use an AD service account. A deliberately exposed credential, keytab, configuration file or overbroad permission can create a Linux-to-AD path.

### Cross-Platform Credential Reuse

Credentials discovered on Linux may support Windows/AD activity, while credentials recovered from Windows may support Linux access.

### CVE-Based Cross-Platform Opportunity

Where a reliable CVE in a Linux-hosted service or Windows/AD-facing component provides a meaningful cross-platform path, prefer it over constructing an artificial configuration-only weakness.

Document exact version, CVE, prerequisites, tool/module availability and expected result.

## Required Inputs

Before final integration, define:

- domain name;
- domain controller hostname/IP plan;
- AD users;
- AD groups;
- service accounts;
- Linux access policy;
- DNS design;
- Kerberos realm;
- classroom network assumptions;
- intended cross-platform attack paths.

## Verification Requirements

AD verification should confirm:

- VM boots and Linux-only labs remain usable without AD;
- domain join succeeds when the Windows environment is available;
- AD users/groups resolve correctly;
- selected SSH/SMB access behaves as intended;
- AD-dependent services fail cleanly when AD is unavailable;
- intended cross-platform paths work;
- final runtime names are realistic and do not expose internal teaching identifiers.

## Development Milestone

The accepted AD-integrated state is preserved as the permanent full-clone milestone:

`CAV-CSF-05-AD-Integrated`

Snapshots may be used during the active AD-integration phase for short-term rollback. Student recovery remains replacement with a fresh VM image.
