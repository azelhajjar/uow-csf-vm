# Project: University Vulnerable Linux Teaching VM
## Project purpose
Build a reusable, intentionally vulnerable Linux virtual machine for cyber security and penetration-testing teaching at the University of Westminster.
The platform will replace the existing OWASP Broken Web Applications and Metasploitable-style teaching environment.
The VM must support several modules and levels from one common installation. Do not create separate VM editions, module profiles or dynamically enabled vulnerability sets. All intended applications, services and vulnerabilities should remain present in the same environment.
Differences between modules and academic levels will be controlled through separate teaching guides, task scope and the amount of guidance provided to students.
The VM must also support an internally developed capture-the-flag event.

## Repository and legacy context

The working repository name is:

`cav-csf`

This is a temporary name and may be changed later. Avoid coupling scripts, service names, hostnames, branding or internal identifiers unnecessarily to the repository name.

A previous implementation attempt has been moved into:

`legacy/`

The `legacy/` directory is provided only as context for the new design. It may contain earlier code, scripts, configurations, documentation, vulnerability ideas or incomplete approaches.

Before designing or implementing a component:

1. inspect any relevant material in `legacy/`;
2. identify ideas or components worth reusing;
3. identify anything obsolete, incomplete or unsuitable;
4. record whether the component should be reused, adapted or replaced.

Do not assume that anything in `legacy/` is correct, complete or compatible with the new design.

Do not modify, delete, execute or automatically copy material from `legacy/` unless explicitly instructed.

All new implementation must remain outside `legacy/`.

Relevant decisions should be recorded in:

`docs/decisions.md`
## Public-facing README

The existing `README.md` contains temporary project instructions and development context. It is not the final public-facing README and may be removed or replaced later.

Create:

`README-public-facing.md`

For now, create the file with only:

# CAV-CSF

Public-facing documentation will be added as the environment is developed.

Update `README-public-facing.md` incrementally as implementation progresses.

Only add information that has been implemented and is suitable for public use, including:

- project purpose;
- supported Ubuntu version;
- VM resource recommendations;
- prerequisites;
- required software;
- installation and setup instructions;
- service start, stop and status commands;
- reset and recovery procedures;
- verification steps;
- known limitations;
- release information.

Do not include:

- instructor credentials;
- hidden accounts;
- vulnerability solutions;
- flag values;
- exploitation paths;
- unresolved design discussions;
- material from the `legacy/` directory;
- unimplemented or unverified information.

Whenever a task changes a public prerequisite, dependency, command, service name, port, reset process or verification step, update `README-public-facing.md` as part of the same task.

Do not rename `README-public-facing.md` to `README.md` until explicitly instructed.
## Base platform
Use:
- Ubuntu Server 26.04 LTS
- amd64 architecture
- minimal server installation
- VMware Workstation as the primary virtualisation platform
- systemd for host services
- Docker Engine and Docker Compose for suitable vulnerable applications
- Bash and Python for provisioning, reset and verification scripts
The VM must eventually join a separate Windows Server Active Directory domain as a member server.
Do not use Kali Linux as the server operating system.

## Execution and testing environment

The Codex development environment is not the final deployment environment.

The user's host machine is Windows. The intended vulnerable server will run as a separate Ubuntu Server virtual machine.

Do not attempt to install, configure or run the complete vulnerable environment directly on the user's Windows host machine.

Do not assume that successful execution inside the Codex container proves that the final Ubuntu VM works correctly.

Codex should:

- create and maintain the source code;
- create provisioning and configuration scripts;
- create container definitions;
- create installation, reset, status and verification scripts;
- perform safe static checks and repository-level tests where practical;
- document the commands that must be run on the Ubuntu VM;
- report prerequisites, expected output and likely failure conditions.

The user will perform integration, exploitation and final acceptance testing on the Ubuntu Server VM.

Do not instruct the user to run Linux provisioning commands directly in Windows PowerShell or Command Prompt.

Where Windows is used only to host VMware Workstation, treat it as the virtualisation host rather than the target deployment platform.

Do not require privileged host operations from the Codex environment. Do not attempt to:

- modify the Windows host;
- install VMware components;
- create or control the final VMware VM;
- join the final Linux VM to Active Directory;
- alter host networking;
- run intentionally vulnerable services on the user's host;
- perform live exploitation against the user's machines.

