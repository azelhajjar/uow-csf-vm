# AP-02 Design: ProFTPD mod_copy to Web-Service Access

## Status

Provisioning is complete and the deployment was live-verified on the reference Ubuntu 26.04 VM. Vulnerable-behaviour and command-execution acceptance testing remain deliberately pending.

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

## Authorisation and Isolation

AP-02 is an intentionally vulnerable service for the university-owned CAV-CSF VM. It must run only on the isolated teaching network. The public `cwscenario.uk` host, the Windows host and university infrastructure are outside scope.

## Teaching Purpose

AP-02 introduces a genuine version-bound service vulnerability rather than another configuration-only path. It supports service fingerprinting, vulnerability research, exploit-condition analysis, web-service interaction, initial host access and evidence-based remediation discussion.

## Architecture

| Component | Deployment | Port | Identity | Purpose |
| --- | --- | ---: | --- | --- |
| ProFTPD 1.3.5 | Source-built under `/opt/cav-csf/ap02/proftpd` | TCP 2121 | `www-data` worker | Deliberately retained `mod_copy` vulnerability |
| Apache with PHP | Ubuntu host package | TCP 80 | `www-data` | Brightleaf warehouse document service and AP-02 web boundary |
| AP-02 web root | `/var/www/brightleaf-ap02` | N/A | writable by `www-data` | Limited destination boundary for the intended path |
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

ProFTPD 1.3.5 is compiled with `mod_copy`, and its worker runs as `www-data`. The AP-02 web root is writable only by that service identity. This intentionally creates the prerequisites for the documented arbitrary file-copy weakness to affect the dedicated AP-02 web boundary.

The design does not make `/var/www`, the administrator home, system configuration or unrelated application directories world-writable.

## Provisioning Contract

`scripts/install-ap02.sh` must:

- require Ubuntu 26.04 and root;
- refuse to replace an unrelated TCP 80 or TCP 2121 listener;
- install only required build and Apache/PHP packages;
- verify the pinned source checksum;
- compile into the dedicated `/opt/cav-csf/ap02` prefix;
- install a dedicated ProFTPD configuration and systemd unit;
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
