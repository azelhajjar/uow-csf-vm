# Architecture

## Purpose

CAV-CSF is one reusable Ubuntu Server vulnerable teaching VM. It supports network penetration testing, web application penetration testing, cyber security labs, advanced penetration testing, Level 7 scenario work and University-run CTF events from one common installation.

The VM does not use separate module profiles or dynamically enabled vulnerability sets. Teaching guides control what each student group is asked to investigate.

The canonical runtime, student-delivery, vulnerability-selection and recovery rules are defined in `docs/runtime-and-delivery-model.md`.

## Base Platform

- Operating system: Ubuntu Server 26.04 LTS.
- Architecture: amd64.
- Installation type: minimal server installation.
- Primary virtualisation platform: VMware Workstation.
- Host services: systemd.
- Provisioning scripts: Bash and Python.
- Containers: Docker Engine and Docker Compose where containerisation improves maintainability without hiding services students are expected to discover.

## Final Student Delivery Model

Students receive only the completed VM image.

They do not receive the Git repository, provisioning source, instructor documentation, internal attack-path maps, build scripts or developer recovery tooling. Each student begins from a fresh copy of the VM.

There is no requirement for student-facing reset buttons, activity-reset scripts, per-challenge restore features or similar mechanisms. If a student VM becomes unusable, the normal recovery method is to provide a fresh copy of the distributed VM image.

Developer and instructor provisioning, verification and recovery tooling may exist in the repository, but it must not be confused with the student experience.

## Deployment Boundary

The final vulnerable environment runs inside the Ubuntu Server VM. The Windows host is only the VMware host. Repository work in Codex or other development environments creates and validates source-controlled files but does not prove Ubuntu VM integration.

Ubuntu VM integration, exploitation testing and instructor acceptance testing are performed on the VM.

## Source Layout

The source repository may use pedagogical organisation such as:

```text
docs/
provisioning/
containers/
custom-app/
flags/
scripts/
tests/
instructor/
```

Internal identifiers such as `AP01`, `AP02`, `WEB01` or `NET03` may be useful inside repository documentation and tests.

They must not automatically become runtime names.

## Runtime Realism

The deployed VM must resemble a plausible real Linux server rather than a labelled teaching appliance.

Do not expose attack-path identifiers, repository names, challenge numbers or module labels through deployed paths, service names, processes, systemd units, users, groups, shares, database names, web routes or other student-visible artefacts.

For example, do not deploy:

```text
/opt/cav-csf/ap03/samba/
/srv/challenge-04/
/var/www/web01/
```

Prefer normal package locations or plausible operational names such as:

```text
/etc/samba/smb.conf
/srv/shared
/srv/backups
/var/www/portal
/var/www/intranet
/opt/reporting-service
/opt/samba-legacy/
```

Repository organisation may be pedagogical. Runtime organisation must be realistic.

## Service Architecture

The VM should expose a meaningful host-visible attack surface. Services use a deliberate mix of:

- host-installed services;
- containerised applications with ports published on the VM network interface;
- selected supporting services, including a database, exposed to the VM network;
- internal-only services used only where hidden placement has a deliberate advanced-discovery or post-exploitation purpose.

Docker must not hide services that students are expected to discover during network reconnaissance.

Administrative SSH must remain distinct from the vulnerable teaching environment. If TCP 22 is needed for student-facing SSH, administrative SSH moves to a separately secured management port and is verified before TCP 22 is released.

## Vulnerability Architecture

The VM must contain more than deliberate misconfigurations.

The intended mix includes:

- genuine exploitable CVEs;
- vulnerable network services and applications;
- web and API vulnerabilities;
- credential and authentication weaknesses;
- Linux privilege-escalation weaknesses;
- realistic configuration weaknesses;
- selected cross-platform AD-related weaknesses.

Where practical, a genuine CVE with a reliable teaching path is preferred over a standalone misconfiguration. Where appropriate, select CVEs with reliable Metasploit modules so students can progress from enumeration and version identification to exploitation through `msfconsole`.

CVE-based vulnerabilities may be combined with misconfigurations when the combination improves the teaching scenario.

Keep the Ubuntu base modern, but allow deliberately selected vulnerable service/application versions where they are required for reliable CVE-based exercises.

## Reconnaissance Surface

The VM represents **Brightleaf Retail Ltd**, a fictional UK technology retailer, unless the scenario name is changed later. The environment should include:

- public web pages;
- hostnames and virtual hosts;
- DNS records;
- service banners;
- documents and metadata;
- staff, department and support references;
- realistic directory, file, share and service names.

Critical classroom reconnaissance material must work inside the lab network. Internal active-testing targets use the reserved `brightleaf.test` namespace. The public `cwscenario.uk` site is contextual/OSINT material and must not be required for active exploitation exercises.

## Development Milestones, Clones and Snapshots

The planned permanent full-clone milestones are:

- `CAV-CSF-00-Clean`
- `CAV-CSF-01-Base`
- `CAV-CSF-02-Web`
- `CAV-CSF-03-Network`
- `CAV-CSF-04-PrivilegeEsc`
- `CAV-CSF-05-AD-Integrated`
- `CAV-CSF-Release`

These are development milestones, not separate student editions.

Use snapshots as temporary rollback points within an active phase. A phase may contain several snapshots before risky installations or configuration changes. Once the phase is stable and accepted, create the next full-clone milestone.

The recovery layers are:

- Git repository: source/configuration/documentation history;
- VMware snapshots: short-term rollback during active experimentation;
- full clones: permanent milestone backups;
- final VM image: student-facing release.

## Verification Architecture

Verification should report clear results such as:

- PASS;
- FAIL;
- expected vulnerability missing;
- unintended exposure detected;
- dependency unavailable.

Verification should cover listening ports, application responses, service versions, accounts, permissions, intended CVEs/misconfigurations, flags, AD-offline boot and AD-online integration.

Verification is an instructor/development concern. It does not imply a requirement for per-activity student reset functionality.

## Constraints

- Do not rely on configuration weaknesses alone when a suitable real CVE can provide the intended lesson.
- Do not place every service inside Docker-internal networks.
- Do not expose instructor credentials, hidden accounts, flags or exploitation paths in public/student-facing documentation.
- Do not expose internal teaching identifiers in runtime names or paths.
- Do not join Active Directory until Windows environment details are agreed.
