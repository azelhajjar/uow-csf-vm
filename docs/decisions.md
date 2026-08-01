# Decisions

## Purpose

This file records decisions required before implementation begins. Items marked `DECISION REQUIRED` must be approved before the relevant component is implemented.

## Phase 1 Decisions

### Platform and Naming

- DECISION REQUIRED: Final fictional organisation name and naming scheme.
- DECISION REQUIRED: Whether VM hostnames, service names and internal paths should avoid the temporary repository name `cav-csf`.
- DECISION REQUIRED: Level of integration with `cwscenario.uk`.

### Service Catalogue

- DECISION REQUIRED: Final list of enabled services for the first implementation.
- DECISION REQUIRED: Port and hostname plan.
- DECISION REQUIRED: Which services are host-installed, containerised with published ports, or internal-only.
- DECISION REQUIRED: Which database service is externally visible.
- DECISION REQUIRED: Whether FTP should use modern misconfiguration, an old vulnerable service, or both.
- DECISION REQUIRED: Whether SMTP is included in the first build.
- DECISION REQUIRED: Whether SNMP is included in the first build.
- DECISION REQUIRED: Whether DVWA is included.

### Web and Custom Application

- DECISION REQUIRED: Technology stack for the custom application.
- DECISION REQUIRED: Final custom application vulnerability list.
- DECISION REQUIRED: Which application findings chain into host, service or AD activities.
- DECISION REQUIRED: Which established web applications are included in the first build.

### Vulnerabilities

- DECISION REQUIRED: Which network-service weaknesses are included in the first build.
- DECISION REQUIRED: Which legacy Apache/PHP misconfigurations are retained.
- DECISION REQUIRED: Whether any deliberately obsolete service versions are justified.
- DECISION REQUIRED: Which weaknesses are introductory, intermediate, advanced or CTF-only paths.

### Module Mapping

- DECISION REQUIRED: Which services are in scope for each module guide.
- DECISION REQUIRED: Which vulnerabilities are introductory, intermediate, advanced or CTF-only.
- DECISION REQUIRED: How much overlap should exist between teaching labs and CTF event routes.
- DECISION REQUIRED: Which activities require AD and which must remain Linux-only.

### Linux Privilege Escalation

- DECISION REQUIRED: Number of privilege-escalation routes in the first build.
- DECISION REQUIRED: Difficulty split across Level 5, Level 6, Level 7 and CTF.
- DECISION REQUIRED: Whether any route should chain from the custom application.
- DECISION REQUIRED: Whether any route should depend on AD integration.

### Active Directory

- DECISION REQUIRED: Domain name and Windows environment details.
- DECISION REQUIRED: Which AD users and groups should map to Linux access.
- DECISION REQUIRED: Which Linux service uses an AD service account.
- DECISION REQUIRED: Which cross-platform attack paths are included.
- DECISION REQUIRED: Whether AD integration appears before or after CTF support in the first release.

### CTF

- DECISION REQUIRED: Whether regular labs use fixed flags, generated flags or both.
- DECISION REQUIRED: Final flag prefix.
- DECISION REQUIRED: Initial number of flags.
- DECISION REQUIRED: Which services/applications host the first flags.
- DECISION REQUIRED: Whether AD-linked flags are included in the first release.
- DECISION REQUIRED: Manifest file format.

## Approved Decisions

No Phase 1 design decisions have been approved yet.
