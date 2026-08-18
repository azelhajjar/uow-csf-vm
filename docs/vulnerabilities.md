# Vulnerability Catalogue

## Purpose

This document defines the vulnerability-selection model for the CAV-CSF VM. The VM must contain a balanced mixture of genuine exploitable CVEs, vulnerable applications, web/API weaknesses, credential weaknesses, Linux privilege-escalation opportunities and deliberate misconfigurations.

The canonical runtime and student-delivery rules are defined in `docs/runtime-and-delivery-model.md`.

## Design Principles

- Weaknesses must be intentional and map to a teaching purpose.
- Each weakness must be independently testable.
- Weaknesses should support both standalone exercises and optional chaining.
- Not every weakness should be part of one mandatory attack path.
- Introductory activities must not require advanced exploitation.
- Keep the Ubuntu base operating system modern.
- Do not treat deliberate misconfiguration as the default form of vulnerability.
- Where practical, include genuine CVE-based exploitation that requires students to enumerate a service/version, identify the vulnerability and exploit it.

## Vulnerability Selection Priority

Use this priority when choosing vulnerabilities:

1. **Genuine CVE with a reliable teaching path.** Prefer a real vulnerable service/application version with reproducible exploitation. Where appropriate, prefer CVEs with reliable Metasploit modules so students can exploit them through `msfconsole` after reconnaissance and vulnerability identification.
2. **CVE plus deliberate misconfiguration.** Combining a real CVE with weak credentials, unsafe permissions, excessive privileges or another realistic configuration weakness is encouraged where it creates a stronger exercise.
3. **Standalone misconfiguration.** Use this when no suitable CVE is practical, reliable or pedagogically appropriate, or when the configuration weakness itself is the learning outcome.

Do not replace a suitable CVE-based activity with a simple misconfiguration merely because the latter is easier to implement.

Individual services may deliberately use older vulnerable versions where this is necessary for a controlled CVE-based activity. This does not mean freezing or downgrading the entire Ubuntu operating system.

## CVE-Based Service Requirements

For each proposed CVE-based service or application, record:

- service/application name;
- exact vulnerable version;
- listening port or application location;
- CVE identifier;
- vulnerability type;
- discovery/enumeration method;
- Metasploit module name where one exists and is suitable;
- whether authentication is required;
- exploitation prerequisites;
- expected outcome, such as shell access, code execution, credential exposure, data access or privilege gain;
- intended teaching level/module;
- VM integration and maintenance implications;
- instructor verification procedure.

A CVE must not be selected simply because a Metasploit module exists. It must fit the teaching objectives and wider VM design.

## Proposed Vulnerability Areas

### Web Application Vulnerabilities

Proposed custom application categories include:

- SQL injection;
- command injection;
- reflected XSS;
- stored XSS;
- broken authentication;
- insecure session handling;
- broken access control;
- insecure direct object reference;
- API broken object-level authorisation;
- path traversal;
- insecure file upload;
- sensitive information disclosure;
- server-side request forgery;
- business-logic weakness.

The custom application should contain a curated, well-tested set rather than attempting to reproduce every PortSwigger, Juice Shop or WebGoat exercise.

### Network Service Vulnerabilities

The network service layer should include a mixture of genuine CVEs and configuration weaknesses. Candidate categories include:

- remotely exploitable vulnerable service versions;
- anonymous access;
- weak or default credentials;
- readable or writable shares;
- information leakage;
- plaintext authentication;
- credential reuse;
- exposed backup files;
- excessive service privileges;
- insecure service configuration;
- custom vulnerable protocol handling.

At least several exposed services should be selected specifically to support real CVE exploitation and, where pedagogically appropriate, Metasploit usage.

### Web Server and Platform Misconfiguration

Useful candidates include:

- directory listing;
- public server-status;
- verbose version and module disclosure;
- permissive override behaviour;
- unsafe upload directories;
- PHP error disclosure;
- weak security headers;
- weak TLS settings where useful for teaching.

These should complement, not replace, genuine exploit activities.

### Database Weaknesses

Candidates include:

- externally visible database service;
- weak or reused database credentials;
- test data linked to web application findings;
- excessive database privileges;
- information useful for later host or AD activity;
- a deliberately vulnerable database-related component where a suitable CVE provides clear teaching value.

### Linux Privilege Escalation

Covered separately in `docs/linux-privilege-escalation.md`.

### CTF Flags

Covered separately in `docs/ctf.md`.

## Runtime Realism

Internal identifiers such as `AP01`, `AP02`, challenge IDs or vulnerability IDs belong in repository and instructor documentation. They must not dictate runtime directory names, service names, process names, web paths or other artefacts visible to students.

A student examining the compromised server should see plausible operational names and conventional Linux locations, not labels that reveal the intended attack route. See `docs/runtime-and-delivery-model.md`.

## Legacy Mapping

Legacy ideas worth evaluating include:

- SMB guest/writable share;
- NFS weak export;
- FTP anonymous/write-enabled access;
- exposed MariaDB/MySQL;
- Apache/PHP information disclosure;
- user and service-account credential reuse;
- genuine vulnerable service binaries that still provide reliable, reproducible CVE exercises;
- file-based flags;
- status reporting.

Legacy artefacts are references only. Do not copy them automatically or deploy them under repository/attack-path-labelled runtime directories.

## Verification Requirements

Every implemented vulnerability should have:

- a short instructor description;
- affected service/application and version;
- intended student activity;
- expected evidence/outcome;
- verification command or automated test;
- recovery/build notes for instructors where required;
- a check that teaching metadata has not leaked into the runtime environment.

Verification confirms the vulnerable state. It does not imply that students require per-activity reset scripts. Students normally start from a fresh VM image.
