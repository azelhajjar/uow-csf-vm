# CAV-CSF Windows VM Project Context and Instructions

We are building the **CAV-CSF cyber security lab environment** for the University of Westminster.

The project consists of deliberately vulnerable teaching VMs used for cyber security labs, practical exercises, and assessment preparation. The aim is to provide realistic, discoverable, and educational attack paths rather than old, random, or unrealistic vulnerable-machine behaviour.

## Current Status

The **Linux VM is mostly complete for now**.

The Linux VM provides the main general-purpose vulnerable lab environment, including web application targets, guided training platforms, service misconfigurations, login/banner text, and a landing page for students. It is currently treated as the broad network and services target.

Known Linux VM details:

- Hostname: `cav-csf-linux`
- IP address: `192.168.144.100`
- Student login:
  - Username: `student`
  - Password: `student`
- Admin login:
  - Username: `uow-admin`
- GitHub repository for issue reporting:
  - `https://github.com/azelhajjar/uow-csf-vm.git`

The Linux VM should remain the main environment for general reconnaissance, web/service enumeration, and Linux-focused exploitation or privilege escalation.

SecGen was used only as early inspiration for some initial Linux service ideas from previous Debian 12 experiments. The current VM is a separate University of Westminster teaching VM and should not appear to students as a SecGen-generated VM. SecGen acknowledgement belongs in GitHub documentation only, not on the VM landing page or login banner.

## Windows VM Direction

We are now starting the **Windows Active Directory VM**.

The Windows VM should be a separate but integrated AD-focused machine. It should not replace the Linux VM. It should add Windows domain, Active Directory, Kerberos, DNS, SMB, Windows-hosted web, and possibly AD CS learning paths.

Agreed baseline:

- Windows Server version: **Windows Server 2019**
- Media: **Windows Server 2019 evaluation media**
- Hostname: `dc01`
- IP address: `192.168.144.200`
- Domain: `uow-csf.internal`
- FQDN: `dc01.uow-csf.internal`
- Initial roles: Active Directory Domain Services and DNS
- AD CS should be deferred until the domain controller is stable
- RAM target: **2 GB**
- CPU target: 1-2 vCPU
- Network: same isolated host-only lab network as the Linux VM and Kali

This VM is a temporary teaching artefact that is discarded or rebuilt at the end of each activity. Do not design around long-term licensing. Document the evaluation-period assumption only.

## Claude/Codex Role

Claude/Codex should act as a **design and documentation assistant only**.

It should propose the architecture, write clear build notes, provide manual configuration steps, and prepare verification commands for me to run.

It should not imply that it is directly building, testing, exploiting, or verifying the VM unless I explicitly provide evidence or ask it to act on a local repository/file.

Important constraints:

- Do not assume direct control of the Windows VM.
- Do not run VM commands unless explicitly asked.
- Do not run provisioning scripts unless explicitly asked.
- Do not run attack tools unless explicitly asked.
- Do not imply that anything has been built, tested, exploited, or verified unless I confirm it or provide evidence.
- Provide instructions for me to run manually, including where to run them, what output to expect, and how to confirm success.
- Keep Phase 1 focused on a stable AD/DNS baseline before adding vulnerabilities.

## Resource Constraint

The Windows Server 2019 VM must be designed for a low-resource lab environment.

Target allocation:

- RAM: `2 GB`
- CPU: `1-2 vCPU`
- Disk: keep modest and document the expected minimum
- Avoid heavy services unless there is a clear teaching reason

Install type:

- Prefer **Windows Server 2019 Desktop Experience** for teaching and manual administration.
- If 2 GB RAM proves too constrained, switch to **Server Core** and document the extra administration steps clearly.
- Do not assume 4-8 GB RAM. That is not the target environment.

Design implication:

Prefer a lean AD/DNS domain controller first. Do not add AD CS, SQL Server, Exchange-like services, or heavy web stacks in the first phase.

## Design Philosophy

The Windows VM can include a mix of older and newer weaknesses, but it should not be built mainly as a collection of old Windows CVEs.

The main backbone should be realistic Active Directory misconfigurations and attack paths. Older vulnerabilities, legacy behaviours, or deliberately outdated services may be included where they support a clear teaching purpose, but they should not dominate the design.

Guiding principles:

- Students should enumerate first.
- Weaknesses should be discoverable through normal AD, DNS, SMB, web, and network reconnaissance.
- Attack chains should be deterministic enough for teaching.
- The VM should support L5, L6, and L7 activities, with advanced paths layered gradually.
- Avoid randomised weaknesses for the core teaching path.
- Avoid making the first Windows build too complex.
- Include older vulnerabilities only when they teach a relevant concept or create a useful bridge into the AD environment.
- Prefer misconfiguration, poor operational practice, weak credentials, exposed information, and realistic privilege paths over isolated one-shot exploits.

## Reference Repositories

These repositories were reviewed as inspiration:

