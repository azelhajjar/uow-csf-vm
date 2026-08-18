# AP-01 Instructor Guide

## Purpose

AP-01 is an internal identifier for a verified teaching route linking network enumeration, anonymous FTP, credential exposure/reuse, SSH initial access, sudo enumeration and Linux privilege escalation.

This guide contains solution information and must not be issued as the student brief.

The canonical delivery and runtime rules are defined in `docs/runtime-and-delivery-model.md`.

## Important Runtime-Naming Rule

`AP-01` is a repository/instructor label only. It must not appear in the final VM as a service name, directory, hostname, share, process or other student-visible runtime artefact.

Likewise, development names such as `cav-csf-linux` or `cav-csf-teaching-ssh.service` should not be treated as final student-facing runtime names. Before release, use plausible organisational/operational names consistent with the Brightleaf scenario and normal Linux conventions.

## Implemented Route

```text
Anonymous FTP on TCP 21
  -> Brightleaf operational handover/support document
  -> low-privilege stockroom credentials
  -> teaching SSH on TCP 22
  -> NOPASSWD /usr/bin/find
  -> effective UID 0
```

Administrative SSH remains separate from the teaching surface and must not accept teaching credentials.

## Teaching Purpose

AP-01 is deliberately a configuration/credential path rather than a CVE path. It is retained because it teaches important weaknesses:

- anonymous service exposure;
- sensitive information disclosure;
- credential reuse;
- remote access with recovered credentials;
- sudo enumeration;
- unsafe delegated command execution.

This does not establish a project-wide preference for misconfiguration. Future service-exploitation activities should prefer genuine CVEs where practical, as defined in `docs/vulnerabilities.md`.

## Student Starting Information

Provide only what is appropriate for the module, typically:

- the authorised target VM address or subnet;
- the relevant student brief;
- evidence/reporting requirements;
- rules of engagement.

Do not provide the recovered password or exact clue location unless additional scaffolding is deliberately required.

## Expected Observations

1. TCP 21 exposes an FTP service with anonymous read access.
2. A plausible operational document exposes a low-privilege credential.
3. The credential authenticates to student-facing SSH on TCP 22.
4. `id` confirms a non-administrative local account.
5. `sudo -l` exposes the intended unsafe `/usr/bin/find` delegation.
6. The learner demonstrates effective UID 0 and records evidence.

## Instructor Verification

Instructor/development verification should confirm:

- FTP is listening;
- anonymous access works as intended;
- the clue is present and consistent with protected credential state;
- the teaching credential authenticates to the intended SSH service;
- it does not authenticate to administrative SSH;
- the teaching account lacks unintended administrative group membership;
- the intended sudo rule exists and is syntactically valid;
- the approved privilege-escalation route works;
- no teaching/repository identifier leaks into final runtime names after release migration.

Verification is a development/instructor concern and must not expose active credentials in output.

## Recovery During Development

Any existing `reset-ap01.sh` or similar script is an instructor/development recovery utility only. It must not be documented or presented as a student activity-reset feature.

Students start from a fresh copy of the completed VM. If a student VM is damaged, the normal recovery approach is to replace it with a fresh copy.

During active development, use temporary VMware snapshots for short-term rollback. Use full clones for permanent phase milestones.

## Release Check

Before the final VM is distributed:

- ensure no AP-01-labelled runtime artefacts are visible;
- ensure the hostname and service names are realistic rather than repository-derived;
- verify the complete route from a Kali attacker system;
- verify administrative access remains separate;
- preserve the internal mapping only in instructor documentation.

## Marking Guidance

Evidence should demonstrate reasoning rather than only a root shell. Relevant areas include:

- accurate reconnaissance;
- explanation of anonymous FTP exposure;
- handling of recovered credentials;
- proof of SSH access;
- local and sudo enumeration;
- controlled privilege escalation;
- risk explanation and remediation;
- professional evidence handling and password redaction.
