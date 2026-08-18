# Attack Paths

## Purpose

This document records internal attack-path design for developers and instructors.

Attack-path identifiers such as `AP-01`, `AP-02` and future `AP-xx` values are **internal documentation labels only**. They must not dictate deployed directory names, systemd units, service names, web roots, users, shares, hostnames, database names or other student-visible runtime artefacts.

The canonical runtime, student-delivery and recovery rules are defined in `docs/runtime-and-delivery-model.md`.

## Student Delivery Model

Students receive only the completed VM image and the relevant teaching guide. They do not receive this attack-path document, the repository or provisioning source.

Each student begins from a fresh VM. There is no requirement for student-facing reset scripts or per-activity restoration features.

Developer/instructor verification and recovery tooling may exist, but it is not part of the student workflow.

## Attack-Path Design Rules

Each attack path should have:

- a clear teaching purpose;
- a realistic starting condition;
- discoverable evidence through normal reconnaissance/enumeration;
- a reproducible exploitation outcome;
- instructor verification;
- realistic runtime naming;
- no dependence on internal teaching identifiers being visible to students.

Do not make every vulnerability part of one mandatory chain. Some activities should remain independently usable for guided Level 5/6 teaching, while advanced and Level 7 teaching can combine weaknesses discovered across the same VM.

## Vulnerability Priority

Where practical, attack paths should include genuine exploitable CVEs rather than relying only on configuration mistakes.

Priority:

1. reliable, teachable CVE, preferably with an appropriate Metasploit module where useful;
2. CVE combined with realistic misconfiguration/credential weaknesses;
3. standalone misconfiguration when no suitable CVE is practical or when the misconfiguration itself is the learning objective.

The Ubuntu base remains modern, while selected services may deliberately run vulnerable versions to support real CVE exploitation.

## AP-01: FTP Clue to Teaching SSH to Root

Status: IMPLEMENTED AND LIVE-VERIFIED on the reference Ubuntu 26.04 VM.

Difficulty: introductory to intermediate.

Learning outcomes:

- enumerate FTP;
- identify anonymous access;
- inspect exposed organisational material;
- recognise credential exposure/reuse;
- authenticate to SSH;
- enumerate sudo privileges;
- exploit an unsafe sudo rule;
- document evidence and remediation.

Internal route summary:

```text
Anonymous FTP
  -> exposed Brightleaf operational clue
  -> low-privilege credentials
  -> SSH host access
  -> unsafe delegated sudo command
  -> effective UID 0
```

AP-01 is intentionally a configuration/credential path. It is retained because those weaknesses are valuable teaching outcomes, not because all future paths should follow the same model.

The student-visible system should use plausible service, user and file names. `AP-01` must not appear as a runtime label.

## AP-02: ProFTPD mod_copy to Web-Service Access

Status: IMPLEMENTED AND LIVE-VERIFIED on the reference Ubuntu 26.04 VM.

AP-02 deliberately introduces a genuine version-bound vulnerability:

- ProFTPD 1.3.5;
- `mod_copy`;
- CVE-2015-3306;
- unauthenticated/anonymous vulnerable condition;
- interaction with a web-served directory.

Internal route summary:

```text
Service discovery and version fingerprinting
  -> identify ProFTPD 1.3.5 / CVE-2015-3306
  -> exploit mod_copy preconditions
  -> arbitrary file placement into web-served location
  -> demonstrate web-service impact
```

This path represents the preferred direction for future network-service work: students should discover the service, identify the version, research/recognise the CVE and exploit a genuine software vulnerability.

See `docs/ap02-design.md` for the runtime-name migration requirement. Current development-labelled paths/units must be replaced with realistic operational names before release.

## Future Network Paths

Future network paths should evaluate CVE-backed services before falling back to configuration-only exercises. Candidate service families include:

- SMB/Samba;
- FTP;
- web servers and middleware;
- databases;
- mail services;
- other services with reliable Metasploit support and clear teaching value.

For each candidate record:

- exact service/version;
- CVE;
- port;
- enumeration/fingerprinting method;
- Metasploit module where appropriate;
- prerequisites;
- expected result;
- runtime integration approach;
- realistic installation/configuration names.

## Future Privilege-Escalation Paths

Privilege escalation may include configuration weaknesses, vulnerable local applications/binaries or selected CVEs where reliable and appropriate.

Candidate categories include:

- unsafe sudo delegation;
- SUID/capabilities misuse;
- writable privileged service or timer;
- exposed credentials;
- vulnerable local/service software;
- AD-linked service-account weaknesses.

## AD and Cross-Platform Paths

Cross-platform paths are intended for advanced Level 6 and Level 7 teaching. Internal design may map Linux-to-AD or AD-to-Linux chains, but student-visible artefacts must still use realistic organisational naming.

## Developer Verification and Recovery

Each implemented path must have instructor verification sufficient to confirm that the intended weakness remains present and exploitable.

This does **not** imply a student reset mechanism.

During development:

- use snapshots as temporary rollback points within the active phase;
- use full clones as permanent completed-phase milestones;
- use Git for source/configuration history.

The planned milestones are:

- `CAV-CSF-00-Clean`
- `CAV-CSF-01-Base`
- `CAV-CSF-02-Web`
- `CAV-CSF-03-Network`
- `CAV-CSF-04-PrivilegeEsc`
- `CAV-CSF-05-AD-Integrated`
- `CAV-CSF-Release`

Student recovery remains a fresh VM copy.
