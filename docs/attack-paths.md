# Attack Paths

## Purpose

This document defines the deliberate attack paths implemented in the CAV-CSF VM. Each path must have a teaching purpose, a controlled starting condition, a reproducible outcome, a reset contract and automated verification.

Design approval does not mean that a path is already installed. The status field distinguishes proposed, approved, implemented and verified work.

## Safety Boundaries

- The public `cwscenario.uk` host is OSINT-only and is never an exploitation target.
- Administrative SSH and teaching SSH use separate configurations.
- Administrative SSH moves to a protected management port before teaching SSH claims TCP 22.
- Administrative SSH uses key-only authentication, restricts permitted users and must not accept teaching credentials.
- Teaching accounts must never receive administrator SSH keys, instructor credentials or access to instructor-only files.
- Deliberate weaknesses must be limited to documented teaching files, accounts and services.
- Every implemented path must be resettable and independently verifiable.
- A clean VMware snapshot remains the recovery boundary for unintended host damage.

## AP-01: FTP Clue to Teaching SSH to Root

Status: IMPLEMENTED AND LIVE-VERIFIED on the reference Ubuntu 26.04 VM.

Teaching material:

- `docs/ap01-student-lab.md` provides the student-facing exercise without the solution.
- `docs/ap01-instructor-guide.md` provides delivery, validation, reset and marking guidance.

Difficulty: introductory to intermediate.

Primary learning outcomes:

- enumerate an FTP service;
- identify anonymous access;
- inspect exposed organisational files;
- recognise credential exposure and reuse;
- authenticate to SSH;
- enumerate sudo privileges;
- exploit an unsafe sudo rule;
- collect evidence of initial access and privilege escalation.

### Starting Conditions

- The student can reach the isolated VM network.
- The student knows the VM IP address or discovers it through the lab setup.
- No instructor or administrator credentials are required.

### Stage 1: FTP Discovery

The VM exposes a maintained FTP implementation with intentional modern misconfiguration:

- anonymous read access is enabled;
- the anonymous root contains plausible Brightleaf Retail Ltd operational material;
- an onboarding or handover document exposes a low-privilege teaching username and password;
- anonymous users cannot access host configuration, administrator material or arbitrary filesystem paths;
- anonymous upload, if added later, must use a non-executable isolated directory and is not required for AP-01.

Expected outcome: the student obtains credentials for the dedicated `stockroom` teaching account.

Credential values must not be committed to the public repository. Provisioning creates the active teaching credential and renders it into both the FTP clue and the instructor manifest.

### Stage 2: Teaching SSH Access

Teaching SSH listens on TCP 22 through a separate OpenSSH configuration and systemd unit. It permits password authentication only for explicitly listed teaching accounts.

The `stockroom` account:

- is an unprivileged local teaching user;
- has no administrator group membership;
- has no access to administrator SSH keys or instructor files;
- has a resettable home directory;
- can authenticate only through the teaching SSH configuration;
- provides a genuine host shell for Linux enumeration and privilege-escalation exercises.

Expected outcome: the student gains an interactive low-privilege host shell as `stockroom`.

### Stage 3: Unsafe Sudo Rule

The `stockroom` account can run `/usr/bin/find` as root without a password. This deliberately unsafe rule supports a reliable introductory privilege-escalation exercise based on `sudo -l` enumeration and command execution through `find`.

The sudoers rule must be stored in a dedicated file under `/etc/sudoers.d/`, owned by root, mode `0440`, and validated with `visudo -cf` before installation.

Expected outcome: the student demonstrates effective UID 0 and gains a root shell through the approved route.

This route is intentionally direct. More realistic chained and indirect privilege-escalation routes will be separate paths so AP-01 remains suitable for introductory teaching.

## Administrative SSH Migration Gate

Teaching SSH must not be enabled on TCP 22 until all of these checks pass:

1. administrative SSH is configured on the approved management port;
2. root login and password authentication are disabled for administrative SSH;
3. the administrator account is explicitly allowed;
4. a new administrative SSH session succeeds on the management port;
5. the existing TCP 22 administrative session remains open during testing;
6. rollback instructions have been tested locally from the VM console;
7. verification confirms that teaching credentials fail against administrative SSH.

