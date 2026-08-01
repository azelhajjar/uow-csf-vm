# Module Mapping

## Purpose

CAV-CSF will provide one shared VM. Module differences come from teaching guides, scope, task framing and the amount of guidance provided, not from separate VM editions.

## Level 5 Network Penetration Testing

Supported activities:

- host discovery;
- TCP and UDP scanning;
- service detection;
- operating-system and version enumeration;
- banner analysis;
- FTP, SMB, NFS, SSH, SNMP and database enumeration where approved;
- password testing against selected services;
- exploitation of simple service misconfiguration;
- initial access;
- basic post-exploitation;
- Linux privilege escalation;
- evidence collection and remediation analysis.

Suitable VM features:

- externally visible service set;
- realistic banners and hostnames;
- weak credentials for selected services;
- readable or writable shares;
- simple privilege-escalation route.

## Level 5 Web Application Penetration Testing

Supported activities:

- web-content discovery;
- application fingerprinting;
- request and response analysis;
- authentication testing;
- session testing;
- access-control testing;
- injection attacks;
- file-handling attacks;
- API testing;
- client-side and server-side vulnerabilities;
- business-logic testing;
- evidence collection and remediation analysis.

Suitable VM features:

- landing page;
- established vulnerable applications;
- custom vulnerable application;
- realistic public content and documents;
- clear hostnames and ports.

## Level 6 6COSC019W Cyber Security

Supported activities:

- reconnaissance;
- active information gathering;
- Nmap scanning;
- service enumeration;
- vulnerability identification;
- web exploitation;
- network-service exploitation;
- Metasploit usage where appropriate;
- packet capture and protocol analysis;
- post-exploitation;
- basic privilege escalation;
- basic lateral-movement concepts;
- threat modelling and security reporting.

Suitable VM features:

- richer reconnaissance surface;
- selected exploitable services;
- traffic observable in the lab network;
- web and host paths that can be linked in reports.

## Level 6 Advanced Penetration Testing

Supported activities:

- limited-guidance enumeration;
- exploitation without procedural walkthroughs;
- vulnerability chaining;
- credential discovery and password reuse;
- Linux privilege escalation;
- pivoting concepts;
- interaction with Windows AD;
- Linux-to-Windows and Windows-to-Linux lateral movement;
- Kerberos and AD-linked credentials.

Suitable VM features:

- multiple independent weaknesses;
- credential reuse across services;
- service accounts;
- hidden or internal-only services;
- AD integration once approved.

## Level 7 Scenario-Led Activities

Students may receive:

- organisational context;
- authorised scope;
- rules of engagement;
- high-level objectives;
- required deliverables.

Suitable VM features:

- believable fictional organisation;
- discoverable information;
- non-linear attack paths;
- enough ambiguity for independent investigation;
- realistic evidence for critical evaluation.

## CTF Events

Supported flag categories:

- web flags;
- network-service flags;
- application-user flags;
- Linux-user flags;
- Linux-root flags;
- credential-discovery flags;
- cross-platform flags;
- optional AD-related flags.

Suitable VM features:

- configurable flag prefix;
- flag generation;
- instructor manifest;
- verification script;
- replacement process before events.

## Open Decisions

- DECISION REQUIRED: Which services are in scope for each module guide.
- DECISION REQUIRED: Which vulnerabilities are introductory, intermediate, advanced or CTF-only.
- DECISION REQUIRED: How much overlap should exist between teaching labs and CTF event routes.
- DECISION REQUIRED: Which activities require AD and which must remain Linux-only.