Scripts must target Ubuntu Server and should fail clearly when run on an unsupported operating system.

For each implementation phase, provide the user with:

1. files added or changed;
2. commands to run on the Ubuntu VM;
3. expected results;
4. verification commands;
5. rollback or reset instructions;
6. any results that Codex could not validate within its own environment.

Do not claim that a component has been fully tested unless it has been tested in the appropriate Ubuntu VM environment. Clearly distinguish among:

- static validation;
- container-level testing;
- Codex-environment testing;
- Ubuntu VM integration testing;
- instructor acceptance testing.

## Host, container and network-service architecture

Docker may be used for selected vulnerable applications where it improves deployment, dependency management and reset reliability. However, containerisation must not hide services that students are expected to discover, enumerate or exploit through network reconnaissance.

The Linux VM must present a meaningful host-visible attack surface. Students scanning the VM with tools such as Nmap must be able to discover selected web applications, databases, file-sharing services, remote-access services and other deliberately exposed network services.

Do not place all applications and supporting components exclusively on Docker-internal networks.

Use a deliberate combination of:

- services installed directly on the Ubuntu host;
- containerised applications with ports published on the VM network interface;
- selected containerised supporting services with published ports;
- internal-only services intended for advanced discovery or post-exploitation.

At least one database service must be directly reachable from the VM network and visible during port scanning. This may run directly on the host or in a container with its port deliberately published.

The exposed database should support relevant teaching activities such as:

- service and version enumeration;
- authentication testing;
- weak or reused credential discovery;
- direct database access;
- data extraction;
- linking database findings to a vulnerable web application;
- using database access as part of a broader compromise.

Established vulnerable applications such as OWASP Juice Shop, WebGoat and Security Shepherd may remain containerised, provided their intended web interfaces are reachable from the VM network.

The custom vulnerable application should be designed so that its supporting services can contribute to both web application and network penetration-testing activities. Its database or another selected backend service should therefore be externally visible where this supports the intended learning outcomes.

For every application and service, document:

- service name;
- host or container deployment;
- listening address;
- TCP or UDP port;
- external or internal visibility;
- reason for inclusion;
- intended student activities;
- deliberate vulnerability or misconfiguration;
- expected exploitation outcome;
- reset requirements;
- dependencies on other services.

Do not publish every container port automatically. Port exposure must be an explicit design decision based on the teaching purpose of the service.

Do not use Docker solely for convenience where it would remove network visibility required by the laboratories.

The architecture must preserve both:

1. realistic host-level network reconnaissance and service enumeration;
2. reliable deployment and restoration of complex vulnerable applications.

