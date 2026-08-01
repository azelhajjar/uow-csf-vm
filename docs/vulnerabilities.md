# Vulnerability Catalogue

## Purpose

This document proposes vulnerability categories for the CAV-CSF VM. Phase 1 records planned weaknesses only. Implementation begins only after approval.

## Design Principles

- Weaknesses must be intentional.
- Each weakness must map to a teaching purpose.
- Each weakness must be independently testable.
- Weaknesses should support both standalone exercises and optional chaining.
- Not every weakness should be part of one mandatory attack path.
- Introductory activities must not require advanced exploitation.
- Avoid relying primarily on obsolete operating-system packages.

## Proposed Vulnerability Areas

### Web Application Vulnerabilities

Proposed custom application categories:

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

The initial custom application should include approximately 10 to 12 well-tested vulnerabilities. The final selection must be agreed before implementation.

### Network Service Weaknesses

Candidate weaknesses:

- anonymous access;
- weak credentials;
- default credentials;
- readable shares;
- writable shares;
- information leakage;
- plaintext authentication;
- credential reuse;
- exposed backup files;
- excessive service privileges;
- insecure service configuration;
- custom vulnerable protocol handling.

### Web Server and Platform Misconfiguration

Legacy-inspired candidates:

- directory listing;
- public server-status;
- verbose version and module disclosure;
- permissive `.htaccess` or override behaviour;
- unsafe upload directories;
- PHP error disclosure;
- weak security headers;
- weak TLS settings where useful for teaching.

These must be scoped carefully rather than applied as broad global misconfiguration.

### Database Weaknesses

Candidates:

- externally visible database service;
- weak or reused database credentials;
- test data linked to web application findings;
- excessive database privileges;
- information useful for later host or AD activity.

### Linux Privilege Escalation

Covered separately in `docs/linux-privilege-escalation.md`.

### CTF Flags

Covered separately in `docs/ctf.md`.

## Legacy Mapping

Legacy ideas worth adapting:

- SMB guest/writable share;
- NFS weak export;
- FTP anonymous/write-enabled access;
- exposed MariaDB/MySQL;
- Apache/PHP information disclosure;
- user and service-account credential reuse;
- file-based flags;
- status reporting.

Legacy ideas requiring replacement or careful approval:

- old vulnerable service binaries;
- one-shot scripts;
- broad `777` permissions without a reset plan;
- hardcoded PHP/package versions;
- direct use of old flags without a generation/manifest process.

## Verification Requirements

Every implemented vulnerability should have:

- a short instructor description;
- affected service/application;
- intended student activity;
- expected evidence;
- reset requirements;
- verification command or automated test;
- safety note for unintended exposure.

## Open Decisions

- DECISION REQUIRED: Final custom application vulnerability list.
- DECISION REQUIRED: Which network-service weaknesses are included in the first build.
- DECISION REQUIRED: Which legacy web server misconfigurations are retained.
- DECISION REQUIRED: Whether any deliberately obsolete service versions are justified.
- DECISION REQUIRED: Which weaknesses are student-facing labs and which are advanced/CTF-only paths.
