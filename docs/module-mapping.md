# Module Mapping

## Purpose

CAV-CSF provides one shared Linux VM. Module differences come from teaching guides, scope, task framing and the amount of guidance provided, not from separate VM editions or profiles.

The canonical runtime and delivery rules are defined in `docs/runtime-and-delivery-model.md`.

Students receive only the completed VM image. They do not receive repository/build tooling and do not need per-activity reset mechanisms.

## Level 5 Network Penetration Testing

Supported activities:

- host discovery;
- TCP and UDP scanning;
- service detection;
- operating-system and version enumeration;
- banner analysis;
- FTP, SMB, NFS, SSH, SNMP and database enumeration where included;
- password testing against selected services;
- identification of known service vulnerabilities;
- exploitation of genuine CVEs where suitable;
- exploitation of selected configuration weaknesses;
- Metasploit use for suitable service CVEs;
- initial access;
- basic post-exploitation;
- Linux privilege escalation;
- evidence collection and remediation analysis.

Suitable VM features:

- externally visible service set;
- realistic banners and hostnames;
- several version-bound vulnerable services;
- CVEs with reliable `msfconsole` modules where pedagogically appropriate;
- selected weak credentials/shares as complementary weaknesses;
- introductory privilege-escalation routes.

## Level 5 Web Application Penetration Testing

Supported activities:

- web-content discovery;
- application fingerprinting;
- request/response analysis;
- authentication and session testing;
- access-control testing;
- injection attacks;
- file-handling attacks;
- API testing;
- client-side/server-side vulnerabilities;
- business-logic testing;
- evidence collection and remediation analysis.

Suitable VM features:

- realistic landing site and virtual hosts;
- established vulnerable applications;
- custom vulnerable application;
- realistic public content/documents;
- database/backend interaction where appropriate.

## Level 6 6COSC019W Cyber Security

Supported activities:

- reconnaissance;
- active information gathering;
- Nmap scanning;
- service enumeration and version fingerprinting;
- vulnerability identification and CVE research;
- web exploitation;
- network-service exploitation;
- Metasploit usage;
- manual exploitation where appropriate;
- packet capture/protocol analysis;
- post-exploitation;
- basic privilege escalation;
- basic lateral-movement concepts;
- threat modelling and security reporting.

The VM must contain genuine CVE-based exploitation opportunities so Metasploit is not reduced to a purely historical or artificial demonstration.

## Level 6 Advanced Penetration Testing

Supported activities:

- limited-guidance enumeration;
- independent vulnerability research;
- CVE and configuration-based exploitation;
- vulnerability chaining;
- credential discovery/reuse;
- Linux privilege escalation;
- pivoting concepts;
- interaction with Windows AD;
- Linux-to-Windows and Windows-to-Linux lateral movement;
- Kerberos and AD-linked credentials;
- combining independently discoverable weaknesses into broader compromise paths.

Suitable VM features:

- multiple independent vulnerabilities;
- genuine service CVEs;
- credential reuse across services;
- service accounts;
- selected internal-only services;
- AD integration.

## Level 7 Scenario-Led Activities

Students may receive only:

- organisational context;
- authorised scope;
- rules of engagement;
- high-level objectives;
- required deliverables.

Suitable VM features:

- believable fictional organisation;
- realistic runtime naming;
- discoverable information;
- non-linear attack opportunities;
- mixture of CVEs and configuration weaknesses;
- enough ambiguity for independent investigation;
- realistic evidence for critical evaluation.

Internal attack-path identifiers must not be exposed in the runtime environment because that would undermine independent discovery.

## CTF Events

The same completed VM/custom application can support CTF events.

Supported flag categories include:

- web flags;
- network-service flags;
- application-user flags;
- Linux-user flags;
- Linux-root flags;
- credential-discovery flags;
- cross-platform flags;
- optional AD-related flags.

CTF differences are challenge framing and flag placement/verification, not a separate VM profile.

## Teaching Guide Principle

Teaching guides determine:

- which parts of the common VM are in scope;
- which techniques are expected;
- how much guidance is provided;
- what evidence students must collect;
- whether cross-platform activity is included.

The VM itself does not enable/disable vulnerabilities by level.
