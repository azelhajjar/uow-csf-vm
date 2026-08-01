# Legacy Review

## Purpose

This document reviews the abandoned previous `legacy/` implementation attempt before new design or implementation work begins.

The legacy directory is context only. It is not the source of truth for the new project, and much of it may be obsolete, incomplete, experimental or unsuitable. It should not be executed, copied automatically, or treated as a design to preserve. Its purpose is to provide ideas that can be reused only where they still support the new CAV-CSF teaching VM design.

## Directory Structure

- `legacy/README.md`: short build notes pointing to the early setup scripts.
- `legacy/environment.md`: previous host, domain and account notes.
- `legacy/todo.md`: high-level note that the abandoned work was based on Metasploitable-style teaching VM ideas.
- `legacy/docs/`: contains `VM-brief.md` and `solution-checklist.md`, both currently empty.
- `legacy/scripts/`: previous build and configuration scripts for base VM setup, users, passwords, Samba, NFS, FTP, Apache, flags, Docker and status reporting.
- `legacy/scripts/vulnerabilities/`: scripts for Apache, PHP, MariaDB/MySQL and older vulnerable-service ideas.
- `legacy/configs/`: service configuration files and account/password data used by the previous attempt.
- `legacy/sites/`: Apache virtual-host reverse-proxy examples for vulnerable web applications.
- `legacy/artifacts/`: archived binaries and supporting packages used by the previous attempt.
- `legacy/flags/` and `legacy/scripts/files/flags/`: previous flag material.
- `legacy/public/`: public teaching/support material such as a dictionary list.

## Significant Components

### Base VM Build

The old `00-build-vm.sh` script shows the previous direction for host setup, package installation, service installation and directory creation. It is useful as evidence of what was attempted, not as a script to preserve.

Useful ideas:

- scripted build process;
- clear root check;
- build logging;
- service directories under `/srv`;
- checkpoint/status concept.

Design concerns to resolve:

- combines package installation, filesystem layout, service setup and handoff logic in one script;
- installs a broad package set before Phase 1 service selection is agreed;
- uses names and paths that may need to change;
- includes desktop VMware tools even though the target is Ubuntu Server;
- assumes old service choices before the new service catalogue is approved.

Decision: keep only the idea of reproducible provisioning. Replace the old build script with new Phase 2 provisioning once the Phase 1 design is approved.

### Users, Groups, Passwords and Flags

The old user scripts show possible fictional organisation users, groups, service accounts, shared directories and fixed flags. They are useful for ideas, not as an approved account model.

Useful ideas:

- named users and departments for organisational realism;
- service accounts;
- groups for Samba, NFS, administrative and departmental roles;
- credential reuse and account placement as teaching material;
- flags placed in user, root and service locations.

Issues:

- users, passwords, flags and filesystem permissions are mixed together in the old setup flow;
- flags use more than one format;
- there is no clear model for lab credentials, event flags, instructor notes and student-facing clues;
- the exact user set is not mapped to modules, services, AD integration or CTF use.

Decision: keep the idea of fictional users, groups and flag placement. Design the actual account, password and flag model from scratch for the new VM.

### Samba

The old Samba setup demonstrates a guest-writable public share with weak permissions and guest access.

Useful ideas:

- SMB enumeration target;
- anonymous or guest access;
- writable/readable share activities;
- file-based clues and possible credential leakage.

Design concerns to resolve:

- share purpose and expected student activity are not documented;
- permissions are broad and not linked to reset behaviour;
- no clear separation between introductory SMB enumeration and advanced credential-chain use.

Decision: keep SMB as a candidate service idea. Redesign the share catalogue, intended weaknesses, reset requirements and verification checks.

### NFS

The old NFS setup appears to aim for a shared directory with weak permissions and `no_root_squash` style behaviour.

Useful ideas:

- NFS enumeration target;
- weak export permissions;
- Linux privilege or file-access teaching route.

Design concerns to resolve:

- the legacy `configs/exports` file appears to contain FTP provisioning content rather than an NFS exports file;
- the export network is hardcoded;
- expected exploitation outcome and reset behaviour are not documented.

Decision: keep NFS as a candidate service idea, but replace the implementation and create a proper service design before provisioning.

### FTP

The old FTP work includes several attempted directions: packaged `vsftpd`, a legacy vulnerable `vsftpd 2.3.4` approach, anonymous upload, local-user access and a possible secondary FTP service.

Useful ideas:

- FTP enumeration;
- anonymous access;
- write/upload weakness;
- local account testing;
- service banner and version-recognition activity.

Design concerns to resolve:

- may rely on obsolete vulnerable binaries and 32-bit compatibility;
- fetches/builds software during provisioning;
- includes self-deleting one-shot scripts;
- mixes classic exploit demonstration with maintainability risk;
- service choice has not yet been approved in the new catalogue.

