# Windows Service Discovery: FTP

## Summary

Anonymous, unauthenticated reconnaissance value of an IIS FTP service on the Windows Server 2019 domain controller `uow-csf-dc` (`192.168.144.200`), running as `Microsoft ftpd` on TCP 21. The service holds a small set of static IT Support reference files, ordinary organisational content rather than a deliberate vulnerability, but anonymous read access to it discloses password-reset contact guidance, department share paths, a new-starter checklist, and department contact names.

## Environment

| Item | Value |
|---|---|
| Target | `192.168.144.200` |
| Domain | `uow-csf.internal` |
| Service | IIS FTP (`Microsoft ftpd`), TCP 21, anonymous access, no database |
| Attacker | Kali VM on the same host-only lab network |

## Lab Dependencies

- Prerequisite: network reachability to `192.168.144.200`; no credential and no prior access required.
- Starting access: none (unauthenticated, anonymous).
- Resulting access: read access to seven static IT Support reference files, organisational reconnaissance value only, not a credential or shell.
- Feeds into: corroborates the department names and share paths already established via `r-19`'s naming convention and `r-22`'s intranet department pages.
- Suggested teaching level: Level 4.

## Reconnaissance

### Service identification

```bash
nmap -p 21 -sV 192.168.144.200
```

```text
PORT   STATE SERVICE VERSION
21/tcp open  ftp     Microsoft ftpd
```

### Anonymous login and directory listing

```bash
curl -v ftp://192.168.144.200/ --user anonymous:anonymous
```

```text
< 220 Microsoft FTP Service
> USER anonymous
< 331 Anonymous access allowed, send identity (e-mail name) as password.
> PASS anonymous
< 230 User logged in.
09-02-26  02:52AM                  273 Department-Contacts.txt
09-02-26  02:50AM                  142 IT-Support-Contacts.txt
09-02-26  02:52AM                  311 New-Starter-IT-Checklist.txt
09-02-26  02:52AM                  330 Password-Reset-Process.txt
09-02-26  02:51AM                  167 Printer-Driver-README.txt
09-02-26  02:51AM                  118 Remote-Access-Guide.txt
09-02-26  02:52AM                  347 Shared-Drives-Guide.txt
< 226 Transfer complete.
```

Anonymous login succeeds without a named domain credential, confirming directory listing access to all seven files; individual file retrieval was expected given Read-only anonymous access, but was not separately captured in this validation pass.

### Access boundary

This service is reconnaissance and information-disclosure only:

- Anonymous login succeeds (see above).
- Directory listing succeeds (see above).
- Individual file retrieval was not separately captured in this validation pass, only the directory listing.
- Anonymous write/upload is not intended by design (Authorization is Read only); this has not yet been empirically tested.
- No credential, shell, privilege change, or chain outcome is gained from FTP alone.

To confirm the upload restriction, run this from Kali:

```bash
echo test > ftp-upload-test.txt
curl -v -T ftp-upload-test.txt ftp://192.168.144.200/ --user anonymous:anonymous
rm ftp-upload-test.txt
```

Expected result: upload denied. This denial should only be recorded as validated once the actual command output is provided.

## Outcome

An anonymous, unauthenticated visitor to the FTP service can log in and list seven IT Support reference files by name, disclosing the existence of password-reset contact guidance, department share paths, a new-starter checklist, and department contact names, all without needing a credential. Individual file retrieval is expected given the service's Read-only anonymous access, but was not separately captured in this validation pass. Alongside `r-19`'s Windows/AD enumeration and `r-22`'s intranet reconnaissance, this is a third independently reachable service corroborating the same organisational naming convention and share layout.

## Teaching Notes

- This is ordinary IT reference content, not a deliberate misconfiguration; the reconnaissance value comes from what an anonymous FTP service naturally discloses once found, not from a bug.
- The department contacts and share paths corroborate `r-22`'s staff directory and the project's existing wordlists, reinforcing the same naming convention across a third service.
- No further access is gained here beyond static file content, this is a reconnaissance addition to the Windows service surface, not a chained exploitation step.
