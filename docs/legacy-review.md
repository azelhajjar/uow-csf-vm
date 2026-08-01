# Legacy Review

## Purpose

This document reviews the previous `legacy/` implementation attempt before new design or implementation work begins.

The legacy directory is context only. It should not be executed, copied automatically, or treated as complete. Ideas may be reused where they still support the new CAV-CSF teaching VM design.

## Directory Structure

- `legacy/README.md`: short build notes pointing to the early setup scripts.
- `legacy/environment.md`: previous host, domain and account notes.
- `legacy/todo.md`: high-level note that the work was based on Metasploitable-style teaching VM ideas.
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

The old `00-build-vm.sh` script performs host setup, package installation, service installation and directory creation. It also enables SSH and prepares `/srv/cav-csf` as the working directory on the VM.

Useful ideas:

- scripted build process;
- clear root check;
- build logging;
- service directories under `/srv`;
- checkpoint/status concept.

Issues:

- combines package installation, filesystem layout, service setup and handoff logic in one script;
- installs a broad package set before Phase 1 service selection is agreed;
- uses names and paths that may need to change;
- includes desktop VMware tools even though the target is Ubuntu Server;
- assumes old service choices before the new service catalogue is approved.

Decision: adapt the build-script idea, but replace the script with new Phase 2 provisioning once the Phase 1 design is approved.

### Users, Groups, Passwords and Flags

The old user scripts create fictional organisation users, groups, service accounts, shared directories and fixed flags. Password application is separated into a CSV-driven script.

Useful ideas:

- named users and departments for organisational realism;
- service accounts;
- groups for Samba, NFS, administrative and departmental roles;
- credential reuse and account placement as teaching material;
- flags placed in user, root and service locations.

Issues:

- users, passwords, flags and filesystem permissions are mixed together;
- flags use more than one format;
- there is no clear separation between instructor-only material, student-facing clues and provisioning state;
- the exact user set is not mapped to modules, services, AD integration or CTF use.

Decision: adapt the fictional users/groups concept and password/flag placement ideas. Redesign account and flag definitions as explicit instructor-owned data with reset and verification support.

### Samba

The old Samba setup creates a guest-writable public share with weak permissions and guest access.

Useful ideas:

- SMB enumeration target;
- anonymous or guest access;
- writable/readable share activities;
- file-based clues and possible credential leakage.

Issues:

- share purpose and expected student activity are not documented;
- permissions are broad and not linked to reset behaviour;
- no clear separation between introductory SMB enumeration and advanced credential-chain use.

Decision: reuse the SMB service idea. Redesign the share catalogue, intended weaknesses, reset requirements and verification checks.

### NFS

The old NFS setup aims to export a shared directory with weak permissions and `no_root_squash` style behaviour.

Useful ideas:

- NFS enumeration target;
- weak export permissions;
- Linux privilege or file-access teaching route.

Issues:

- the legacy `configs/exports` file appears to contain FTP provisioning content rather than an NFS exports file;
- the export network is hardcoded;
- expected exploitation outcome and reset behaviour are not documented.

Decision: reuse the NFS concept, but replace the implementation and create a proper service design before provisioning.

### FTP

The old FTP work includes packaged `vsftpd`, a legacy vulnerable `vsftpd 2.3.4` approach, anonymous upload, local-user access and a possible secondary FTP service.

Useful ideas:

- FTP enumeration;
- anonymous access;
- write/upload weakness;
- local account testing;
- service banner and version-recognition activity.

Issues:

- relies on obsolete vulnerable binaries and 32-bit compatibility;
- fetches/builds software during provisioning;
- includes self-deleting one-shot scripts;
- mixes classic exploit demonstration with maintainability risk;
- service choice has not yet been approved in the new catalogue.

Decision: adapt the FTP teaching goals. Decide in Phase 1 whether FTP should use modern misconfiguration, a deliberately old service, or both.

### Apache, PHP and Web Misconfiguration

The old Apache/PHP scripts enable directory listing, public server-status, verbose version information, CGI execution, broad overrides, writable web roots, PHP error display, URL include behaviour and weak logging/SSL settings.

Useful ideas:

- web server enumeration;
- information disclosure;
- directory listing;
- server-status exposure;
- insecure upload/file handling;
- weak PHP configuration;
- weak TLS/security-header discussion.

Issues:

- hardcoded PHP version;
- broad global changes rather than scoped teaching weaknesses;
- some settings may be obsolete or package-version dependent;
- no mapping from each misconfiguration to learning outcome and verification test.

Decision: adapt selected Apache/PHP misconfiguration ideas and implement them later as deliberate, documented, testable weaknesses.

### Database

The old MariaDB/MySQL work includes remote bind-address changes and weak credentials.

Useful ideas:

- externally visible database service;
- service/version enumeration;
- weak credential testing;
- connection between database access and web/application findings.

Issues:

- hardcoded credential assumptions;
- no explicit database schema or teaching purpose;
- no reset/verification design.

Decision: reuse the exposed-database concept because the README requires at least one network-visible database service. Redesign database role, accounts, schema, reset and verification.

### Docker and Established Vulnerable Applications

The old Docker script installs `docker.io` and `docker-compose`. Legacy site configs show reverse proxies for Juice Shop, WebGoat and DVWA. The older webapps script also references DVWA, bWAPP and Mutillidae.

Useful ideas:

- containerised established vulnerable applications;
- named virtual hosts;
- reverse-proxy routing;
- landing-page links to public applications.

Issues:

- old script uses older package names and app choices without Phase 1 approval;
- no Docker Compose design is present;
- established application ports/hostnames are not documented as service-catalogue decisions;
- bWAPP/Mutillidae are not currently named in the new README requirements.

Decision: adapt the reverse-proxy and containerised-app ideas for Juice Shop, WebGoat and Security Shepherd. Treat DVWA as optional and requiring approval.

### Status and Checkpoint Helpers

The old status script reports active services, listening ports, shares and staged artifacts. The checkpoint helper records text checkpoints.

Useful ideas:

- service status script;
- listening-port summary;
- share summary;
- checkpoint history;
- clear operational reporting for instructors.

Issues:

- old service names and paths are hardcoded;
- output is not connected to formal verification tests;
- no PASS/FAIL structure matching the new README.

Decision: adapt the status/checkpoint idea into new `scripts/status.sh` and `scripts/verify.sh` during Phase 2.

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
- Any direct copy of legacy instructor-only values into public or student-facing documentation.

## Unresolved Questions

- DECISION REQUIRED: Should FTP use a modern misconfiguration, a deliberately old vulnerable service, or both?
- DECISION REQUIRED: Which legacy user and department names should be retained, replaced or expanded?
- DECISION REQUIRED: What flag format should be used for regular labs versus CTF events?
- DECISION REQUIRED: Which SMB and NFS weaknesses should be included for Level 5 versus advanced activities?
- DECISION REQUIRED: Should DVWA be included, or should the established web-app set remain Juice Shop, WebGoat and Security Shepherd only?
- DECISION REQUIRED: Should the public web/reconnaissance scenario reuse existing CAV-style naming or introduce a new fictional organisation?
- DECISION REQUIRED: Which database technology should provide the externally visible database service?
- DECISION REQUIRED: Which legacy Apache/PHP misconfigurations are pedagogically useful enough to keep?
