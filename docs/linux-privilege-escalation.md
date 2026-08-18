# Linux Privilege Escalation

## Purpose

CAV-CSF should include several independent Linux privilege-escalation opportunities of different difficulty. They must be intentional, documented and reliably reproducible on the completed VM.

The canonical runtime and student-delivery rules are defined in `docs/runtime-and-delivery-model.md`.

## Design Principles

- Do not make every privilege-escalation route part of one mandatory chain.
- Use several different weakness classes so students learn enumeration and reasoning rather than one repeated pattern.
- Misconfiguration-based privilege escalation remains valuable, but selected local/service CVEs may also be included where reliable and pedagogically appropriate.
- Do not rely primarily on kernel exploits.
- Runtime artefacts must use realistic names and conventional locations. Internal labels such as `AP-01` remain documentation-only.
- Students receive a fresh VM image and do not require per-route reset scripts.

## Candidate Routes

### Weak Sudo Rule

Teaching purpose:

- introduce sudo enumeration;
- demonstrate command-specific privilege risk.

Implemented example: the low-privilege `stockroom` teaching account can run `/usr/bin/find` as root without a password in the currently verified AP-01 route.

This is intentionally a configuration weakness and is retained because the weakness itself is pedagogically useful.

### SUID Binary Misuse

Teaching purpose:

- teach filesystem permission review and SUID risk.

Possible design:

- a standard or custom binary with an intentionally unsafe execution path.

Prefer a plausible operational binary/service name rather than `privesc`, `challenge`, `APxx` or similar teaching metadata.

### Linux Capabilities Misuse

Teaching purpose:

- show capability-based privilege risk without full SUID.

Possible design:

- a plausible operational binary with an excessive capability assigned.

### Writable Privileged Script or Service

Teaching purpose:

- demonstrate unsafe write permissions and privileged execution;
- teach service/timer/cron enumeration.

Possible design:

- a root-run maintenance script or systemd service that trusts a writable path or environment value.

Use realistic names such as a backup, reporting, inventory or synchronisation task. Do not call it `ap04-service`, `privesc.service` or similar.

### Exposed Credentials or Password Reuse

Teaching purpose:

- connect web/service findings to host access;
- demonstrate compound risk.

Possible sources include:

- FTP/SMB/NFS documents;
- application configuration;
- database records;
- backup files;
- shell history;
- AD-linked service credentials.

### Vulnerable Local or Service Software

Where practical, include a genuine CVE-based local/service privilege-escalation route in addition to configuration-based techniques.

For any such CVE document:

- exact product/version;
- CVE;
- starting privilege level;
- prerequisite conditions;
- exploitation method/tool;
- expected privilege gain;
- compatibility with Ubuntu 26.04;
- instructor verification.

Do not select an obsolete package merely to have a CVE if it is unreliable or adds excessive maintenance burden.

### Service Account Misuse

Teaching purpose:

- introduce service-account permissions;
- connect application compromise, file access and later privilege escalation;
- support advanced AD/lateral-movement concepts.

Possible design:

- an application or service account has access to a file, group, credential or delegated command that enables further privilege gain.

## Requirements

Each route should record:

- affected user/service account;
- starting access assumption;
- required enumeration technique;
- weakness type: CVE, configuration, credential or combination;
- expected outcome;
- instructor verification;
- difficulty level/module mapping;
- realistic deployed names/locations;
- developer recovery notes where necessary.

Do not add a student reset requirement to each route. Students normally recover by starting from a fresh VM image.

## Development Recovery

During active implementation, use VMware snapshots as temporary rollback points within the current phase. When the privilege-escalation phase is accepted, preserve the milestone using the planned full clone `CAV-CSF-04-PrivilegeEsc`.

Git remains the source/configuration history.
