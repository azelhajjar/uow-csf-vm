# CAV-CSF Implementation Rules for Claude

These rules are mandatory for all future implementation work in this repository.

Read `docs/runtime-and-delivery-model.md` before changing provisioning, service layouts, vulnerability designs or runtime configuration.

If older documentation conflicts with this file or `docs/runtime-and-delivery-model.md`, the newer canonical rules take precedence.

## 1. Final Student Experience

The final deliverable is a completed vulnerable VM image.

Students receive the VM image only. They do not receive this repository, provisioning scripts, developer tools, instructor manifests, internal attack-path documentation or source-controlled build material as part of the normal lab experience.

Each student starts from a fresh copy of the VM.

Therefore:

- do not create student-facing reset scripts;
- do not create reset buttons or reset web endpoints;
- do not create per-challenge restore menus;
- do not design an activity around students restoring the environment;
- do not add reset instructions to student labs unless explicitly requested.

Existing `reset-*` scripts, if retained, are instructor/developer recovery tools only.

If a student VM becomes unusable, the normal recovery method is to replace it with a fresh VM image.

## 2. One VM, Not Profiles

Build one complete Linux VM containing all intended applications, services and vulnerabilities.

Do not create separate Level 5, Level 6, Level 7 or CTF VM configurations/profiles.

Teaching guides determine what students are asked to investigate. The VM itself remains the same.

## 3. Vulnerability Means More Than Misconfiguration

Do not interpret 'vulnerable VM' as 'misconfigured VM'.

The environment must contain a mixture of:

- genuine exploitable CVEs;
- vulnerable network services/applications;
- web/API vulnerabilities;
- credential/authentication weaknesses;
- service/filesystem misconfigurations;
- Linux privilege-escalation weaknesses;
- later AD/cross-platform weaknesses.

### Selection priority

When choosing a new service vulnerability:

1. Prefer a genuine CVE with a reliable, reproducible and teachable exploitation path.
2. Prefer CVEs with reliable Metasploit modules where this supports the curriculum, so students can enumerate the service/version, identify the CVE and exploit it through `msfconsole`.
3. Combining a CVE with a deliberate misconfiguration is acceptable and often desirable.
4. Use a standalone misconfiguration when no suitable CVE is practical/reliable, or when the configuration weakness itself is the intended lesson.

Do not replace a suitable CVE exercise with a simple misconfiguration merely because the misconfiguration is easier to provision.

The Ubuntu base remains modern. Individual services/applications may deliberately run pinned vulnerable versions when required for a controlled CVE exercise.

## 4. Runtime Must Look Real

Repository and instructor documentation may use internal identifiers such as:

- `AP-01`;
- `AP-02`;
- `WEB01`;
- `NET03`;
- challenge IDs.

These identifiers are internal metadata only.

They must not dictate deployed runtime names.

Do not create runtime artefacts such as:

```text
/opt/cav-csf/ap03/samba/
/opt/cav-csf/ap02/proftpd/
/var/www/brightleaf-ap02/
/srv/challenge-04/
cav-csf-ap02-proftpd.service
ap03-samba.service
```

Use normal Linux locations or plausible organisational/service names instead, for example:

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

Do not expose teaching metadata unnecessarily in:

- directories;
- service/systemd names;
- process names;
- usernames/groups;
- databases/schemas;
- SMB shares;
- DNS/hostnames;
- web routes/app titles;
- config/log/cron names;
- environment variables.

Repository organisation may be pedagogical. Runtime organisation must be realistic.

## 5. Existing AP-02 Naming Is Temporary

The current reference AP-02 implementation uses development-labelled paths and unit names. This is known technical debt.

Do not copy that naming pattern into new services.

Before final release, AP-02 runtime artefacts must be migrated to realistic operational names while preserving the verified CVE-2015-3306 vulnerable condition.

## 6. Network Reconnaissance Must Remain Meaningful

Students must be able to discover intended services using normal reconnaissance and enumeration.

Do not hide every backend service behind Docker-internal networks.

Use a deliberate mixture of:

- host-installed services;
- containers with published ports;
- externally visible supporting services such as at least one database;
- internal-only services only when hidden placement has a deliberate advanced-discovery/post-exploitation purpose.

Students should be able to follow:

Reconnaissance -> Enumeration -> Vulnerability identification -> Exploitation -> Post-exploitation

## 7. Development Recovery Model

Use:

- Git for source/configuration/documentation history;
- VMware snapshots for temporary rollback within an active development phase;
- VMware full clones for permanent milestone backups.

Planned full-clone milestones:

- `CAV-CSF-00-Clean`
- `CAV-CSF-01-Base`
- `CAV-CSF-02-Web`
- `CAV-CSF-03-Network`
- `CAV-CSF-04-PrivilegeEsc`
- `CAV-CSF-05-AD-Integrated`
- `CAV-CSF-Release`

Do not invent a separate student reset architecture to replace this model.

## 8. Verification Is Not Reset

Every intentional vulnerability should be verifiable.

Verification confirms that the intended vulnerable state exists and behaves as designed.

Do not infer from a verification requirement that every activity needs a reset script.

Instructor/developer recovery tooling may be used during build/test work. Student recovery remains a fresh VM copy.

## 9. Do Not Redesign Agreed Architecture Without Approval

Before adding a major service, vulnerability, container, custom runtime path or new recovery mechanism:

- check the current documentation;
- preserve agreed architecture;
- record genuine unresolved decisions in `docs/decisions.md`;
- do not create extra complexity merely because it is convenient for implementation.

When uncertain whether a change affects the agreed student experience, CVE strategy, runtime realism or milestone model, stop and ask rather than inventing a new convention.