## Primary design principles
1. Build one complete Linux VM containing all intended applications, services and vulnerabilities.
2. Do not create Level 5, Level 6, Level 7 or CTF VM profiles.
3. Teaching guides will direct students towards the activities suitable for each module.
4. Use one maintainable and reproducible build.
5. Keep the base operating system modern.
6. Introduce weaknesses deliberately through applications, services, permissions, credentials and configuration.
7. Avoid relying primarily on obsolete operating-system packages.
8. Support both independent exercises and weaknesses that can be chained during advanced activities.
9. Do not make every vulnerability part of one mandatory linear attack path.
10. Ensure that introductory activities can be completed without requiring advanced exploitation.
11. Make all intended behaviour reproducible from source-controlled provisioning.
12. Provide verification tests for every intended vulnerability.
13. Clearly document all intentional weaknesses for instructors.
14. Do not expose solutions, flags or instructor credentials in student-facing material.
## Teaching use
The Linux VM will be used for the following purposes.
### Level 5 Network Penetration Testing
Support:
- host discovery
- TCP and UDP scanning
- service detection
- operating-system and version enumeration
- banner analysis
- network-service enumeration
- password testing against selected services
- exploitation of service misconfiguration
- exploitation of selected vulnerable services
- initial access
- basic post-exploitation
- Linux privilege escalation
- evidence collection
- remediation analysis
### Level 5 Web Application Penetration Testing
Support:
- web-content discovery
- application fingerprinting
- HTTP request and response analysis
- authentication testing
- session testing
- access-control testing
- injection attacks
- file-handling attacks
- API testing
- client-side vulnerabilities
- server-side vulnerabilities
- business-logic testing
- evidence collection
- remediation analysis
### Level 6 6COSC019W Cyber Security
Support:
- reconnaissance
- active information gathering
- Nmap scanning
- service enumeration
- vulnerability identification
- web exploitation
- network-service exploitation
- Metasploit usage
- manual exploitation where appropriate
- packet capture and protocol analysis
- post-exploitation
- basic privilege escalation
- basic lateral-movement concepts
- threat modelling
- security reporting
### Level 6 Advanced Penetration Testing
Support:
- limited-guidance enumeration
- exploitation without procedural walkthroughs
- vulnerability chaining
- credential discovery
- password reuse
- Linux privilege escalation
- pivoting concepts
- interaction with the Windows AD environment
- Linux-to-Windows lateral movement
- Windows-to-Linux lateral movement
- Kerberos and AD-linked credentials
- cross-platform attack paths
### Level 7
Support scenario-led activities with limited technical guidance.
Students may receive only:
- organisational context
- authorised scope
- rules of engagement
- high-level objectives
- required deliverables
The platform must allow independent reconnaissance, attack-path discovery, exploitation and critical evaluation.
### Capture-the-flag events
The custom application and selected host components must support University-run CTF events.
CTF support should include:
- web flags
- network-service flags
- application-user flags
- Linux-user flags
- Linux-root flags
- credential-discovery flags
- cross-platform flags
- optional AD-related flags
- instructor flag manifest
- automated flag verification
- a simple process for replacing flag values before an event
Do not create a full public CTF management platform unless explicitly requested. The initial requirement is to place, generate, document and verify flags within the VM and custom application.
## Existing teaching activities to retain or modernise
The existing laboratories currently include:
- robots.txt analysis
- web-directory discovery
- DirBuster or equivalent content discovery
- Nmap host and service scanning
- Nmap Scripting Engine
- service enumeration
- FTP enumeration
- SMB enumeration
- SNMP enumeration
- SSH testing
- HTTP traffic capture
- plaintext credential observation
- Wireshark filters and packet analysis
- password testing with Hydra
- exploitation through Metasploit
- Meterpreter or shell post-exploitation
- Linux enumeration
- Linux privilege escalation
- credential discovery
- lateral movement
- web vulnerabilities using DVWA, WebGoat and Security Shepherd
- OWASP-aligned web testing
Retain the learning outcomes, but do not reproduce obsolete commands, unsupported tools or unnecessary historical implementation details merely for compatibility with the old labs.
## Web application environment
Install established vulnerable applications where technically practical:
- OWASP Juice Shop
- OWASP WebGoat
- OWASP Security Shepherd
- optionally DVWA if it provides distinct introductory value
Use the OWASP Vulnerable Web Applications Directory as a source for evaluating additional applications. It is not itself an application to install.
PortSwigger Web Security Academy is an external teaching resource and should not be copied into the VM.
Prefer containers for established vulnerable applications so that they can be installed and reset consistently.
Each application must use a clearly documented port or hostname.
Provide a simple landing page that lists the installed teaching applications without disclosing solutions.
## Custom vulnerable application
Develop one original vulnerable application owned and maintained as part of this project.
The application will serve two purposes:
1. curriculum-aligned web penetration-testing activities;
2. University-run capture-the-flag events.
Do not attempt to reproduce every vulnerability available in Juice Shop, WebGoat or PortSwigger.
The custom application should provide a coherent fictional organisational context and contain deliberately selected vulnerabilities that match module learning outcomes.
The initial custom application should aim to include approximately 10 to 12 well-tested vulnerabilities across categories such as:
- SQL injection
- command injection
- reflected XSS
- stored XSS
- broken authentication
- insecure session handling
- broken access control
- insecure direct object reference
- API broken object-level authorisation
- path traversal
- insecure file upload
- sensitive information disclosure
- server-side request forgery
- business-logic weakness
The exact final selection must be agreed before implementation.
Some vulnerabilities should provide self-contained web exercises. Others may reveal credentials or information that become useful during advanced host or AD activities.
Do not force every vulnerability into a single attack chain.
## Network services
The VM should expose a deliberate and documented set of network services suitable for scanning and enumeration.
Candidate services include:
- HTTP and HTTPS
- SSH
- FTP
- SMB
- NFS
- DNS
- SMTP
- SNMP
- a database service
- one custom TCP service
Do not install every candidate automatically. First create a service-selection document explaining:
- teaching purpose
- intended weakness
- student technique
- expected exploitation outcome
- maintenance burden
- interaction with other services
Each enabled service must have a clear pedagogical role.
Possible deliberate weaknesses include:
- anonymous access
- weak credentials
- default credentials
- readable shares
- writable shares
- information leakage
- unsafe permissions
- plaintext authentication
- credential reuse
- exposed backup files
- excessive service privileges
- insecure service configuration
- vulnerable application code
- custom vulnerable protocol handling
Avoid filling the VM with unrelated obsolete daemons solely to increase the number of open ports.
## Linux privilege escalation
Implement several independent privilege-escalation opportunities of different difficulty.
Candidate categories include:
- weak sudo rules
- SUID binary misuse
- Linux capabilities misuse
- writable privileged scripts
- insecure cron tasks
- insecure systemd services
- exposed credentials
- password reuse
- weak file and directory permissions
- unsafe environment-variable handling
- service-account misuse
- application-to-host credential exposure
Each route must be:
- intentional
- documented
- independently testable
- reliable after reset
- mapped to a learning outcome
- distinguishable from accidental system misconfiguration
Do not rely primarily on kernel exploits.
## Active Directory integration
The Linux VM must be capable of joining the separate Windows Active Directory domain as a genuine member server.
Plan for:
- DNS integration
- Kerberos
- realmd
- SSSD
- Samba
- AD user and group resolution
- selected AD-authenticated SSH access
- selected AD-authenticated SMB access
- an AD service account used by a Linux application or service
- at least one cross-platform credential-discovery opportunity
- at least one Linux-to-Windows activity
- at least one Windows-to-Linux activity
Do not implement the final domain join until the Windows environment, domain name, users, groups and service accounts have been agreed.
The Linux VM must still support its Linux-only teaching activities when the Windows AD VM is not running. AD-dependent services should fail cleanly rather than preventing the VM from starting.
## CTF flags
Use a consistent flag format, initially:
UOWCTF{example_value}
The prefix must be configurable.
Flags may be stored in:
- web responses
- database records
- API output
- restricted files
- application configuration
- user home directories
- root-only locations
- service output
- SMB resources
- AD-linked artefacts
Do not place every flag in a predictable `flag.txt` file.
Create:
- a flag-generation script
- an instructor-only flag manifest
- a flag verification script
- documentation showing the intended route to each flag
- a method for replacing event flags without rebuilding the entire VM
Do not implement per-team dynamic infrastructure in the first version unless explicitly requested.
## Student-facing entry point
Create a simple landing page for the Linux VM.
The page may include:
- fictional organisation branding
- links to intentionally public applications
- basic organisational information
- contact or support information used for reconnaissance exercises
- realistic documents or pages that provide clues
The page must not list:
- vulnerabilities
- privileged credentials
- hidden services
- flags
- attack paths
- instructor notes
## Provisioning and repository structure
Use source-controlled provisioning rather than relying solely on a manually configured VM image.
Proposed repository structure:
project-root/
├── README.md
├── docs/
│ ├── architecture.md
│ ├── services.md
│ ├── vulnerabilities.md
│ ├── attack-paths.md
│ ├── module-mapping.md
│ ├── testing.md
│ └── decisions.md
├── legacy/ -- this will be removed later. 
├── provisioning/
│ ├── base/
│ ├── packages/
│ ├── services/
│ ├── users/
│ ├── permissions/
│ └── ad/
├── containers/
│ ├── compose.yml
│ ├── juice-shop/
│ ├── webgoat/
│ ├── security-shepherd/
│ └── custom-app/
├── custom-app/
│ ├── application/
│ ├── api/
│ ├── database/
│ ├── seed/
│ └── tests/
├── flags/
│ ├── definitions/
│ ├── generate/
│ └── verify/
├── scripts/
│ ├── install.sh
│ ├── configure.sh
│ ├── reset.sh
│ ├── verify.sh
│ └── status.sh
├── tests/
│ ├── services/
│ ├── vulnerabilities/
│ ├── privilege-escalation/
│ └── integration/
└── instructor/
    ├── credentials.example.yml
    ├── flags.example.yml
    └── solutions/
