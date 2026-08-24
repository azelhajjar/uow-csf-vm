# Runtime and Delivery Model

## Purpose

This document defines the canonical deployment, realism, vulnerability-selection and recovery model for CAV-CSF. Where older documentation conflicts with this document, this document takes precedence until the older text is corrected.

## Final student delivery model

The final deliverable is a completed vulnerable virtual machine image.

Students will receive the VM, not the Git repository, provisioning source, instructor manifests, build scripts, development notes or internal attack-path documentation. Each student starts from a fresh copy of the VM image.

There is therefore no requirement for student-facing activity reset mechanisms. Do not create student reset buttons, reset menus, per-challenge restore scripts, reset web pages or similar features. If a student VM becomes unusable, the normal recovery method is to replace it with a fresh copy of the distributed VM image.

Provisioning, verification and recovery scripts may exist for developers and instructors, but they are build and maintenance artefacts. They are not part of the student experience and must not be described as student activity reset facilities.

## One VM, multiple teaching uses

There is one complete Linux VM containing the intended services, applications and vulnerabilities. There are no Level 5, Level 6, Level 7 or CTF VM profiles and no requirement to enable or disable vulnerabilities by module.

Teaching guides control scope, depth, permitted techniques and the amount of guidance. The VM itself remains the same.

## What counts as a vulnerability

The VM must not become merely a collection of deliberate misconfigurations.

The intended mix includes:

- genuine exploitable CVEs;
- vulnerable network services and applications;
- web and API vulnerabilities;
- authentication and credential weaknesses;
- service and filesystem misconfigurations;
- Linux privilege-escalation weaknesses;
- selected cross-platform AD-related weaknesses.

### Vulnerability-selection priority

Where practical, prefer a genuine exploitable CVE over a standalone misconfiguration.

Use this priority:

1. A genuine CVE with a reliable, reproducible and teachable exploitation path. Where suitable, prefer vulnerabilities with a reliable Metasploit module so students can identify the service/version, research the CVE and exploit it through `msfconsole`.
2. A CVE combined with one or more deliberate misconfigurations where the combination improves the teaching scenario or attack chain.
3. A standalone misconfiguration where no suitable CVE is practical, reliable or pedagogically appropriate.

Do not replace a suitable CVE-based activity with a simple misconfiguration merely because the misconfiguration is easier to implement.

The Ubuntu base operating system remains modern. Individual deliberately selected services or applications may use vulnerable versions when that is necessary to provide a controlled CVE-based teaching activity.

For each proposed CVE-based service, document the service, version, port, CVE, vulnerability type, available Metasploit module where applicable, required preconditions, expected outcome and teaching level.

## Reconnaissance and discoverability

Students should be able to discover weaknesses through normal penetration-testing methodology:

Reconnaissance -> Enumeration -> Vulnerability identification -> Exploitation -> Post-exploitation

Services intended for network teaching must be visible and enumerable from the VM network. Containerisation must not hide databases, file-sharing services or other supporting infrastructure that students are expected to discover with Nmap or protocol-specific enumeration.

Use a deliberate mixture of host services, published container ports and internal-only services. Internal-only services should exist only when their hidden placement has a specific advanced-discovery or post-exploitation purpose.

## Runtime realism

The deployed VM must resemble a plausible real-world Linux server. Internal teaching metadata must not leak into the runtime environment.

Repository and instructor documentation may use identifiers such as `AP01`, `AP02`, `WEB01` or `NET03`. Those identifiers must not appear in deployed runtime artefacts unless they are intentionally part of a student-facing scenario.

Do not create deployed paths such as:

- `/opt/cav-csf/ap03/samba/`
- `/srv/challenge-04/`
- `/var/www/web01/`
- `/opt/attack-path-2/`

Prefer normal package locations or plausible operational names, for example:

- `/etc/samba/smb.conf`
- `/srv/shared`
- `/srv/backups`
- `/var/www/portal`
- `/var/www/intranet`
- `/opt/reporting-service`
- `/opt/samba-legacy/` when an isolated legacy build genuinely requires it

Teaching metadata must not unnecessarily appear in directory names, service names, systemd units, process names, usernames, groups, database names, schemas, SMB shares, DNS names, hostnames, web routes, application titles, configuration filenames, cron names, log names or environment-variable names.

Repository organisation may be pedagogical. Runtime organisation must be realistic.

## Development milestones, clones and snapshots

The planned full-clone milestones are:

- `CAV-CSF-00-Clean`
- `CAV-CSF-01-Base`
- `CAV-CSF-02-Web`
- `CAV-CSF-03-Network`
- `CAV-CSF-04-PrivilegeEsc`
- `CAV-CSF-05-AD-Integrated`
- `CAV-CSF-Release`

These are development milestones, not student editions.

Use full clones as permanent milestone backups. Use snapshots as temporary rollback points during active work within a phase. A phase may have several snapshots before risky installations or configuration changes. Once a phase is accepted, unnecessary temporary snapshots may be removed and a full clone is created for the completed milestone.

Git provides source/configuration history. VMware snapshots provide short-term rollback within a phase. Full clones provide permanent milestone recovery. The final VM image is the student-facing release.

## Verification versus reset

Every intentional vulnerability must be verifiable. Verification means confirming that the intended vulnerable state exists and behaves as designed.

Do not infer from this requirement that every vulnerability needs a student-facing reset process.

Developer/instructor recovery may use provisioning, idempotent configuration, scripts, snapshots or full clones as appropriate. Student recovery is normally a fresh VM copy.
