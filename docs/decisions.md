# Decisions

## Purpose

This file records approved design decisions and decisions that still require approval.

The canonical runtime, student-delivery, vulnerability-selection and recovery rules are defined in `docs/runtime-and-delivery-model.md`. Where an older decision conflicts with that document, the newer canonical decision below takes precedence.

## Approved Core Decisions

### Student Delivery Model

- APPROVED: Students receive only the completed VM image and the relevant teaching material.
- APPROVED: Students do not receive the Git repository, provisioning source, build scripts, developer recovery tooling, instructor manifests or internal attack-path documentation.
- APPROVED: Each student starts from a fresh copy of the VM image.
- APPROVED: Do not design student-facing reset buttons, reset menus, per-activity restore scripts, reset web endpoints or challenge-reset workflows.
- APPROVED: Developer/instructor recovery scripts may exist where useful, but they are build/maintenance artefacts only.
- APPROVED: If a student VM becomes unusable, the normal recovery method is to replace it with a fresh copy of the distributed image.

### One VM, Multiple Teaching Uses

- APPROVED: Build one complete Linux VM containing the intended applications, services and vulnerabilities.
- APPROVED: Do not create separate Level 5, Level 6, Level 7 or CTF VM profiles.
- APPROVED: Teaching guides determine scope, expected techniques, depth and guidance level.
- APPROVED: The same VM may later participate in advanced cross-platform activities with the separate Windows AD environment.

### Vulnerability Selection

- APPROVED: The VM must not be only a collection of deliberate misconfigurations.
- APPROVED: Where practical, prefer a genuine exploitable CVE with a reliable teaching path over a standalone configuration weakness.
- APPROVED: Where appropriate, prefer CVEs with reliable Metasploit modules so students can progress from reconnaissance and version identification to CVE research and exploitation through `msfconsole`.
- APPROVED: Combining a genuine CVE with weak credentials, unsafe permissions or another deliberate misconfiguration is acceptable and often desirable.
- APPROVED: Use a standalone misconfiguration when no suitable CVE is practical/reliable or when the configuration weakness itself is the learning objective.
- APPROVED: Keep the Ubuntu base operating system modern, but allow deliberately selected vulnerable service/application versions when required for controlled CVE-based teaching.
- APPROVED: Do not reject a suitable vulnerable service solely because its version is old if the version is deliberately pinned, reproducible and pedagogically valuable.

### Runtime Realism

- APPROVED: Internal identifiers such as `AP-01`, `AP-02`, `WEB01`, challenge numbers and repository names are documentation/development labels only.
- APPROVED: They must not dictate student-visible runtime directory names, service names, systemd units, process names, usernames, groups, database names, schemas, SMB shares, DNS names, hostnames, web routes, configuration filenames, cron names, log names or environment-variable names.
- APPROVED: Prefer standard Linux paths and normal package layouts where possible.
- APPROVED: Where an isolated vulnerable build requires a custom location, use a plausible operational name such as `/opt/document-transfer/`, `/opt/samba-legacy/`, `/var/www/warehouse/` or another scenario-appropriate equivalent rather than `/opt/cav-csf/apxx/...`.
- APPROVED: Repository organisation may be pedagogical; deployed runtime organisation must be realistic.
- APPROVED: Existing development-labelled AP-02 runtime artefacts must be migrated to realistic operational names before the final release VM is produced.

### Development Recovery

- APPROVED: Git is the source/configuration/documentation history.
- APPROVED: VMware snapshots are temporary short-term rollback points during active work within a development phase.
- APPROVED: Full clones are permanent completed-phase milestone backups.
- APPROVED: A phase may contain several temporary snapshots before risky installations or configuration changes.
- APPROVED: The planned permanent full-clone milestones are:
  - `CAV-CSF-00-Clean`
  - `CAV-CSF-01-Base`
  - `CAV-CSF-02-Web`
  - `CAV-CSF-03-Network`
  - `CAV-CSF-04-PrivilegeEsc`
  - `CAV-CSF-05-AD-Integrated`
  - `CAV-CSF-Release`
- APPROVED: These milestones are development/recovery artefacts, not separate student editions.

## Approved Platform and Scenario Decisions

- APPROVED: Retain `CAV-CSF` as the project/repository working name during development.
- APPROVED: Avoid unnecessary coupling of deployed service names, hostnames and internal paths to the repository name.
- APPROVED: Use Ubuntu Server 26.04 LTS as the Linux base platform.
- APPROVED: Use VMware Workstation as the primary VM platform.
- APPROVED: Use **Brightleaf Retail Ltd** as the fictional organisation unless explicitly changed later.
- APPROVED: Use the reserved `brightleaf.test` namespace for internal lab services.
- APPROVED: Use `www.brightleaf.test` for the internal landing site.
- APPROVED: `cwscenario.uk` is an optional contextual/OSINT companion resource; the VM must not depend on it for core lab operation.

## Approved Service Architecture Decisions

