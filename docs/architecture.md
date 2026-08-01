# Architecture

## Purpose

CAV-CSF will be one reusable Ubuntu Server vulnerable teaching VM. It will support network penetration testing, web application penetration testing, cyber security labs, advanced penetration testing, Level 7 scenario work and University-run CTF events from one common installation.

The VM will not use separate module profiles or dynamically enabled vulnerability sets. Teaching guides will control what each student group is asked to investigate.

## Base Platform

- Operating system: Ubuntu Server 26.04 LTS.
- Architecture: amd64.
- Installation type: minimal server installation.
- Primary virtualisation platform: VMware Workstation.
- Host services: systemd.
- Provisioning scripts: Bash and Python.
- Containers: Docker Engine and Docker Compose where containerisation improves maintainability and reset reliability.

## Deployment Boundary

The final vulnerable environment runs inside the Ubuntu Server VM. The Windows host is only the VMware host. Repository work in Codex creates and validates source-controlled files but does not prove Ubuntu VM integration.

Ubuntu VM integration, exploitation testing and instructor acceptance testing will be performed manually on the VM.

## High-Level Layout

The intended source layout is:

```text
docs/
provisioning/
containers/
custom-app/
flags/
scripts/
tests/
instructor/
```

All new implementation must remain outside `legacy/`.

## Service Architecture

The VM should expose a meaningful host-visible attack surface. Services will use a deliberate mix of:

- host-installed services;
- containerised applications with ports published on the VM network interface;
- selected supporting services with published ports;
- internal-only supporting services used for advanced discovery or post-exploitation.

Docker must not hide services that students are expected to discover during network reconnaissance.

Administrative SSH must remain distinct from the vulnerable teaching environment. During the base build, host SSH remains on TCP 22 for administration. Before teaching SSH is deployed, administrative SSH will move to a separately secured management port and be tested before TCP 22 is released. The teaching SSH service will then use TCP 22 for realistic discovery. Administrative SSH must use key-only authentication, restrict permitted users and, where practical, restrict source addresses or bind to a management interface.

## Proposed Service Groups

- Core administration: host SSH on a separately secured management port, migrated safely from the base-build TCP 22 configuration.
- Core discovery: HTTP, HTTPS and DNS.
- Teaching access: a separate, resettable SSH service with its own accounts, published on TCP 22.
- Network services: FTP, SMB, NFS, SNMP, SMTP, database service, custom TCP service.
- Established web applications: Juice Shop, WebGoat, Security Shepherd, and optional DVWA if approved.
- Custom vulnerable application: original project-owned web/API/database application.
- CTF support: flag placement, manifest generation and verification.
- AD integration: Linux member-server capability for a separate Windows Server Active Directory domain.

## Reconnaissance Surface

The VM represents **Brightleaf Retail Ltd**, a fictional UK technology retailer serving consumers, SMEs, education customers and trade partners. The same organisation appears on the public `cwscenario.uk` OSINT site. The internal lab should include:

- public web pages;
- hostnames and virtual hosts;
- DNS records;
- service banners;
- documents and metadata;
- staff, department and support references;
- realistic directory and file names.

Critical classroom reconnaissance material must work inside the host-only lab network. The public domain `cwscenario.uk` is a safe, OSINT-only companion asset and must not host deliberately vulnerable components or be presented as an active-testing target. The VM must not depend on it.

## Reset and Recovery Architecture

Reset and recovery should distinguish:

- rebuilding the VM from source;
- restoring a clean VMware snapshot;
- resetting applications and databases;
- resetting user files and flags;
- checking service health;
- verifying intended vulnerabilities.

Reset scripts must not silently repair deliberate vulnerabilities.

## Verification Architecture

Verification should report clear results:

- PASS;
- FAIL;
- expected vulnerability missing;
- unintended exposure detected;
- dependency unavailable.

Verification should cover listening ports, application responses, accounts, permissions, vulnerabilities, flags, reset behaviour, AD-offline boot and AD-online integration.

## Constraints

- Do not implement vulnerabilities during Phase 1.
- Do not rely primarily on obsolete operating-system packages.
- Do not place every service inside Docker-internal networks.
- Do not expose instructor credentials, hidden accounts, flags or exploitation paths in public/student-facing documentation.
- Do not join Active Directory until Windows environment details are agreed.

## Open Decisions

- DECISION REQUIRED: Final fictional organisation name and naming scheme.
- DECISION REQUIRED: Final service catalogue and port exposure.
- DECISION REQUIRED: Which services are host-installed, containerised with published ports, or internal-only.
- DECISION REQUIRED: Database technology and exposure model.
- DECISION REQUIRED: Whether DVWA is included.
- DECISION REQUIRED: Level of integration with `cwscenario.uk`.
