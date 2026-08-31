# Services README — CAV-CSF Linux VM

A consolidated overview of every service running on this VM, its status (vulnerable, misconfigured, or hardened/not exploitable), and links to the relevant reconnaissance/exploitation activity files. Intended as a quick-reference index; see the individual `r-`/`e-` files for full technical detail, evidence, and remediation guidance.

Target addressing note: this README describes the master CAV-CSF Linux VM. The master VM is currently on its final static address, `192.168.144.100`. The Windows domain controller is a separate static host at `192.168.144.200`.
---

## Summary Table

| Service | Port(s) | Status | Class | Files |
|---|---|---|---|---|
| ProFTPD | 21/tcp | **Vulnerable** | CVE (backdoor RCE) | `e-01`, `r-04` |
| SSH (OpenSSH) | 22/tcp | Hardened | — | `r-05` |
| RPC/NFS | 111/tcp, 2049/tcp | **Misconfigured** | Anonymous export, credential exposure | `e-02`, `r-06` |
| Erlang/OTP SSH | 2222/tcp | **Vulnerable** | CVE-2025-32433 (RCE) | `e-03`, `r-05` |
| MySQL/MariaDB | 3306/tcp | Hardened | Host-restricted, not exploitable | `r-08` |
| distccd | 3632/tcp | **Vulnerable** | CVE-2004-2687 (RCE) | `e-06`, `r-07` |
| Zookeeper | 2181/tcp | Informational only | Bundled Druid dependency, no independent finding | `r-09` |
| Apache Druid | 8081, 8082, 8083, 8091, 8888/tcp | **Vulnerable** | CVE-2021-25646 (RCE); CVE-2023-25194 unconfirmed | `e-05`, `r-10` |
| Port 1716 | 1716/tcp+udp | Unidentified | Investigated, inconclusive | `r-11` |
| CUPS / cups-browsed | 631/udp (UDP only; TCP loopback-only) | **Vulnerable** | CVE-2024-47176/47076/47175/47177 chain (RCE as `lp`) | `e-12`, `r-12`, `r-13` |
| Samba | 139/tcp, 445/tcp | **Misconfigured** | Guest-writable share, no CVE | `e-13`, `r-14` |
| SNMP | 161/udp | **Misconfigured** | Default community string, no CVE | `e-14`, `r-15` |
| Redis | 6379/tcp | **Misconfigured** | No authentication, no CVE | `e-15`, `r-16` |
| DNS (BIND9) | 53/tcp+udp | **Misconfigured** | Unrestricted zone transfer (AXFR), no CVE | `e-16`, `r-17` |
| SMTP (Postfix) | 25/tcp | **Misconfigured** | Open relay + user enumeration, no CVE | `e-17`, `r-18` |

## Privilege-Escalation Chain (local, post-foothold)

| Finding | Status | Files |
|---|---|---|
| `sudo service *` wildcard | **Vulnerable** | `e-04` |
| Readable `/etc/shadow` | **Vulnerable** (credential cracking) | `e-07` |
| SUID `nano` | **Vulnerable** | `e-08` |
| `sudo` AWK rule | Not provisioned (negative finding) | `e-09` |
| Tar wildcard cron job | **Vulnerable** | `e-10` |
| Writable cron script (`/root/.config/cron.sh`) | Not exploitable — blocked by `/root` directory permissions (negative finding) | `e-11` |

---

## Per-Service Detail

### ProFTPD 1.3.3c — Vulnerable (CVE backdoor)
Backdoored release, unauthenticated root RCE via a hidden command sequence. Also has a separate, independent misconfiguration: anonymous login enabled, disclosing a breadcrumb note pointing to the NFS export below.

### SSH (OpenSSH) — Hardened
Current OpenSSH build, no anomalies. Compared directly against the Erlang SSH service on port 2222 (below), which merely shares the same protocol, not the same software.

### RPC/NFS — Misconfigured
`/srv/backups` exported with no host restriction (`*`). Contains `backup.conf`, disclosing the `backupsvc` credential, the starting point for the entire low-privilege exploitation chain on this VM. Independently rediscoverable via the FTP note, the SNMP-extended breadcrumb, and the SMTP-delivered internal email (see below).

### Erlang/OTP SSH — Vulnerable (CVE)
CVE-2025-32433, pre-auth RCE in the Erlang SSH daemon library, distinct software from OpenSSH despite listening on a similar port and speaking the same wire protocol.

### MySQL/MariaDB — Hardened
Enforces host-based access control (`Host` grant table restriction); every connection attempt from Kali is rejected before authentication is even reached. Confirmed via five independent tools/methods. No exploitable finding on this VM.

### distccd — Vulnerable (CVE)
CVE-2004-2687, weak-configuration RCE via arbitrary compiler invocation. Notable for a Metasploit module (`distcc_exec`) failing where manual/NSE exploitation succeeds, a documented tool-reliability finding.

### Zookeeper — Informational only
Not independently vulnerable; confirmed (via its own `envi` diagnostic command) to be Druid's own embedded coordination service, running as the `druid` user from Druid's install directory, not a standalone target.

### Apache Druid — Vulnerable (CVE), with an open lead
CVE-2021-25646 (JavaScript engine RCE) fully exploited. A second, distinct vulnerability, CVE-2023-25194 (JNDI injection), was identified via Metasploit module search but its exploitability check was inconclusive; recorded as an open item, not confirmed either way.

