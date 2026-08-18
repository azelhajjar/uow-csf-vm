# CAV-CSF Codex Agent Rules

These rules are mandatory for Codex work in this repository.

Before changing provisioning, runtime configuration, service layouts, vulnerability designs or verification tooling, read:

- `docs/runtime-and-delivery-model.md`
- `docs/architecture.md`
- `docs/services.md`
- `docs/vulnerabilities.md`
- `docs/decisions.md`

If older repository content conflicts with these files or this file, the newer canonical rules take precedence.

## 1. Codex Role

Codex is responsible for repository implementation work, including:

- provisioning scripts;
- installation scripts;
- configuration files and templates;
- service definitions;
- container definitions where appropriate;
- verification scripts;
- static validation;
- repository documentation required to support implementation.

Codex is not the exploitation operator for this project.

Do not attempt to perform or automate instructor exploitation testing against the VM. Claude is used to prepare instructor/student exploitation guidance, and Ayman executes exploitation steps manually.

Codex may build verification tooling that checks whether an intended vulnerable state exists, but verification must not be confused with exploitation or student reset functionality.

## 2. Privileged VM Workflow

Codex may inspect the Ubuntu VM over SSH when access is available.

Do not assume that Codex has working `sudo` privileges.

Ayman will manually execute privileged commands when required.

When a necessary VM operation requires root privileges:

1. prepare the exact command;
2. explain briefly what it changes;
3. give the command to Ayman;
4. wait for the result/output;
5. interpret the result;
6. continue from that state.

Do not repeatedly test `sudo` after it is known not to be available.

Lack of `sudo` is not a project blocker.

## 3. Repository State

When Ayman states that the repository has already been pulled or updated, treat the current checkout as authoritative.

Do not repeatedly run `git pull`, compare local and remote state, or speculate that the repository is stale unless there is a concrete repository error that requires investigation.

Read the files that exist in the current checkout and work from them.

## 4. One Complete VM

Build one complete Linux VM containing all intended applications, services and vulnerabilities.

Do not create separate Level 5, Level 6, Level 7 or CTF VM profiles.

Teaching guides control which parts students use and how much guidance they receive. The runtime remains the same.

## 5. Student Delivery Model

Students receive the completed VM image only.

They do not receive the Git repository, provisioning scripts, build tooling, developer documentation or instructor-only material as part of the normal student workflow.

Each student begins with a fresh copy of the VM.

Therefore, do not create:

- student reset scripts;
- reset menus;
- reset web endpoints;
- per-activity restore systems;
- student-facing recovery services.

Developer/instructor installation, verification and maintenance tooling may exist in the repository, but it is not a student feature.

## 6. Existing Scripts Must Be Audited Before Reuse

Existing provisioning scripts were created before the current runtime model was finalised.

Do not blindly execute them.

Before reusing an existing installer or configuration script:

1. inspect it;
2. compare it with the canonical documentation;
3. identify obsolete assumptions;
4. refactor it where needed;
5. perform static validation;
6. only then propose the VM execution step.

In particular, remove or replace behaviour that deploys teaching identifiers into the runtime.

Repository filenames may retain internal identifiers such as `install-ap02.sh` when useful for development, but deployed artefacts must not use AP/challenge/repository naming.

## 7. Runtime Must Look Real

The deployed VM must resemble a plausible operational Linux server that happens to contain exploitable weaknesses.

Internal identifiers such as `AP-01`, `AP-02`, `WEB01`, `NET03`, challenge IDs or the repository name must not leak unnecessarily into the runtime.

Do not deploy paths or units such as:

```text
/opt/cav-csf/ap02/
/opt/cav-csf/ap03/
/etc/cav-csf/ap02/
/var/www/brightleaf-ap02/
cav-csf-ap02-proftpd.service
ap03-samba.service
```

Prefer normal package paths or plausible operational names such as:

```text
/etc/samba/smb.conf
/srv/shared
/srv/backups
/var/www/warehouse
/var/www/intranet
/opt/document-transfer
/opt/samba-legacy
document-transfer.service
inventory-sync.service
```