- APPROVED: The VM must expose a meaningful host-visible attack surface for Nmap and protocol-specific enumeration.
- APPROVED: Docker may be used where it improves deployment/maintenance, but must not hide services students are expected to discover.
- APPROVED: Use a deliberate mix of host services, published container services and selected internal-only services.
- APPROVED: At least one database must be network-visible and usable for direct enumeration/testing.
- APPROVED: Run OWASP Juice Shop, WebGoat and Security Shepherd as externally reachable applications where compatibility permits.
- APPROVED: Develop a separate project-owned custom vulnerable application for curriculum-aligned web testing and CTF use.
- APPROVED: Host SSH used for instructor/administrator maintenance must remain separate from student-facing teaching access.
- APPROVED: If student-facing SSH uses TCP 22, move administrative SSH to a separate protected management port first and verify it before releasing TCP 22.
- APPROVED: HTTP, internal DNS, SMB, NFS, FTP and a network-visible database are intended service families for the wider build, subject to phase-specific implementation decisions.
- APPROVED: FTP may include both configuration-based and genuine CVE-based teaching opportunities. The verified AP-02 ProFTPD path demonstrates the desired CVE-based direction.
- APPROVED: Selected service versions may be deliberately pinned for CVE teaching where reliable and maintainable.

## Approved AP-01 Decisions

- APPROVED: AP-01 is an internal documentation identifier only.
- APPROVED: AP-01 provides an introductory configuration/credential chain: anonymous FTP clue -> low-privilege credential reuse -> student-facing SSH -> unsafe sudo rule -> root/effective UID 0.
- APPROVED: Use the `stockroom` account for the currently verified reference route.
- APPROVED: The unsafe sudo rule uses `/usr/bin/find` for the introductory privilege-escalation outcome.
- APPROVED: AP-01 is intentionally a misconfiguration/credential exercise and remains useful even though future service paths should prefer genuine CVEs where practical.
- APPROVED: Any AP-01 recovery script is instructor/developer tooling only and must not be presented as a student reset feature.
- APPROVED: Before release, ensure no AP-01/repository-derived runtime naming remains visible to students.

## Approved AP-02 Decisions

- APPROVED: AP-02 is an internal documentation identifier only.
- APPROVED: ProFTPD 1.3.5 with `mod_copy` is retained as the verified CVE-2015-3306 teaching service.
- APPROVED: AP-02 is host-native/source-built rather than containerised.
- APPROVED: The currently verified reference implementation exposes ProFTPD on TCP 2121 and links the vulnerable file-copy condition to an Apache/PHP web-served boundary.
- APPROVED: Live testing established that the intended web-root effect requires the anonymous context/service identity; named logins do not have the same web-root permissions.
- APPROVED: Separate health/configuration verification from instructor-controlled exploit acceptance testing.
- APPROVED: Current development-labelled runtime names such as `/opt/cav-csf/ap02/...`, `/var/www/brightleaf-ap02`, `cav-csf-ap02-proftpd.service` and AP-02-specific configuration paths are temporary development artefacts and must be renamed before release.
- APPROVED: The final names must be realistic operational names while preserving the exact vulnerable condition.
- APPROVED: Any AP-02 recovery script is instructor/developer tooling only and is not part of the student workflow.

## Approved CTF Decisions

- APPROVED: CTF use will use the same completed VM/custom application rather than a separate VM profile.
- APPROVED: CTF event preparation may replace or generate flags before the event image is frozen/distributed.
- APPROVED: Students/teams receive fresh event VM copies and do not need per-challenge reset controls.
- APPROVED: Internal challenge/flag identifiers must not leak into runtime naming unless intentionally part of the fictional scenario.

## Decisions Still Required

### Web and Custom Application

- DECISION REQUIRED: Final custom application technology stack.
- DECISION REQUIRED: Final custom application vulnerability list.
- DECISION REQUIRED: Which application findings chain into host, service or AD activities.
- DECISION REQUIRED: Final database choice/exposure model if PostgreSQL is changed.

### Network Services

- DECISION REQUIRED: Final CVE/service candidates for SMB/Samba, additional FTP services, database components and any other network services.
- DECISION REQUIRED: Which CVE candidates must have Metasploit modules versus which may use manual exploitation.
- DECISION REQUIRED: Final externally visible port plan.
- DECISION REQUIRED: Whether SMTP, SNMP, HTTPS, DVWA or a custom TCP service are included in the first release.

### Linux Privilege Escalation

- DECISION REQUIRED: Number and final mix of privilege-escalation routes.
- DECISION REQUIRED: Whether to include a genuine CVE-based local/service privilege-escalation route in addition to configuration-based routes.
- DECISION REQUIRED: Which route, if any, chains directly from the custom application.

### Active Directory

- DECISION REQUIRED: Domain name and Windows environment details.
- DECISION REQUIRED: AD users, groups and service accounts used by Linux.
- DECISION REQUIRED: Which AD-authenticated Linux services are included.
- DECISION REQUIRED: Which Linux-to-Windows and Windows-to-Linux attack paths are implemented.

### CTF

- DECISION REQUIRED: Final flag prefix for the first event.
- DECISION REQUIRED: Initial number of flags.
- DECISION REQUIRED: Flag locations and instructor manifest format.
- DECISION REQUIRED: Whether AD-linked flags are included in the first event/release.
