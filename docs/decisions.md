# Decisions

## Purpose

This file records decisions required before implementation begins. Items marked `DECISION REQUIRED` must be approved before the relevant component is implemented.

## Phase 1 Decisions

### Service Catalogue

- DECISION REQUIRED: Final port assignments for services other than HTTP and teaching SSH.

### Web and Custom Application

- DECISION REQUIRED: Technology stack for the custom application.
- DECISION REQUIRED: Final custom application vulnerability list.
- DECISION REQUIRED: Which application findings chain into host, service or AD activities.

### Vulnerabilities

- DECISION REQUIRED: Which network-service weaknesses are included in the first build.
- DECISION REQUIRED: Which legacy Apache/PHP misconfigurations are retained.
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

### Platform and Naming

- APPROVED: Retain `CAV-CSF` as the project and repository name during university development.
- APPROVED: Do not create a separate public name or edition unless public release becomes a concrete requirement.
- APPROVED: Avoid unnecessary coupling of service names, hostnames and internal paths to `cav-csf` so a future rename remains manageable.
- APPROVED: The fictional organisation is a UK technology retailer serving consumers, SMEs, education customers and trade partners.
- APPROVED: Use **Brightleaf Retail Ltd** as the fictional organisation across the public `cwscenario.uk` OSINT site and the internal VM scenario.
- APPROVED: Keep the public `cwscenario.uk` host safe and OSINT-only; active scanning and exploitation targets must remain inside the isolated lab.
- APPROVED: Use `cwscenario.uk` only as an optional companion resource; essential classroom material must remain available inside the lab environment.
- APPROVED: Use the reserved `brightleaf.test` namespace for the offline internal lab.
- APPROVED: Use `www.brightleaf.test` for the internal landing site. Additional service names will follow the same namespace as services are implemented.

### First-Build Service Baseline

- APPROVED: Host SSH is administrative only and is not an intentionally vulnerable teaching service. It remains on TCP 22 for the clean base snapshot, then moves to a separately secured management port before teaching SSH is deployed.
- APPROVED: Provide SSH teaching activities through a separate, resettable service on TCP 22 with its own accounts and deliberate weaknesses.
- APPROVED: Test administrative SSH on its new port in a second session before releasing TCP 22, preventing accidental administrator lockout.
- APPROVED: Include HTTP, internal lab DNS, SMB, NFS and FTP as host-visible teaching services.
- APPROVED: Use a maintained FTP implementation with deliberate modern misconfiguration rather than an obsolete vulnerable version.
- APPROVED: Run PostgreSQL in a container with its database port deliberately published to the VM network and link it to the custom application.
- APPROVED: Run OWASP Juice Shop, WebGoat and Security Shepherd as externally reachable containers.
- APPROVED: Implement the custom application separately in Phase 4 after its technology and vulnerability design is approved.
- APPROVED: Defer DVWA, SMTP, SNMP and HTTPS from the first build.
- APPROVED: Do not introduce deliberately obsolete service versions in the first build.
- APPROVED: Defer Active Directory integration until the core Linux environment is stable.

### First Attack Path

- APPROVED: Implement AP-01 first as an end-to-end path: anonymous FTP clue, reused low-privilege teaching credentials, teaching SSH host access, unsafe sudo rule and root outcome.
- APPROVED: Use a dedicated `stockroom` teaching account and generate its active credential during provisioning rather than committing it to the repository.
- APPROVED: Use a dedicated sudoers rule allowing `stockroom` to run `/usr/bin/find` as root without a password for the introductory privilege-escalation outcome.
- APPROVED: Require reset and automated verification for the complete path before adding further deliberate weaknesses.
- APPROVED: Do not enable teaching SSH on TCP 22 until administrative SSH migration and rollback gates pass.

### Second Attack Path

- APPROVED: Implement AP-02 as a host-native, pinned ProFTPD 1.3.5 service compiled with `mod_copy` for CVE-2015-3306 teaching.
- APPROVED: Do not use containers for AP-02.
- APPROVED: Keep AP-01 vsftpd on TCP 21 and expose AP-02 ProFTPD on TCP 2121.
- APPROVED: Use a dedicated Apache/PHP web boundary on TCP 80 and restrict writable scope to the AP-02 web root.
- APPROVED: Separate provisioning verification from instructor-controlled exploit acceptance testing.