### Port 1716 — Unidentified
Investigated (manual protocol probing, maximum-intensity nmap version detection, TLS handshake test, UDP check). Several hypotheses (including KDE Connect) tested and neither confirmed nor fully ruled out. Genuinely unresolved; recorded honestly rather than forced to a conclusion.

### CUPS / cups-browsed — Vulnerable (CVE chain)
Deliberately downgraded to `1.28.17-3` (pre-September-2024-patch) specifically to reintroduce CVE-2024-47176/47076/47175/47177. Full chain validated end-to-end: RCE confirmed as the `lp` user (not root — CUPS drops privileges before invoking print filters, a structural, designed boundary). Packages held (`apt-mark hold`) to prevent accidental re-patching. Scenario content: a legitimate `HR-LaserJet-2F` print queue with a completed job, separate from the exploit-generated queue.

### Samba — Misconfigured (no CVE)
Current Samba version (4.17.12), fully patched; the finding is purely configuration (`guest ok`/`guest only`/`writable` on the `HR-Shared` share, plus `map to guest = Bad User` globally). Contains a staff directory and rota file as scenario content.

### SNMP — Misconfigured (no CVE)
Default `public` community string with `view all` (rather than the restrictive default `systemonly`) and `agentaddress` opened to all interfaces. Discloses full process listing and a custom `NET-SNMP-EXTEND-MIB` breadcrumb note pointing to `/srv/backups`.

### Redis — Misconfigured (no CVE)
`bind 0.0.0.0` and `protected-mode no`, no `requirepass` set. Contains a live-looking session token (session-hijacking primitive) and an application database password (unconfirmed credential-reuse lead against MariaDB, which rejects Kali's connections regardless).

### DNS (BIND9) — Misconfigured (no CVE)
Serves `uow-csf.internal` (deliberately `.internal`, not `.local`, to avoid the mDNS reservation conflict) with `allow-transfer { any; }`. A full AXFR discloses every hostname, including `dc01` at `192.168.144.200` and two currently-unreachable breadcrumb hosts (`vpn-internal`, `backup-legacy`).

The `dc01` record was written as a forward-looking breadcrumb while the Windows AD VM was still unbuilt. That VM now exists at `192.168.144.200`, but its actual hostname is `uow-csf-dc`, so the address is correct while the name is not. Two open items follow from this and are tracked below: the `dc01` name itself, and the fact that this BIND9 instance and the DC's AD-integrated zone now both claim authority for `uow-csf.internal`.

### SMTP (Postfix) — Misconfigured (no CVE)
`mynetworks` widened to the full lab subnet (open relay, demonstrated by successfully queuing mail to an unrelated external domain) and `mydestination` includes `uow-csf.internal` (enables reliable `RCPT TO`-based user enumeration, though `VRFY` itself is unreliable on this Postfix build, a documented tool-behaviour finding). A legitimate internal email was delivered locally to `analyst`'s mailbox; this is **not** part of the unauthenticated attack surface, it requires a prior shell as `analyst` to read.

---

## Recurring Cross-Service Breadcrumb: `/srv/backups`

The same underlying lead (the NFS export containing the `backupsvc` credential) is independently discoverable through four separate services, a deliberate design choice demonstrating that real environments often leak the same sensitive reference through multiple, unrelated channels:

1. FTP anonymous access → `note` file (`r-04`)
2. SNMP `NET-SNMP-EXTEND-MIB` custom breadcrumb (`r-15`)
3. SMTP-delivered internal email, readable only post-compromise of `analyst` (`e-17`)
4. Naming convention consistency across CUPS/Samba/DNS records referencing shared infrastructure

## Known Open Items

### Accepted design characteristics

- **Split DNS authority for `uow-csf.internal`.** This VM's BIND9 instance is authoritative for the zone (that authority is the entire basis of `e-16`), and the Windows DC also holds an AD-integrated primary zone for the same name. **Tested and accepted, not a defect.** All five web application platforms were confirmed working with the Windows VM powered off, which is the normal state for the great majority of teaching use: students work on the Linux VM alone except in one Level 6 and one Level 7 module. The Linux VM keeps serving its own zone and does not depend on the DC being reachable. No change is planned, and none should be made without a specific reason, since the Linux VM has already been supplied to the lab technician for the lab repository.
- **`dc01` versus `uow-csf-dc`.** The zone advertises `dc01.uow-csf.internal → 192.168.144.200`; the built DC answers to `uow-csf-dc`. The address is correct, the name is not. Low priority and cosmetic in effect, but it should be an explicit choice rather than unnoticed drift: either correct the record, or retain `dc01` deliberately as a stale/legacy entry, which is realistic in its own right. Note that changing it now means re-supplying the Linux VM, so the realistic options are "retain and document" or "fold into the next scheduled re-supply."

### Unresolved technical leads

- **CVE-2023-25194** (Druid JNDI injection) — identified, not confirmed exploitable
- **Port 1716** — service identity unresolved
- **Redis `app:config:db_password`** — recovered in `e-15`, untested as a credential-reuse lead because MariaDB rejects Kali's source address before authentication (`r-08`)

### Deferred build work

- **`cwscenario.uk` passive reconnaissance** — deferred pending domain/subdomain configuration (`r-01`)
- **Final package/service minimisation** — procedure documented in `final-linux-vm-optimisation.md`, not yet executed

Windows AD status is no longer tracked here; see `w-01-windows-ad-baseline-design.md` for the built Phase 1 baseline and `ad-integration.md` for the cross-VM integration state.
