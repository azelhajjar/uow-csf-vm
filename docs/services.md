# Service Catalogue

## Purpose

This document defines the proposed service catalogue for the first CAV-CSF vulnerable teaching VM design.

The VM should expose enough real host-visible services for network reconnaissance, enumeration, exploitation and reporting. Services should be included because they support teaching, not simply to increase the number of open ports.

No service is implemented in Phase 1.

## First Build Proposal

The first build should include a small but useful set of services that supports Level 5 and Level 6 teaching immediately, while leaving room for Level 7, AD and CTF extensions.

| Service | Deployment | Visibility | Teaching Purpose | Intended Weakness or Role | Initial Status |
| --- | --- | --- | --- | --- | --- |
| HTTP landing site | Host or reverse proxy | External | First contact, scenario context, web discovery, links to public apps | Public pages, robots/sitemap/content discovery, non-solution clues | Proposed |
| Administrative SSH | Host; TCP 22 during the base build, then a separately secured management port | Restricted to the management path where practical | VM administration, maintenance and recovery | No deliberate weakness; key-only authentication and restricted administrator access | Base access implemented; port migration planned |
| Teaching SSH | Separate resettable service, TCP 22 | External | Realistic SSH enumeration, credential testing and controlled low-privilege shell access | Selected weak or reused teaching credentials once the account model is agreed | Proposed |
| SMB | Host | External | SMB enumeration, share review, file discovery | Readable or writable share, public/internal clue material | Proposed |
| NFS | Host | External | NFS enumeration, Linux file access, permissions analysis | Weak export or permission model if approved | Proposed |
| FTP | Host or container | External | FTP enumeration, anonymous/local login testing, file transfer evidence | Modern misconfiguration by default; old vulnerable version only if approved | DECISION REQUIRED |
| Database | Host or published container | External | Service/version enumeration, database login testing, data extraction | Weak/reused credentials and application-linked data | Proposed |
| Internal lab DNS | Host | Lab network | Hostname and virtual-host discovery | Scenario records, subdomain clues and internal service names | Proposed |
| Juice Shop | Container | External via documented port or hostname | Established web exploitation | Built-in vulnerable application | Proposed |
| WebGoat | Container | External via documented port or hostname | Guided web exploitation | Built-in vulnerable application | Proposed |
| Security Shepherd | Container | External via documented port or hostname | OWASP-aligned web practice | Built-in vulnerable application | Proposed |
| Custom web application | Container or host | External | Project-owned web, API, CTF and scenario exercises | Agreed custom vulnerability set | Proposed |

## Optional or Deferred Services

These services remain useful candidates, but should not be included automatically in the first build unless approved.

| Service | Reason to Include | Reason to Defer | Status |
| --- | --- | --- | --- |
| HTTPS | TLS inspection, certificate review, weak configuration discussion | HTTP already supports early web work; TLS needs a clear teaching reason | DECISION REQUIRED |
| SMTP | Banner grabbing, user discovery, mail artefacts | Needs careful scope to avoid unnecessary mail-server complexity | DECISION REQUIRED |
| SNMP | Classic enumeration and information disclosure | Useful, but can be added after core services are stable | DECISION REQUIRED |
| Custom TCP service | Protocol analysis and custom exploitation | Better designed after custom application and module mapping are clearer | DECISION REQUIRED |
| DVWA | Introductory web exploitation | May duplicate Juice Shop/WebGoat/custom-app learning outcomes | DECISION REQUIRED |

## Service Design Notes

### Administrative and Teaching SSH

Host SSH is administrative infrastructure, not a student vulnerability. It remains on TCP 22 for the clean base snapshot, then moves to a separately secured management port before the separate teaching SSH service claims TCP 22. The administrative service must not use teaching credentials or deliberate weaknesses. Migration must be tested through a second SSH session before the existing connection is closed. Verification must test both that the teaching weakness is present and that unintended administrative SSH access has not been introduced.

### HTTP and Web Routing

The VM should provide a simple landing site. It should support reconnaissance and navigation without revealing solutions, vulnerabilities, flags, hidden services or instructor notes.

Established web applications can be containerised, but their web interfaces must be reachable from the VM network through documented ports or hostnames.

### Database

At least one database service must be reachable from the VM network. This is a core README requirement because students should be able to discover, enumerate and test a database service directly.

The database should be linked to the custom application or scenario data so that database access has teaching value beyond simply opening another port.

### SMB and NFS

SMB and NFS should support file-share enumeration, permissions analysis and clue discovery. Weak access should be intentional, documented and resettable.

### FTP

FTP is useful for enumeration, anonymous access, weak local-user access and file-transfer evidence. The default proposal is a maintainable modern misconfiguration. A deliberately old vulnerable FTP service should only be used if the exploit lesson is worth the maintenance cost.

### Internal Lab DNS

Internal lab DNS should support lab-local discovery of hostnames, subdomains and virtual hosts. It is part of the vulnerable teaching environment and should provide scenario records, internal service names and discovery clues.

This is separate from builder/instructor resolver switching. A helper such as `switch-dns.sh` may be useful for changing the VM resolver between university and home profiles during setup or support work, but that utility is not the vulnerable lab DNS service students enumerate.

Any public-domain clue path must have an internal equivalent or fallback inside the VM so classroom sessions do not depend on external availability.

## Legacy Idea Use

The abandoned legacy attempt suggests possible service ideas: SMB, NFS, FTP, Apache/web, MariaDB/MySQL, Docker-hosted web applications and status reporting.

These are only idea sources. The new service catalogue should not copy the old scripts or assume the old implementation is correct.

## Verification Requirements

Each approved service needs a verification check for:

- installed/enabled state;
- listening address and TCP/UDP port;
- expected banner or response;
- intended access controls;
- intended vulnerability or misconfiguration;
- reset behaviour;
- absence of unintended administrative exposure.

## Decisions Required Before Implementation

- DECISION REQUIRED: Approve the first-build service set.
- DECISION REQUIRED: Choose the externally visible database technology.
- DECISION REQUIRED: Decide whether FTP is included in the first build.
- DECISION REQUIRED: If FTP is included, decide modern misconfiguration versus old vulnerable service.
- DECISION REQUIRED: Decide whether HTTPS, SMTP, SNMP, custom TCP service or DVWA are included in the first build.
- DECISION REQUIRED: Approve the first port and hostname plan.