Decision: keep FTP as a candidate teaching service. Decide in Phase 1 whether the new VM needs modern FTP misconfiguration, a deliberately old service for a specific exploit lesson, or no FTP in the first build.

### Apache, PHP and Web Misconfiguration

The old Apache/PHP scripts show possible web-server misconfiguration ideas: directory listing, public server-status, verbose version information, CGI execution, broad overrides, writable web roots, PHP error display, URL include behaviour and weak logging/SSL settings.

Useful ideas:

- web server enumeration;
- information disclosure;
- directory listing;
- server-status exposure;
- insecure upload/file handling;
- weak PHP configuration;
- weak TLS/security-header discussion.

Design concerns to resolve:

- hardcoded PHP version;
- broad global changes rather than scoped teaching weaknesses;
- some settings may be obsolete or package-version dependent;
- no mapping from each misconfiguration to learning outcome and verification test.

Decision: keep selected Apache/PHP ideas only if they support the new service and vulnerability catalogue. Do not copy the old scripts.

### Database

The old MariaDB/MySQL work shows an attempt at remote database exposure and weak credentials.

Useful ideas:

- externally visible database service;
- service/version enumeration;
- weak credential testing;
- connection between database access and web/application findings.

Design concerns to resolve:

- fixed weak credential assumptions need to be made deliberate and documented;
- no explicit database schema or teaching purpose;
- no reset/verification design.

Decision: keep the exposed-database concept because the README requires at least one network-visible database service. Design the actual database role, accounts, schema, reset and verification for the new VM.

### Docker and Established Vulnerable Applications

The old Docker script and site configs show attempted container/reverse-proxy ideas for vulnerable web applications. They are not an approved application stack.

Useful ideas:

- containerised established vulnerable applications;
- named virtual hosts;
- reverse-proxy routing;
- landing-page links to public applications.

Design concerns to resolve:

- old script uses older package names and app choices without Phase 1 approval;
- no Docker Compose design is present;
- established application ports/hostnames are not documented as service-catalogue decisions;
- bWAPP/Mutillidae are not currently named in the new README requirements.

Decision: keep the idea of containerised established web apps and clear hostnames. Select the actual application set from the README and Phase 1 decisions.

### Status and Checkpoint Helpers

The old status script reports active services, listening ports, shares and staged artifacts. The checkpoint helper records text checkpoints. These are useful operational ideas, but they refer to the abandoned build.

Useful ideas:

- service status script;
- listening-port summary;
- share summary;
- checkpoint history;
- clear operational reporting for instructors.

Design concerns to resolve:

- old service names and paths are hardcoded;
- output is not connected to formal verification tests;
- no PASS/FAIL structure matching the new README.

Decision: keep the status/checkpoint idea and design new `scripts/status.sh` and `scripts/verify.sh` during Phase 2.

## Material Worth Reusing

- Fictional organisation accounts, groups and departmental roles.
- SMB, NFS, FTP, SSH, web and database as candidate network services.
- Guest/writable share concepts.
- Exposed database concept.
- Apache/PHP information disclosure and misconfiguration concepts.
- Containerised established web applications with clear hostnames.
- Status and checkpoint reporting.
- Flag placement across web, service, user and root contexts.

## Material Requiring Adaptation

- User and credential model.
- Flag format, generation, placement and verification.
- Samba and NFS permissions.
- FTP service design.
- Apache/PHP misconfiguration scope.
- Database exposure.
- Docker installation and Compose layout.
- Virtual-host naming.
- Status and verification scripts.

## Material That Should Be Replaced

- One-shot self-deleting provisioning scripts.
- Hardcoded package/version assumptions.
- Obsolete vulnerable-binary provisioning unless explicitly approved for a specific teaching purpose.
- Empty legacy docs.
- Incorrect or misplaced config content, including the apparent NFS/FTP mismatch in `legacy/configs/exports`.
- Broad global misconfiguration that is not mapped to learning outcomes.
- Any direct copy of instructor-only values into public or student-facing documentation where those values would reveal solutions rather than support the intended exercise.

## Unresolved Questions

- DECISION REQUIRED: Should FTP use a modern misconfiguration, a deliberately old vulnerable service, or both?
- DECISION REQUIRED: Which legacy user and department names should be retained, replaced or expanded?
- DECISION REQUIRED: What flag format should be used for regular labs versus CTF events?
- DECISION REQUIRED: Which SMB and NFS weaknesses should be included for Level 5 versus advanced activities?
- DECISION REQUIRED: Should DVWA be included, or should the established web-app set remain Juice Shop, WebGoat and Security Shepherd only?
- DECISION REQUIRED: Should the public web/reconnaissance scenario reuse existing CAV-style naming or introduce a new fictional organisation?
- DECISION REQUIRED: Which database technology should provide the externally visible database service?
- DECISION REQUIRED: Which legacy Apache/PHP misconfigurations are pedagogically useful enough to keep?
