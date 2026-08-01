# Service Catalogue

## Purpose

This document proposes the service set for CAV-CSF. No service should be installed until its teaching purpose, weakness, expected outcome, reset behaviour and verification method are approved.

## Proposed Services

| Service | Deployment | Visibility | Teaching Purpose | Proposed Weakness | Status |
| --- | --- | --- | --- | --- | --- |
| HTTP | Host and containers | External | Web discovery, landing page, application access | Directory/content discovery and selected information disclosure | DECISION REQUIRED |
| HTTPS | Host or reverse proxy | External | TLS inspection and web access | Weak/misconfigured TLS only if pedagogically useful | DECISION REQUIRED |
| SSH | Host | External | Remote access testing and post-exploitation | Selected weak/reused credentials or AD-authenticated access later | DECISION REQUIRED |
| FTP | Host or container | External | FTP enumeration, anonymous access, upload testing | Anonymous or weak local-user configuration | DECISION REQUIRED |
| SMB | Host | External | SMB enumeration and share analysis | Guest/readable/writable shares, information leakage | DECISION REQUIRED |
| NFS | Host | External | NFS enumeration and Linux file-access weakness | Weak export permissions or `no_root_squash` style route | DECISION REQUIRED |
| DNS | Host | External on lab network | Hostname, subdomain and virtual-host discovery | Informative records and scenario clues | DECISION REQUIRED |
| SMTP | Host or container | External or internal | Banner grabbing, email/user discovery | Open information leakage, not necessarily open relay | DECISION REQUIRED |
| SNMP | Host | External | SNMP enumeration and information disclosure | Weak community string and readable system details | DECISION REQUIRED |
| Database | Host or published container | External | Version enumeration, credential testing, data extraction | Weak/reused credentials and mapped application data | DECISION REQUIRED |
| Custom TCP service | Host or container | External | Protocol analysis and custom service exploitation | Simple deliberate protocol flaw | DECISION REQUIRED |
| Juice Shop | Container | External via port or hostname | Established web exploitation | Application-provided vulnerabilities | Proposed |
| WebGoat | Container | External via port or hostname | Guided web exploitation | Application-provided vulnerabilities | Proposed |
| Security Shepherd | Container | External via port or hostname | OWASP-aligned practice | Application-provided vulnerabilities | Proposed |
| DVWA | Container or host | External if approved | Introductory web exploitation | Application-provided vulnerabilities | DECISION REQUIRED |

## Lessons From Legacy

Legacy provides candidate service ideas for SSH, Samba, NFS, FTP, Apache, MariaDB/MySQL and Docker-hosted web applications. These ideas should be redesigned rather than copied.

Useful legacy service ideas:

- guest-writable SMB share;
- weak NFS export;
- anonymous/write-enabled FTP;
- exposed database;
- web server information disclosure;
- named virtual hosts for established vulnerable applications;
- status script reporting running services and listening ports.

Legacy concerns:

- broad installation before approval;
- obsolete vulnerable binaries;
- hardcoded network ranges;
- inconsistent configuration files;
- service names and paths tied to the old attempt;
- no formal service-to-learning-outcome mapping.

## Port Exposure Principles

- Ports must be exposed because they support teaching, not merely because a container provides them.
- At least one database service must be reachable from the VM network.
- Established vulnerable web apps may remain containerised if their intended interfaces are reachable.
- Internal-only services may exist for advanced discovery or post-exploitation, but they must be documented.

## Verification Requirements

Each approved service needs checks for:

- installed/enabled state;
- listening address and TCP/UDP port;
- expected banner or response;
- intended access controls;
- intended vulnerability or misconfiguration;
- reset behaviour;
- absence of unintended administrative exposure.

## Open Decisions

- DECISION REQUIRED: Final list of enabled services for first implementation.
- DECISION REQUIRED: Port and hostname plan.
- DECISION REQUIRED: Which database service is externally visible.
- DECISION REQUIRED: Whether FTP should include an old vulnerable service or only modern misconfiguration.
- DECISION REQUIRED: Whether SMTP is included in the first build.
- DECISION REQUIRED: Whether SNMP is included in the first build.
- DECISION REQUIRED: Whether DVWA is included.
