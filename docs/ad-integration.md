# Active Directory Integration

## Purpose

The Linux VM must be capable of joining a separate Windows Server Active Directory domain as a genuine member server. AD integration is planned, but the final domain join must not be implemented until the Windows environment, domain name, users, groups and service accounts are agreed.

The VM must continue to support Linux-only teaching activities when the AD VM is not running.

## Planned Capabilities

- DNS integration.
- Kerberos.
- `realmd`.
- SSSD.
- Samba.
- AD user and group resolution.
- Selected AD-authenticated SSH access.
- Selected AD-authenticated SMB access.
- AD service account used by a Linux application or service.
- Cross-platform credential-discovery opportunity.
- Linux-to-Windows activity.
- Windows-to-Linux activity.

## Design Constraints

- Do not join AD during Phase 1.
- Do not implement final AD provisioning until Windows domain details are agreed.
- AD-dependent services should fail cleanly when the domain is unavailable.
- Linux-only activities must still work without the Windows AD VM.
- AD-linked credentials and cross-platform paths must be instructor documented.

## Possible Teaching Routes

### Linux Member Server Enumeration

Students identify that the Linux VM is domain joined and enumerate relevant configuration.

Status: DECISION REQUIRED.

### AD-Authenticated SSH or SMB

Selected AD users or groups can authenticate to Linux services.

Status: DECISION REQUIRED.

### AD Service Account Exposure

A Linux application or service uses an AD service account. Misplaced configuration or weak file permissions expose useful material.

Status: DECISION REQUIRED.

### Cross-Platform Credential Reuse

Credentials discovered on Linux support Windows or AD activity, or credentials from Windows support Linux access.

Status: DECISION REQUIRED.

## Required Future Inputs

- Domain name.
- Domain controller hostname and IP plan.
- AD users.
- AD groups.
- Service accounts.
- Allowed Linux access policy.
- DNS design.
- Kerberos realm.
- Classroom network assumptions.

## Verification Requirements

AD verification should check:

- VM boots correctly without AD;
- AD packages and services are installed when approved;
- domain join works when the AD VM is available;
- AD users and groups resolve;
- selected SSH/SMB access behaves as intended;
- AD-dependent services fail cleanly when AD is unavailable;
- intended cross-platform paths work as designed.

## Open Decisions

- DECISION REQUIRED: Domain name and Windows environment details.
- DECISION REQUIRED: Which AD users and groups should map to Linux access.
- DECISION REQUIRED: Which Linux service uses an AD service account.
- DECISION REQUIRED: Which cross-platform attack paths are included.
- DECISION REQUIRED: Whether AD integration appears before or after CTF support in the first release.
