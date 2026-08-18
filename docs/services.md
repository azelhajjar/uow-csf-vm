# Service Catalogue

## Purpose

This document defines the service catalogue for the CAV-CSF vulnerable teaching VM.

The VM must expose enough real host-visible services for reconnaissance, enumeration, vulnerability identification, exploitation and reporting. Services are included because they support teaching, not simply to increase the number of open ports.

The canonical delivery, vulnerability-selection and runtime-realism rules are defined in `docs/runtime-and-delivery-model.md`.

## Service Selection Principles

For each exposed service, prefer a genuine CVE-based teaching opportunity where a reliable, reproducible and maintainable option exists. Misconfiguration remains important, but should not automatically replace a suitable real CVE.

A service may deliberately combine:

- a vulnerable software version associated with a genuine CVE;
- weak credentials or credential reuse;
- unsafe permissions;
- excessive service privileges;
- insecure protocol or share configuration.

This combination is desirable where it creates a realistic scenario and multiple teaching opportunities.

Where a suitable CVE has a reliable Metasploit module, document that explicitly so the service can support `msfconsole` exploitation activities.

## Runtime Visibility

The VM must present a meaningful host-visible attack surface. Containerisation must not hide services that students are expected to discover through Nmap or protocol-specific enumeration.

Use a deliberate mixture of:

- services installed directly on the Ubuntu host;
- containerised applications with ports published on the VM network interface;
- selected supporting services, including at least one database, exposed to the VM network;
- internal-only services used only where hidden placement has a deliberate advanced-discovery or post-exploitation purpose.

Do not expose repository or attack-path naming in runtime service names or locations. Internal labels such as `AP01` and `AP02` are documentation identifiers only.

## Service Catalogue

| Service | Deployment | Visibility | Teaching Purpose | Intended Weakness or Role |
| --- | --- | --- | --- | --- |
| HTTP landing site | Host or reverse proxy | External | First contact, scenario context, content discovery, virtual-host discovery | Public pages, robots/sitemap/content discovery and realistic clues |
| Administrative SSH | Host, separate management access | Restricted | VM administration and instructor maintenance | No deliberate student weakness |
| Teaching SSH | Host or isolated instance on TCP 22 | External | SSH enumeration, credential testing and host shell access | Weak/reused teaching credentials or a selected service vulnerability where appropriate |
| SMB | Host or justified isolated build | External | SMB enumeration, shares, authentication, file discovery, exploitation | Prefer a suitable CVE where practical; may also include guest/weak share configuration |
| NFS | Host | External | NFS enumeration, file access and permission analysis | Weak export/permission model and, where suitable, a CVE-backed component |
| FTP | Host or justified isolated build | External | FTP enumeration, authentication testing, file transfer and service exploitation | Prefer a genuine CVE-based service where reliable; misconfiguration may be combined with it |
| Database | Host or published container | External | Service/version enumeration, authentication, data extraction and application linkage | Weak/reused credentials and/or a suitable vulnerable component |
| Internal lab DNS | Host | Lab network | Hostname, record and virtual-host discovery | Scenario records and realistic discovery clues |
| Juice Shop | Container | External | Established modern web exploitation | Built-in vulnerable application |
| WebGoat | Container | External | Guided web exploitation | Built-in vulnerable application |
| Security Shepherd | Container | External | OWASP-aligned web practice | Built-in vulnerable application |
| Custom web application | Container or host | External | Project-owned web, API and CTF exercises | Curated custom vulnerability set |
| SMTP | Host or container | External if approved | Banner, user and protocol enumeration | Suitable CVE and/or controlled configuration weakness |
| SNMP | Host | External if approved | Enumeration and information disclosure | Default/weak community or other controlled weakness |
| Custom TCP service | Host | External if approved | Protocol analysis and custom exploitation | Custom vulnerable protocol behaviour |

## Administrative and Teaching SSH

Administrative SSH exists only for development/instructor maintenance and must remain distinct from the student-facing teaching surface.

If TCP 22 is required for the teaching SSH service, administrative SSH should move to a separate management port before teaching deployment. Administrative access should use key-based authentication and must not accept teaching credentials.

The final student VM is distributed as a complete image. Students do not need an activity-reset interface or resettable teaching SSH service. Build/instructor scripts may restore intended state during development, but that is not part of the student experience.

## HTTP and Web Routing

The VM should provide a plausible fictional organisational landing site at `www.brightleaf.test` unless the scenario name is changed later. It should support reconnaissance without revealing solutions, flags, CVEs or internal attack-path identifiers.

Established vulnerable web applications can be containerised, but their intended web interfaces must be reachable from the VM network.

## Database

At least one database service must be reachable from the VM network and visible during scanning. Students should be able to enumerate the database service and connect database findings to a web application or wider compromise scenario.

Do not hide every database behind Docker-internal networking.

## SMB and NFS

SMB and NFS should support genuine service enumeration and file/permission analysis. Where a reliable CVE-based implementation is available and appropriate, prefer that over a configuration-only exercise. Misconfiguration can still be combined with the vulnerable version where it improves the scenario.

Runtime paths and share names must be realistic. Do not use names derived from `cav-csf`, `APxx`, challenge numbers or module names.

## FTP

FTP should support more than anonymous access where practical. A genuine vulnerable FTP implementation with a reliable teaching path should be preferred when it can be integrated safely and reproducibly. Misconfiguration such as anonymous access may be retained as a separate or combined learning opportunity.

A suitable Metasploit-exploitable CVE is particularly valuable because it supports the full workflow of service discovery, version identification, vulnerability research and exploitation through `msfconsole`.

## Internal Lab DNS

Internal DNS should support lab-local discovery of hostnames, subdomains and virtual hosts. It should expose plausible organisational names, not teaching identifiers.

The public `cwscenario.uk` host remains contextual/OSINT material and must not be required for the vulnerable VM to function.

## CVE Documentation Requirement

For each service deliberately pinned to a vulnerable version, document:

- exact service/version;
- port;
- CVE;
- discovery method;
- available Metasploit module where applicable;
- prerequisites;
- expected exploitation outcome;
- intended module/level;
- installation location;
- instructor verification procedure.

If a custom installation path is required for an old vulnerable build, use a plausible operational name such as `/opt/samba-legacy/` rather than `/opt/cav-csf/ap03/samba/`.

## Verification Requirements

Each approved service needs verification for:

- installed/enabled state;
- listening address and TCP/UDP port;
- expected banner/version;
- intended access controls;
- intended CVE and/or configuration weakness;
- expected exploitation preconditions;
- absence of unintended administrative exposure;
- absence of teaching metadata in student-visible runtime artefacts.

Verification is an instructor/development concern. It does not require student-facing reset functionality.
