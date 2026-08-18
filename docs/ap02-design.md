# AP-02 Design: ProFTPD mod_copy to Web-Service Access

## Status

AP-02 has been provisioned and live-verified on the reference Ubuntu 26.04 VM. Exploit acceptance testing confirmed the intended ProFTPD 1.3.5 `mod_copy` condition (CVE-2015-3306).

AP-02 is an internal documentation identifier only. It must not define the deployed runtime naming scheme.

The canonical runtime and student-delivery rules are in `docs/runtime-and-delivery-model.md`.

## Teaching Purpose

AP-02 deliberately provides a genuine version-bound CVE rather than another configuration-only path. It supports:

- service discovery and fingerprinting;
- version identification;
- vulnerability research;
- CVE recognition;
- exploit-condition analysis;
- Metasploit/manual exploitation discussion where appropriate;
- interaction between a network service and a web service;
- evidence-based remediation.

This pattern should be repeated elsewhere in the VM where reliable CVE-based exercises are practical.

## Verified Vulnerable Component

- Product: ProFTPD 1.3.5.
- Vulnerability: CVE-2015-3306.
- Module: `mod_copy`.
- Service port: TCP 2121 in the current reference build.
- Exploit precondition: the configured anonymous context gives the daemon an identity capable of writing to the intended web-served location.
- Expected result: unauthenticated file-copy capability into a web-served location.

The source build uses the pinned `proftpd-1.3.5.tar.gz` archive and verifies its SHA-256 before extraction.

## Runtime Naming Requirement

The current reference implementation used development-labelled runtime artefacts such as:

- `/opt/cav-csf/ap02/proftpd`;
- `/var/www/brightleaf-ap02`;
- `cav-csf-ap02-proftpd.service`;
- AP-02-specific configuration paths.

These names are **not acceptable for the final VM** because they expose repository and attack-path metadata to students.

Before release, migrate the runtime artefacts to plausible operational names. For example:

- source-built ProFTPD: `/opt/document-transfer/` or another scenario-appropriate operational path;
- web root: `/var/www/warehouse/`;
- systemd unit: `document-transfer.service` or another plausible service name;
- configuration: `/etc/proftpd/warehouse.conf` or another conventional/realistic location.

The exact names should fit the Brightleaf scenario and normal Linux conventions. Do not use `cav-csf`, `ap02`, `attack-path`, `challenge` or teaching-level identifiers in student-visible runtime artefacts.

Internal repository files may continue to use AP-02 as a developer/instructor identifier.

## Current Vulnerable Condition

ProFTPD 1.3.5 is compiled with `mod_copy`. An anonymous context is configured so that the vulnerable file-copy operation can affect the dedicated web-served boundary.

Live testing established an important implementation detail: named logins run as their own account and cannot write to the web boundary, whereas the anonymous context runs using the intended web-service identity. This is why the anonymous context is part of the verified condition.

The design does not require broad world-writable permissions on unrelated system directories.

## Provisioning Requirement

The installer must:

- require the approved Ubuntu version and root privileges;
- refuse to overwrite unrelated listeners;
- install only required build/runtime dependencies;
- verify the pinned source checksum;
- compile the vulnerable ProFTPD version into the approved realistic runtime location;
- install a realistically named service/configuration;
- configure the intended anonymous context;
- create the dedicated web-served location;
- preserve unrelated teaching and administrative services;
- run non-exploit verification after installation.

Provisioning scripts may retain internal names such as `install-ap02.sh` inside the repository. Those names are not visible to students because the repository is not part of the final student VM experience.

## Instructor Verification

Verification should confirm:

- exact ProFTPD version;
- presence of `mod_copy`;
- configuration parse success;
- expected listening port;
- service active/enabled state;
- expected web service response;
- intended ownership/permissions;
- coexistence with other approved services;
- absence of teaching/repository identifiers in deployed paths and unit names after runtime-name migration.

Exploit acceptance remains a separate instructor-controlled activity rather than part of a health checker.

## Developer Recovery

Any existing `reset-ap02.sh` or equivalent script is an **instructor/development recovery utility only**. It must not be presented as something students use between activities.

Students receive a fresh completed VM image. If a student instance becomes unusable, the normal recovery method is to replace it with a fresh VM copy.

During development, use snapshots for short-term rollback within the current phase and full clones for permanent milestone recovery as defined in `docs/runtime-and-delivery-model.md`.

## Release Requirement

Before `CAV-CSF-Release` is produced:

1. remove/migrate all AP-02-labelled runtime paths and service names;
2. verify that the CVE remains exploitable after the rename/migration;
3. verify that normal reconnaissance reveals realistic service/version information without exposing internal teaching identifiers;
4. record the final runtime mapping in instructor documentation only.
