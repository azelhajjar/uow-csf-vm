# CAV-CSF

CAV-CSF is an intentionally vulnerable Linux teaching environment under active development. The current implementation provides the base tooling only; vulnerable applications and services are not yet available.

## Supported platform

- Ubuntu Server 26.04 LTS
- amd64 architecture
- Minimal server installation
- VMware Workstation as the primary virtualisation platform

## Base installation

Clone the repository on the Ubuntu VM, enter the repository directory, and run:

```bash
sudo ./scripts/install-base.sh
```

The installer checks the operating-system version and installs Git, Python, Docker Engine, and Docker Compose. A user added to the `docker` group must log out and back in before the new group membership applies.

## Status and verification

Display operating-system, network, tool, service, port, and repository status:

```bash
./scripts/status.sh
```

Verify the supported OS, base commands, Docker daemon, Docker Compose, and systemd health:

```bash
./scripts/verify.sh
```

A successful verification ends with `RESULT: PASS`.

## Current limitations

- No vulnerable applications or deliberate weaknesses are implemented yet.
- Reset and recovery scripts will be added as services are implemented.
- Ubuntu VM integration and instructor acceptance testing are still required.
