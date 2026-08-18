# AP-02 Instructor Guide

## Purpose

AP-02 is an internal identifier for the verified ProFTPD 1.3.5 `mod_copy` exercise using CVE-2015-3306. It provides a genuine version-bound service vulnerability and should serve as a model for future CVE-based network exploitation activities.

This guide contains solution information and must not be issued as the student brief.

The canonical delivery and runtime rules are defined in `docs/runtime-and-delivery-model.md`.

## Runtime-Naming Requirement

`AP-02` is a repository/instructor label only. It must not appear in the final VM as a service name, directory, hostname, web root, process or other student-visible runtime artefact.

The current reference implementation contains development-labelled names such as `/opt/cav-csf/ap02/...`, `/var/www/brightleaf-ap02`, `cav-csf-ap02-proftpd.service` and AP-02-specific configuration paths. These must be migrated to plausible operational names before release while preserving the verified vulnerable condition.

See `docs/ap02-design.md` for the migration requirement.

## Implemented Route

```text
ProFTPD 1.3.5 discovered on TCP 2121
  -> version/CVE research identifies CVE-2015-3306
  -> anonymous session satisfies the intended mod_copy condition
  -> SITE CPFR / SITE CPTO copies a file into a web-served location
  -> HTTP access demonstrates the impact
```

## Why This Path Matters

This is the type of activity the project should deliberately retain and expand:

1. students scan the target;
2. identify the service and version;
3. research or recognise a genuine CVE;
4. identify the exploit prerequisites;
5. exploit the service manually or through an appropriate framework;
6. demonstrate a meaningful result;
7. explain remediation.

Where suitable, future CVEs should also support reliable Metasploit modules so `msfconsole` remains part of the curriculum.

## Student Starting Information

Provide only what is appropriate for the module:

- target VM address or subnet;
- assessment/evidence requirements;
- rules of engagement;
- the student brief if guided delivery is intended.

Do not provide the vulnerable version, CVE or exploit command in advance unless the learning level requires that scaffolding.

## Verified Condition

The validated condition is:

- ProFTPD 1.3.5;
- `mod_copy` compiled in;
- anonymous access configured so the vulnerable file operation uses the intended service identity;
- a bounded web-served destination owned by the service identity;
- Apache/PHP serving the destination.

Live acceptance testing confirmed that a named login does not have the same write capability to the web boundary, while the anonymous context does. This implementation detail is part of the instructor solution.

## Instructor Verification

Verification should confirm:

- exact ProFTPD version;
- `mod_copy` presence;
- configuration parse success;
- intended port listening;
- web service response;
- intended ownership/permission boundary;
- coexistence with approved services;
- final runtime names do not expose `cav-csf`, `AP-02`, challenge numbers or repository structure.

Exploit acceptance testing remains a separate instructor-controlled activity. Health verification does not need to execute the exploit every time.

## Development Recovery

Any existing `reset-ap02.sh` or similar script is an instructor/development recovery utility only.

It is **not** a student-facing reset process and should not appear in student instructions.

Students receive a fresh completed VM image. If a student VM is damaged, the normal recovery method is to replace it with a fresh copy.

During development:

- snapshots are temporary rollback points within the active phase;
- full clones are permanent milestone backups;
- Git provides source/configuration history.

## Troubleshooting Notes

### Anonymous login is refused

Check that the intended anonymous context exists in the final realistically named ProFTPD configuration and that the service identity and web-served path match the approved design.

### `SITE CPTO` returns `550 Permission denied`

Confirm whether the session is anonymous and therefore using the intended service identity. A named login running as its own account is expected to fail against the protected web boundary.

### Copied file does not appear over HTTP

Confirm the correct virtual host/Host header, web-service state, final web-root location and ownership.

### Recovery is uncertain

Use the current phase snapshot for short-term rollback. If the phase is no longer trustworthy, return to the previous permanent full-clone milestone.

## Marking Guidance

Evidence should demonstrate the reasoning chain, not just final file placement. Relevant areas include:

- accurate service fingerprinting and version identification;
- correct CVE identification;
- understanding of exploitation prerequisites;
- non-destructive proof of impact;
- explanation of the permission/identity boundary;
- realistic follow-on impact;
- remediation quality.

Stronger work should distinguish clearly between a genuine software vulnerability and a configuration weakness, and explain how both can interact in a real compromise.