- `https://github.com/safebuffer/vulnerable-AD`
- `https://github.com/arth0sz/Practice-AD-CS-Domain-Escalation`
- `https://github.com/cliffe/SecGen`

Important distinction:

- `vulnerable-AD` is useful for AD misconfiguration ideas such as Kerberoasting, AS-REP roasting, weak passwords, password spraying, bad ACLs, DnsAdmins, DCSync, and SMB signing weaknesses.
- `Practice-AD-CS-Domain-Escalation` is useful later for AD CS paths such as ESC1 or ESC4.
- `SecGen` is useful only as historical/inspirational context for the broader vulnerable VM idea, not as the model for the Windows AD VM.

## Windows Web Application Component

The Windows VM design should include a proposed vulnerable or deliberately misconfigured website, but this should be documented and planned first rather than assumed to be implemented immediately.

The website should not simply duplicate the Linux VM web targets. The Linux VM already provides broad web application practice through services such as WebGoat, WebWolf, Security Shepherd, DVWA, and Juice Shop.

The Windows-hosted website should support the Active Directory learning path by exposing domain-relevant clues, credentials, service names, internal hostnames, user patterns, or controlled misconfigurations.

Possible options:

- A lightweight IIS/custom intranet site.
- A simple custom vulnerable website connected to AD-style organisational data.
- A service desk or staff portal that leaks useful reconnaissance clues.
- A lightweight vulnerable Windows-compatible site if it does not exceed the 2 GB RAM target.
- WordPress only if there is a strong teaching reason and the resource cost is acceptable.

Preferred direction:

Use the Windows website as a reconnaissance and initial-access bridge into the AD environment, rather than as a standalone OWASP-only target.

Examples of useful website-based clues:

- Staff names and usernames.
- Department names matching AD groups.
- Internal hostnames.
- Service account references.
- Backup/configuration files.
- Exposed comments or metadata.
- Links to SMB shares or internal services.
- Weak login credentials reused elsewhere.
- Hints about password conventions.
- References to the Linux VM and Windows DC belonging to the same lab organisation.

## Proposed Windows VM Phases

### Phase 1: Stable AD Baseline

Build a clean Windows Server 2019 domain controller:

- Static IP: `192.168.144.200`
- Hostname: `dc01`
- New forest/domain: `uow-csf.internal`
- DNS role installed and working
- Basic domain users and groups
- Linux VM can resolve or refer to `dc01.uow-csf.internal`
- No AD CS yet
- No complex vulnerabilities yet
- No heavy website yet

### Phase 2: Core AD Misconfiguration Path

Add deterministic AD weaknesses such as:

- Weak/default domain passwords
- Password reuse for spraying
- Passwords or clues in AD user descriptions
- Kerberoastable service accounts with SPNs
- AS-REP roastable users
- Over-privileged users or groups
- Misconfigured AD ACLs
- DnsAdmins abuse path
- Optional DCSync path for advanced learners
- SMB signing weakness if useful and realistic
- Lightweight Windows-hosted intranet or vulnerable web component

### Phase 3: Advanced AD CS Path

Only after the DC is stable, add AD CS:

- Enterprise CA
- One deliberately vulnerable template first
- Prefer ESC1 or ESC4 as the first AD CS teaching path
- Keep ESC7 and more complex certificate abuse as optional advanced material

## Open Decisions - Current Answers

- Network segment: use the same isolated host-only lab network as the Linux VM and Kali.
- Static IP: confirmed. `dc01` uses `192.168.144.200`; Linux VM uses `192.168.144.100`.
- Internet during build: allowed temporarily for installation/updates if needed, then removed/disabled before lab-ready distribution.
- Install type: prefer Windows Server 2019 Desktop Experience for teaching and manual administration. If 2 GB RAM proves too constrained, switch to Server Core and document the extra administration steps.
- Domain-joined workstation: deferred. Phase 1 is DC only.
- Licensing/media: use Windows Server 2019 evaluation media. The VM is discarded/rebuilt at the end of each activity, so document the evaluation assumption and do not design around long-term licensing.
- Snapshot naming: use `CAV-CSF-Win-01-Baseline-ADDS-DNS`.
- Time source: keep default/simple for Phase 1. Revisit NTP/Kerberos time discipline when cross-VM Kerberos activities are added.

## Immediate Task

Prepare the Windows Server 2019 AD baseline design and documentation.

Focus on producing:

1. VM role and network assumptions.
2. Domain and hostname configuration.
3. Initial AD users and groups.
4. DNS records and Linux integration points.
5. Proposed Windows-hosted vulnerable website role.
6. Health checks for confirming the DC is working.
7. Manual build steps I can follow.
8. Manual test commands I can run.
9. Expected outputs from those checks.
10. Reproducible exploit/walkthrough instructions for later vulnerability phases.
11. What to defer until the vulnerability phase.
12. Open decisions before implementation.

Do not run attack tools, provisioning scripts, VM commands, or deployment commands unless explicitly asked. Keep this stage focused on design and a stable baseline.