# AP-02 Design: ProFTPD mod_copy to Web-Service Access

## Status

Provisioning is complete and the deployment was live-verified on the reference Ubuntu 26.04 VM. Exploit acceptance testing was completed on 3 August 2026: an anonymous FTP session successfully used `SITE CPFR`/`SITE CPTO` to copy a file into the AP-02 web root, confirmed served over HTTP. See `docs/ap02-instructor-guide.md` for the full transcript and `docs/decisions.md` for the `<Anonymous>` configuration change that testing required.

## Verified Deployment Result

On 1 August 2026, `sudo ./scripts/verify-ap02.sh` passed every non-exploit deployment check on the reference VM:

- the AP-02 binary is installed under the dedicated prefix and reports ProFTPD 1.3.5;
- `mod_copy` is compiled into the binary;
- the dedicated ProFTPD configuration parses successfully;
- `cav-csf-ap02-proftpd.service` is enabled and active;
- ProFTPD listens on TCP 2121;
- Apache is active, listens on TCP 80 and returns the expected Brightleaf page;
- the AP-02 web root has the intended `www-data:www-data` ownership and mode `0750`;
- AP-01 FTP remains available on TCP 21;
- teaching SSH remains available on TCP 22;
- administrative SSH remains available on TCP 22222.

No exploit commands, vulnerable copy operations, payloads or command execution were used during verification. No deployment or compatibility fix was required after installation.

## Exploit Acceptance Testing Result

On 3 August 2026, an instructor-controlled exploit acceptance pass (fresh VMware snapshot taken beforehand) was run from a Kali attacker VM against the reference VM. First attempt: authenticating as the AP-01 `stockroom` account and running `SITE CPFR`/`SITE CPTO` against the web root failed with `550 Permission denied`, because a named (non-anonymous) ProFTPD login is set-uid to its own account, not `www-data` — the `<Anonymous>` context described below was missing from the original configuration. After adding it and re-running `install-ap02.sh`, an anonymous session authenticated, `SITE CPFR index.php` / `SITE CPTO proof.php` returned `250 Copy successful`, and `curl` against `http://.../proof.php` with the `warehouse.brightleaf.test` `Host` header returned the copied page. Full transcript in `docs/ap02-instructor-guide.md`. `scripts/reset-ap02.sh` was run afterward and `verify-ap02.sh` still reports `RESULT: PASS`, confirming the vulnerable condition survives reset.

Secondary observation: `stockroom`'s AP-01 credentials also authenticate against AP-02 (ProFTPD falls back to reading `/etc/shadow` directly since the build uses `--disable-auth-pam`). That session runs as `stockroom` and can use `mod_copy` only within paths `stockroom` already owns (e.g. `/tmp`) — it cannot reach the web root. This is a real but secondary finding, not the headline AP-02 path.

## Authorisation and Isolation

AP-02 is an intentionally vulnerable service for the university-owned CAV-CSF VM. It must run only on the isolated teaching network. The public `cwscenario.uk` host, the Windows host and university infrastructure are outside scope.

## Teaching Purpose

AP-02 introduces a genuine version-bound service vulnerability rather than another configuration-only path. It supports service fingerprinting, vulnerability research, exploit-condition analysis, web-service interaction, initial host access and evidence-based remediation discussion.

## Architecture

| Component | Deployment | Port | Identity | Purpose |
| --- | --- | ---: | --- | --- |
| ProFTPD 1.3.5 | Source-built under `/opt/cav-csf/ap02/proftpd` | TCP 2121 | `www-data` for anonymous sessions (`<Anonymous>` context); named logins run as themselves | Deliberately retained `mod_copy` vulnerability |
| Apache with PHP | Ubuntu host package | TCP 80 | `www-data` | Brightleaf warehouse document service and AP-02 web boundary |
| AP-02 web root | `/var/www/brightleaf-ap02` | N/A | writable by `www-data`; doubles as the anonymous FTP root | Limited destination boundary for the intended path |
| systemd unit | `cav-csf-ap02-proftpd.service` | N/A | root master, configured worker identity | Lifecycle and reboot persistence |