Do not place real credentials or active flag values in the Git repository.
## Reset and recovery
The platform must support reliable recovery.
Provide:
- a full installation script
- an idempotent configuration process where practical
- a service-status script
- a reset script for applications and databases
- a reset mechanism for user files and flags
- verification after reset
- instructions for producing a clean VMware snapshot
- instructions for rebuilding from source
The reset script must not silently repair deliberate vulnerabilities.
Application reset and full VM restoration are different operations and must be documented separately.
## Verification
Create automated tests that confirm:
- required ports are listening
- expected applications respond
- test accounts exist
- intended permissions are present
- intended vulnerabilities remain exploitable
- unintended administrative access is not present
- privilege-escalation routes work as designed
- flags are present and verifiable
- reset restores the intended state
- the VM boots correctly without the AD VM
- AD integration works when the domain is available
Tests should report clearly:
- PASS
- FAIL
- expected vulnerability missing
- unintended exposure detected
- dependency unavailable
## Documentation
Maintain separate documentation for:
### Developers
- architecture
- installation
- dependencies
- implementation decisions
- test procedures
- reset procedures
### Instructors
- all accounts and credentials
- all deliberate vulnerabilities
- intended exploitation routes
- learning-outcome mappings
- flags and solutions
- recovery instructions
### Students
Student lab guides will be created separately.
Do not expose instructor documentation through the VM web interface or student distribution repository.
## Development process
Work incrementally.
Before implementing a major component:
1. document the proposed component;
2. state its teaching purpose;
3. identify dependencies;
4. identify maintenance risks;
5. propose verification tests;
6. wait for approval where the design has not yet been agreed.
Do not install a large collection of vulnerable services without prior agreement.
Do not redesign the project architecture unnecessarily.
Prefer refinement, simplicity and maintainability over feature volume.

