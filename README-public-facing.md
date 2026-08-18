# CAV-CSF

CAV-CSF is an intentionally vulnerable Linux teaching environment under active development.

## Supported platform

- Ubuntu Server 26.04 LTS
- amd64 architecture
- Minimal server installation
- VMware Workstation as the primary virtualisation platform

## Development installation

The repository contains the source-controlled build and provisioning material used to create the teaching VM.

On the Ubuntu development VM, clone the repository, enter the repository directory, and run the relevant approved provisioning scripts for the current development phase.

The repository is development/instructor material. Students will receive the completed VM image rather than the repository or provisioning source.

## Status and verification

Development/instructor verification tooling is used to confirm the intended VM state as components are implemented.

Current base commands include:

```bash
./scripts/status.sh
./scripts/verify.sh
```

A successful verification reports the expected environment state and any component-specific PASS/FAIL results.

## Student delivery model

The final teaching release will be distributed as a completed VM image. Each student starts from a fresh copy of that image.

Student-facing per-activity reset scripts, reset buttons or challenge-reset workflows are not part of the design. If a student copy becomes unusable, it can be replaced with a fresh VM image.

## Current development status

The environment is under active construction. Public documentation will be expanded as services, vulnerable applications, CVE-based activities, network services, privilege-escalation routes and the later Active Directory integration are finalised and accepted.

Implementation details, instructor solutions, credentials, flags and internal attack-path mappings are intentionally excluded from this public-facing document.