Existing AP-01 vsftpd remains on TCP 21. Administrative SSH remains key-only on TCP 22222, and teaching SSH remains on TCP 22.

## Pinned Component

- Product: ProFTPD 1.3.5.
- Source archive: `proftpd-1.3.5.tar.gz`.
- SHA-256: `c10316fb003bd25eccbc08c77dd9057e053693e6527ffa2ea2cc4e08ccb87715`.
- Build option: `--with-modules=mod_copy`.
- Compiler mode: `CFLAGS='-O2 -std=gnu17'` because Ubuntu 26.04's compiler defaults make `bool` a C23 keyword that conflicts with an identifier in the unmodified 1.3.5 source.
- Relevant issue: CVE-2015-3306.

Provisioning accepts a local archive through `PROFTPD_SOURCE_ARCHIVE`. Otherwise, it downloads the archive to the VM source cache. Every path verifies the SHA-256 before extraction. The verified archive remains cached for the frozen appliance.

## Intended Vulnerable Condition

ProFTPD 1.3.5 is compiled with `mod_copy`. An `<Anonymous /var/www/brightleaf-ap02>` context chroots anonymous sessions to the AP-02 web root and runs them as `www-data`, the same identity that owns the web root. This intentionally creates the prerequisites for the documented arbitrary file-copy weakness to affect the dedicated AP-02 web boundary, with no credentials required.

Named (non-anonymous) logins are authenticated but run as themselves, not `www-data`, so they cannot reach the web root through `mod_copy` — only the anonymous path can. This was confirmed empirically during exploit acceptance testing; see the result above.

The design does not make `/var/www`, the administrator home, system configuration or unrelated application directories world-writable.

## Provisioning Contract

`scripts/install-ap02.sh` must:

- require Ubuntu 26.04 and root;
- refuse to replace an unrelated TCP 80 or TCP 2121 listener;
- install only required build and Apache/PHP packages;
- verify the pinned source checksum;
- compile into the dedicated `/opt/cav-csf/ap02` prefix;
- install a dedicated ProFTPD configuration (including the `<Anonymous>` context required for the intended exploit condition) and systemd unit;
- create the dedicated Apache site and web root;
- preserve AP-01 and administrative SSH;
- run non-exploit verification after installation.

## Reset Contract

`scripts/reset-ap02.sh` removes files introduced into the AP-02 web root, restores the source-controlled Brightleaf page, restores ownership and permissions, restarts only AP-02 services and invokes verification. It does not alter AP-01, SSH configuration or administrator data.

## Verification Boundary

`scripts/verify-ap02.sh` performs health and configuration checks only. It confirms:

- the pinned binary version;
- `mod_copy` is compiled in;
- the ProFTPD configuration parses;
- TCP 2121 is listening;
- the dedicated systemd unit is enabled and active;
- Apache is active and TCP 80 responds with the expected Brightleaf page;
- the AP-02 web root has the intended bounded ownership and permissions;
- AP-01 and administrative ports remain present where already deployed.

It deliberately does not invoke the vulnerable copy commands, place executable content or test command execution. Exploit acceptance testing is a separate instructor-controlled phase.

## Maintenance Boundary

The ProFTPD installation is not managed by `apt` and must not be replaced by a current package. The source archive, checksum, build parameters and resulting binary version must be recorded in the release manifest. Once accepted, the VM release will be frozen and distributed only for isolated teaching use.

## Legacy Review

The legacy script correctly identified ProFTPD 1.3.5 and the `--with-modules=mod_copy` build option. It is not reused because it disables certificate checking, uses an obsolete SysV/Upstart lifecycle, modifies iptables directly, assumes dynamic-IP helper scripts and lacks checksum, reset and verification controls.