Before completing the Phase 1 design documents, inspect the `legacy/` directory and create:

`docs/legacy-review.md`

The document should summarise:

- the legacy directory structure;
- the purpose of significant components;
- material worth reusing;
- material requiring adaptation;
- material that should be replaced;
- unresolved questions raised by the previous attempt.

## Initial delivery phases
### Phase 1: Design
Produce:
- architecture document
- service catalogue
- vulnerability catalogue
- module mapping
- proposed fictional organisation
- custom application outline
- privilege-escalation options
- AD integration requirements
- initial CTF flag plan
Do not implement vulnerabilities during Phase 1.
### Phase 2: Base VM
Implement:
- Ubuntu Server base
- required packages
- Docker Engine
- Docker Compose
- repository scripts
- landing page
- service health checks
### Phase 3: Established web applications
Install and test:
- Juice Shop
- WebGoat
- Security Shepherd
- optional DVWA if approved
### Phase 4: Custom application
Implement the agreed custom application and its initial vulnerability set.
### Phase 5: Network services
Implement the approved service catalogue and deliberate weaknesses.
### Phase 6: Linux privilege escalation
Implement and verify the approved privilege-escalation routes.
### Phase 7: Active Directory integration
Join the Linux host to the agreed Windows domain and implement the approved cross-platform activities.
### Phase 8: CTF support
Add flag generation, placement, manifest generation and verification.
### Phase 9: Validation and release
Complete:
- functional testing
- exploitation testing
- reset testing
- student-machine resource testing
- instructor documentation
- clean VMware image
- release archive
- checksums
- version notes
## Immediate task
Start with Phase 1 only.
Create the following files:
- `docs/legacy-review.md`
- `docs/architecture.md`
- `docs/services.md`
- `docs/vulnerabilities.md`
- `docs/module-mapping.md`
- `docs/custom-application.md`
- `docs/linux-privilege-escalation.md`
- `docs/ad-integration.md`
- `docs/ctf.md`
- `docs/decisions.md`
Populate them with proposed designs based on these instructions.
Do not install software or write vulnerable implementation code yet.
Clearly mark every unresolved design decision as:
`DECISION REQUIRED`
At the end, provide a concise list of all decisions that require approval before implementation begins.
