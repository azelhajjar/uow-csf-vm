# CTF Plan

## Purpose

CAV-CSF should support internally developed University capture-the-flag events using the same completed VM and custom application used for teaching.

The project should not create a separate CTF VM profile or a full public CTF management platform unless explicitly requested.

The canonical runtime and student-delivery rules are defined in `docs/runtime-and-delivery-model.md`.

## Same Environment

CTF use does not require a separate technical build. The same applications, services and vulnerabilities remain present. The CTF event changes the challenge brief, scoring/flag expectations and amount of guidance, not the underlying VM architecture.

## Flag Format

Initial format:

```text
UOWCTF{example_value}
```

The prefix may be changed later.

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

Runtime paths and object names should remain realistic. Do not name directories, services, shares or database objects after challenge IDs simply to identify a flag location.

## Required Components

For development/instructor use:

- flag-generation or replacement tooling where useful;
- instructor-only flag manifest;
- flag verification tooling;
- documentation showing the intended route to each flag;
- a practical method for preparing event-specific flag values before distributing the event VM image.

These are instructor/build artefacts. They are not student-facing reset or management features.

## Event Preparation

The expected event model is:

1. prepare the completed VM;
2. place or replace the required event flags;
3. verify the flags and intended routes;
4. create/freeze the event VM image;
5. distribute a fresh copy to each participant/team.

Students do not need a button or script to reset individual challenges. If an event VM is damaged, replace it with a fresh event image.

## Proposed Flag Categories

- web flag;
- network-service flag;
- application-user flag;
- Linux-user flag;
- Linux-root flag;
- credential-discovery flag;
- cross-platform flag;
- optional AD-related flag.

## Verification

Instructor verification should confirm:

- each expected flag exists;
- each flag matches the event/instructor manifest;
- permissions/access conditions match the intended route;
- no unintended flag exposure is present;
- runtime names do not expose internal challenge/attack-path metadata.

Verification is not a student reset mechanism.

## Open Decisions

- DECISION REQUIRED: Final flag prefix for the first event.
- DECISION REQUIRED: Initial number of flags.
- DECISION REQUIRED: Which services/applications host the first flags.
- DECISION REQUIRED: Whether AD-linked flags are included in the first event/release.
- DECISION REQUIRED: Instructor manifest format.