Teaching metadata must not unnecessarily appear in runtime directories, services, process names, usernames/groups, databases, SMB shares, DNS names, hostnames, web routes, application titles, configuration names, logs, cron entries or environment variables.

Repository organisation may be pedagogical. Runtime organisation must be realistic.

## 8. CVE-First Vulnerability Strategy

Do not treat the project as a collection of misconfigurations.

The environment must contain a deliberate mix of genuine CVEs, vulnerable services/applications, web/API vulnerabilities, authentication and credential weaknesses, service/filesystem misconfigurations, Linux privilege-escalation weaknesses and later AD/cross-platform weaknesses.

For new service vulnerabilities, use this priority:

1. genuine CVE with a reliable, reproducible and teachable exploitation path;
2. CVE combined with deliberate misconfiguration where that improves the scenario;
3. standalone misconfiguration where no suitable CVE is practical/reliable or where the configuration weakness itself is the intended lesson.

Where appropriate, prefer CVEs with reliable Metasploit modules so students can follow reconnaissance -> version identification -> CVE research -> module selection -> exploitation -> meaningful compromise.

Do not replace a suitable CVE with a simple misconfiguration merely because it is easier to install.

The Ubuntu base remains modern. Individual services/applications may deliberately use pinned vulnerable versions when required for a controlled CVE exercise.

## 9. Network Reconnaissance Must Remain Meaningful

Students must be able to discover intended services using normal reconnaissance and protocol-specific enumeration.

Do not hide every service behind Docker-internal networks.

Use host-installed services, published container ports and internal-only services deliberately.

At least one database should remain directly visible where this supports the teaching design.

Port exposure is a teaching/design decision, not merely a container implementation detail.

## 10. SSH Roles Are Separate

During development:

- TCP `22222` is the administrative SSH channel for Ayman/instructor development access;
- TCP `22` is reserved for the student-visible SSH attack surface and may later host a deliberately vulnerable SSH service/configuration selected for teaching.

Do not conflate these services.

Do not weaken administrative SSH on `22222` merely because TCP `22` is intended to become vulnerable.

Whether `22222` remains in the final student image or is removed before release is a later decision.

## 11. VM Interface and IP Address Rules

The Linux network interface is intended to be `eth0`.

Do not assume a fixed VM IP address.

VMware clones may receive different virtual NIC identities and different DHCP leases.

Never reuse an IP address from:

- another clone;
- another milestone;
- a previous development session;
- old documentation.

Treat clone/milestone identity and IP address as separate facts.

When an IP address is required, determine or confirm the current address for the active VM once and use that address for the current work. Re-check after switching to another clone or when the VM network state changes.

Do not confuse a different DHCP address with a different logical milestone.

## 12. VMware Development Model

Use:

- Git for source/configuration/documentation history;
- VMware snapshots for temporary rollback within an active phase;
- VMware full clones for permanent milestone backups.

Planned full-clone milestones:

- `CAV-CSF-00-Clean`
- `CAV-CSF-01-Base`
- `CAV-CSF-02-Web`
- `CAV-CSF-03-Network`
- `CAV-CSF-04-PrivilegeEsc`
- `CAV-CSF-05-AD-Integrated`
- `CAV-CSF-Release`

Snapshots may be taken before risky installations or configuration changes within a phase. Full clones mark accepted stable milestones.

Do not invent another reset architecture to replace this model.

## 13. Testing Boundaries

Distinguish clearly between:

- static validation;
- repository-level testing;
- container-level testing;
- Ubuntu VM integration testing;
- vulnerability-state verification;
- instructor exploitation acceptance testing.

Do not claim that a vulnerable service is fully accepted merely because its installer ran successfully.

Codex should implement and verify what it can safely verify. Ayman performs privileged VM commands where required and performs exploitation acceptance testing using guidance prepared separately.

## 14. Do Not Redesign Settled Architecture

Do not introduce new profiles, reset systems, runtime naming conventions, SSH architectures, container layouts or vulnerability-selection policies simply because they are easier to implement.

When a genuine unresolved architecture decision appears, raise it before implementation rather than inventing a new convention.
