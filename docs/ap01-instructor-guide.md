# AP-01 Instructor Guide

## Purpose

AP-01 is the first verified CAV-CSF attack path. It provides a short, dependable exercise linking network enumeration, anonymous FTP, credential exposure and reuse, SSH initial access, sudo enumeration and Linux privilege escalation.

This guide contains solution information and must not be issued as the student brief.

## Implemented Path

```text
Anonymous FTP on TCP 21
  -> Brightleaf stockroom handover document
  -> generated stockroom credentials
  -> teaching SSH on TCP 22
  -> NOPASSWD /usr/bin/find
  -> effective UID 0
```

Administrative SSH is a separate key-only service on TCP 22222. The `stockroom` password must fail against it.

## Prerequisites

- The CAV-CSF VM is attached only to the approved isolated teaching network.
- The `AP-01 verified` VMware snapshot exists.
- Instructor administration uses TCP 22222 and an SSH key.
- The student or Kali system can reach the VM on TCP 21 and TCP 22.
- `sudo ./scripts/verify-ap01.sh` returns `RESULT: PASS`.

## Student Starting Information

Provide:

- the authorised target VM address, or the subnet if host discovery is an assessed objective;
- the student brief in `docs/ap01-student-lab.md`;
- assessment evidence and reporting requirements;
- the lab rules of engagement.

Do not provide the generated `stockroom` password. Do not identify the handover filename unless additional scaffolding is required.

## Expected Route

The exact scanning and FTP client commands may vary. The intended observations are:

1. TCP 21 exposes vsftpd with anonymous read access.
2. The anonymous FTP root contains `stockroom-handover.txt`.
3. The document exposes the generated `stockroom` username and password.
4. Those credentials authenticate to teaching SSH on TCP 22.
5. `id` confirms a non-administrative local account.
6. `sudo -l` exposes the exact `/usr/bin/find` NOPASSWD rule.
7. The learner uses the delegated `find` command-execution feature to run a controlled identity check or obtain the intended root shell.

A minimal controlled proof is conceptually equivalent to:

```bash
sudo /usr/bin/find /dev/null -maxdepth 0 -exec /usr/bin/id -u \;
```

Expected output:

```text
0
```

For a shell-based demonstration, students may use the same documented command-execution property, confirm `id`, collect evidence and exit immediately. They must not create persistence or modify administrator material.

## Instructor Validation

Run from the repository root through administrative SSH on TCP 22222:

```bash
sudo ./scripts/verify-ap01.sh
```

The verifier checks:

- FTP listening and safe anonymous-root ownership;
- anonymous retrieval of the clue;
- consistency between the clue and protected credential state;
- teaching SSH authentication;
- rejection of teaching credentials by administrative SSH;
- absence of `sudo` and `adm` group membership;
- exact sudoers syntax and rule scope;
- controlled execution with effective UID 0.

The verifier does not print the active password.

## Reset Between Uses

Run:

```bash
sudo ./scripts/reset-ap01.sh
```

Reset terminates `stockroom` processes, restores its home directory, restores the anonymous FTP clue, reapplies the current generated password, restores the exact sudo rule, restarts the teaching services and runs verification.

The normal reset retains the current generated credential so that the protected instructor state and published clue remain consistent. A fresh install generates a new credential.

## Troubleshooting

### Administrative connection fails

Confirm the client uses TCP 22222 and the administrative private key. Do not weaken teaching SSH or enable the administrator on TCP 22.

### Anonymous FTP returns an access error

Confirm `/srv/ftp` is owned by `root:root` with mode `0755`, then run the reset script. vsftpd refuses an anonymous chroot root that is writable by the anonymous account.

### Teaching SSH is unavailable

Check `cav-csf-teaching-ssh.service` and verify that administrative SSH has not reclaimed TCP 22.

### Verification reports credential inconsistency

Run the reset script. Do not manually copy a password into the repository or student documentation.

### Recovery is uncertain

Keep the TCP 22222 administrative session open. If the documented reset cannot restore the path safely, revert to the `AP-01 verified` VMware snapshot.

## Marking Guidance

Evidence should demonstrate the complete reasoning chain rather than only a root shell. Suggested areas are:

- accurate scope and reconnaissance;
- identification and explanation of anonymous FTP exposure;
- handling of exposed credentials and proof of SSH access;
- correct local and sudo enumeration;
- controlled privilege-escalation evidence;
- risk explanation and remediation quality;
- professional evidence handling and password redaction.

Stronger postgraduate submissions should discuss compound risk, trust-boundary failures, alternative mitigations, monitoring opportunities and why an individually simple weakness can become serious when chained.
