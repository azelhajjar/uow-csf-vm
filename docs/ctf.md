# CTF Plan

## Purpose

CAV-CSF must support internally developed University capture-the-flag events. The first requirement is flag placement, generation, documentation and verification within the VM and custom application.

The project should not create a full public CTF management platform unless explicitly requested.

## Flag Format

Initial format:

```text
UOWCTF{example_value}
```

The prefix must be configurable.

## Flag Locations

Flags may be placed in:

- web responses;
- database records;
- API output;
- restricted files;
- application configuration;
- user home directories;
- root-only locations;
- service output;
- SMB resources;
- AD-linked artefacts.

Flags should not all be placed in predictable `flag.txt` files.

## Required Components

- Flag-generation script.
- Instructor-only flag manifest.
- Flag verification script.
- Documentation showing the intended route to each flag.
- Method for replacing event flags without rebuilding the entire VM.

## Lab Flags Versus Event Flags

Legacy contains fixed flag material and setup-time flag placement. That is useful as a teaching idea, but the new design needs a clear distinction:

- fixed lab flags may be acceptable for repeatable teaching exercises;
- event flags should be replaceable before a CTF event;
- instructor manifests must record current values and intended routes;
- public/student-facing material must not reveal flag values or direct solutions.

## Proposed Flag Categories

- Web flag.
- Network-service flag.
- Application-user flag.
- Linux-user flag.
- Linux-root flag.
- Credential-discovery flag.
- Cross-platform flag.
- Optional AD-related flag.

## Reset and Verification

The reset process should restore or regenerate flag state as intended.

Verification should confirm:

- each expected flag exists;
- each flag matches the current manifest;
- file permissions match the intended route;
- no unintended flag exposure is present;
- event replacement works without rebuilding the VM.

## Open Decisions

- DECISION REQUIRED: Whether regular labs use fixed flags, generated flags or both.
- DECISION REQUIRED: Final flag prefix.
- DECISION REQUIRED: Initial number of flags.
- DECISION REQUIRED: Which services/applications host the first flags.
- DECISION REQUIRED: Whether AD-linked flags are included in the first release.
- DECISION REQUIRED: Manifest file format.