If any gate fails, TCP 22 remains assigned to administrative SSH and AP-01 deployment stops.

## Reset Contract

The AP-01 reset process must:

- restore the FTP anonymous directory from a source-controlled template;
- render the current generated teaching credential into the intended clue;
- remove student-created FTP files outside any explicitly retained upload exercise;
- restore the `stockroom` home directory from a clean template;
- terminate active `stockroom` sessions and processes;
- restore the intended account password and group memberships;
- restore the approved teaching SSH configuration;
- restore the exact sudoers rule and permissions;
- leave administrative SSH configuration and administrator keys unchanged;
- run AP-01 verification after reset.

Reset must restore the vulnerable state; it must not remove the intentional anonymous access, credential exposure or unsafe sudo rule.

## Verification Contract

Automated verification must report clear PASS or FAIL results for:

- FTP is listening on its approved port;
- anonymous FTP login succeeds;
- the expected clue file is readable;
- the clue contains the currently provisioned teaching username without exposing it in test output;
- teaching SSH is listening on TCP 22;
- `stockroom` can authenticate through teaching SSH using the instructor-side credential source;
- teaching credentials fail against administrative SSH;
- `stockroom` is not in administrative groups;
- `stockroom` cannot read administrator SSH keys or instructor-only files;
- the dedicated sudoers file passes `visudo -cf`;
- `sudo -l -U stockroom` contains only the intended AP-01 rule plus explicitly documented defaults;
- a controlled non-interactive proof confirms the intended sudo route executes with effective UID 0;
- no unrelated service account receives the AP-01 sudo rule;
- reset restores all expected AP-01 state.

Verification output must never print active passwords, private keys or complete instructor manifests.

## Rollback and Recovery

Before AP-01 installation:

- confirm the Phase 2 clean-base VMware snapshot exists;
- preserve a working VM console or administrative SSH session;
- back up the active administrative SSH configuration locally on the VM;
- validate all generated OpenSSH and sudoers configuration before service reload.

If teaching SSH or FTP deployment fails, disable only the new teaching unit and restore the previous administrative SSH configuration. If host access or package state cannot be recovered safely, restore the clean-base VMware snapshot.

## AP-01 Deployment Procedure

The implementation is split at the administrative SSH safety gate:

1. Choose an unused management port from 1024 to 65535, excluding 22.
2. Run `sudo scripts/configure-admin-ssh.sh prepare PORT`. This retains TCP 22 while adding the management port and enforcing key-only administrative access.
3. Keep the existing session open and confirm a second administrative session succeeds on the management port.
4. From the original or tested session, run `sudo scripts/configure-admin-ssh.sh finalize PORT` and type the required confirmation. This releases TCP 22.
5. Keep the tested management session open and run `sudo scripts/install-ap01.sh`.
6. Run `sudo scripts/verify-ap01.sh` after installation and `sudo scripts/reset-ap01.sh` between cohorts or exercises.

The AP-01 installer refuses to run before the migration marker exists, before the recorded administrative port is listening, or while TCP 22 remains occupied.
The migration script disables Ubuntu's default `ssh.socket` activation and enables the standalone `ssh.service`, because socket activation otherwise binds only the first configured administrative port.

## Deferred Paths

The following paths remain proposed and require their own detailed contracts before implementation:

- SMB guest share to credential or document discovery;
- published PostgreSQL to application-data extraction;
- NFS weak export to controlled file access;
- custom web application to database or host access;
- SUID binary privilege escalation;
- writable privileged service or timer privilege escalation;
- cross-platform Active Directory paths;
- CTF-only multi-stage paths.

## AP-02: ProFTPD mod_copy to Web-Service Access

Status: INSTALLED AND LIVE-VERIFIED FOR PROVISIONING, CONFIGURATION AND SERVICE COEXISTENCE. EXPLOIT ACCEPTANCE TESTING PENDING.

AP-02 uses a pinned, host-native ProFTPD 1.3.5 build with `mod_copy` on TCP 2121 and a dedicated Apache/PHP boundary on TCP 80. This is a genuine version-bound vulnerability retained for the isolated university lab. See `docs/ap02-design.md` for the architecture, safety boundary, reset contract and verification scope.

Exploit execution is deliberately outside the provisioning verifier and remains a later instructor-controlled acceptance phase.
