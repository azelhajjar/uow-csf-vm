# Linux Privilege Escalation

## Purpose

CAV-CSF should include several independent Linux privilege-escalation opportunities of different difficulty. They must be intentional, documented, reliable after reset and mapped to learning outcomes.

The VM should not rely primarily on kernel exploits.

## Candidate Routes

### Weak Sudo Rule

Teaching purpose:

- introduce sudo enumeration;
- demonstrate command-specific privilege risk.

Possible design:

- a selected low-privilege user can run one carefully chosen command as another user or root.

Status: APPROVED for AP-01. The dedicated `stockroom` teaching account may run `/usr/bin/find` as root without a password. See `docs/attack-paths.md` for safety, reset and verification requirements.

### SUID Binary Misuse

Teaching purpose:

- teach filesystem permission review and SUID risk.

Possible design:

- a small custom or standard binary with an intentionally unsafe execution path.

Status: DECISION REQUIRED.

### Linux Capabilities Misuse

Teaching purpose:

- show capability-based privilege risk without full SUID.

Possible design:

- a binary with an excessive capability assigned.

Status: DECISION REQUIRED.

### Writable Privileged Script

Teaching purpose:

- demonstrate unsafe write permissions and scheduled/admin execution.

Possible design:

- a root-run maintenance script with controlled weak permissions.

Status: DECISION REQUIRED.

### Insecure Cron or Systemd Service

Teaching purpose:

- teach service and timer enumeration.

Possible design:

- a service, timer or cron task that trusts a writable path or environment value.

Status: DECISION REQUIRED.

### Exposed Credentials or Password Reuse

Teaching purpose:

- connect web/service findings to host access.

Possible design:

- credentials discovered through SMB, FTP, database, web app or documents work for a lower-privilege Linux user.

Status: APPROVED for AP-01. Anonymous FTP material exposes the generated credentials for the low-privilege `stockroom` teaching account; the value is not committed to the repository.

### Service Account Misuse

Teaching purpose:

- introduce service-account permissions and lateral movement concepts.

Possible design:

- an application or service account has access to a file, group or command that supports escalation.

Status: DECISION REQUIRED.

## Legacy Mapping

Legacy contains useful account, group, service-account, flag and shared-directory ideas. It does not provide a clean privilege-escalation design. Any route should be redesigned and documented before implementation.

## Requirements

Each route must include:

- affected user or service account;
- starting access assumption;
- required student technique;
- expected outcome;
- reset behaviour;
- verification test;
- instructor notes;
- difficulty level;
- module mapping.

## Open Decisions

- DECISION REQUIRED: Number of privilege-escalation routes in the first build.
- DECISION REQUIRED: Difficulty split across Level 5, Level 6, Level 7 and CTF.
- DECISION REQUIRED: Whether any route should chain from the custom application.
- DECISION REQUIRED: Whether any route should depend on AD integration.
