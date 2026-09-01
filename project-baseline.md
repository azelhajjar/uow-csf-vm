# CAV-CSF Master Project Blueprint

**Private maintainer record for the CAV-CSF VM build, validation, integration, and handover state**
**Generated:** 29 August 2026 · **Revised:** 31 August 2026 (project-state reconciliation pass: the Linux master is now recorded consistently as static `192.168.144.100` and already joined to the Windows AD domain; Windows Phase 1 is recorded as complete, with the Windows Server 2019 DC `uow-csf-dc` at `192.168.144.200` for `uow-csf.internal`; stale archive wording that still described `.130`, deferred static migration, incomplete landing-page review, or Phase 1 reproduction in progress has been superseded by the current verified state; split DNS is retained as a deliberate, tested, accepted design; all five web-application platforms are recorded as deployed; delivery of the Linux VM to the lab technician is treated as complete; historical disposable-VM `.13x` testing addresses are preserved only where they document the exploitation evidence trail)

**Source:** This private maintainer repository is the authoritative working record for the CAV-CSF VM build, validation, integration, and handover state. It is not student-facing material. Student-facing content lives inside the supplied VM images and any separate lab materials distributed to students.

**Audience note:** These documents are maintainer-facing. They may include build history, discarded approaches, SecGen provenance, troubleshooting notes, implementation detail, and unresolved technical leads that students are not expected to see. References to the repository, Git, or project documents should be understood as private maintainer workflow unless explicitly described as student-facing output.

**Note on superseded context:** Only this private maintainer repository and its current `docs/` directory describe the current CAV-CSF project state. Older assistant conversations, previous project-store wording, deleted files, and discarded build notes must not be used to infer current architecture, pending work, or file layout.

**Lineage correction:** Earlier CAV-CSF conversations contained a discarded Ubuntu/from-scratch build thread, including ideas such as a separate administrative SSH service, Docker-hosted vulnerable applications on a build VM, milestone reset thinking, and locally hosted web apps on Kali. That thread is not part of the current project state and should not be used as evidence for current architecture or outstanding work. The current baseline is the SecGen-derived Debian 12 VMware Linux VM plus the separate Windows Server 2019 AD DC, with Kali acting only as the attacker/workstation VM.
---

## 1. Project Overview

### 1.1 What CAV-CSF is

CAV-CSF is a deliberately vulnerable virtual infrastructure built for practical cyber security teaching at the University of Westminster. The core deliverable is a Linux VM, hostname `cav-csf-linux` (Debian 12 KDE, generated from SecGen and then substantially modified; since migrated to and maintained directly in VMware Workstation, and later converted to headless for final distribution), now integrated with a working Windows Server 2019 Active Directory domain controller VM (`cav-csf-windows`, in-guest hostname `uow-csf-dc`) and a purpose-registered teaching domain (`cwscenario.uk`) tying both machines into a single fictional organisational scenario. Status as of this revision: the Linux VM carries a full deliberately-vulnerable infrastructure surface plus five deployed web-application training platforms; Windows Phase 1 is complete (AD DS/DNS, OU/user/group scaffolding, validation checks, and client/domain-join testing); the Linux master has joined the AD domain; the Linux landing page has been updated and verified; and the Linux VM has already been supplied to the lab technician. See Section 5 for the current, corrected build/handover status.

The environment is an **authorised, intentionally vulnerable teaching lab under the project owner's own control**, isolated on a host-only VMware network segment (`192.168.144.0/24`) with no route to the internet. The attacker platform is a university-provided Kali VM on the same segment; Kali is now the attacker/workstation VM only, not a host for Docker, sites, or duplicated vulnerable web applications. The student deliverable is the completed VMware VM directory, compressed as a 7-Zip archive and supplied through the lab repository/workflow.

### 1.2 Target audience

University students across three module levels, all working hands-on against the same shared infrastructure at different depths:

- **Level 5** — introductory: reconnaissance fundamentals, service/version enumeration, manual protocol interaction, weak/default credentials, basic information disclosure.
- **Level 6** — intermediate: targeted enumeration, vulnerability validation, credential attacks, local enumeration and privilege escalation, web-application weaknesses, chaining two or more findings.
- **Level 7** — advanced: CVE-based exploitation, multi-stage attack chains, troubleshooting failed tooling, alternative/manual exploitation methods, attack-path reasoning, capstone-style chained RCE work.

The same service is frequently reused across levels (e.g. a service that yields a clean Level 5 enumeration exercise may also anchor a Level 7 chained-exploitation exercise), rather than building separate infrastructure per level.

### 1.3 Core educational goals

- Deliver a **coherent vulnerable infrastructure**, not an unrelated collection of CVEs: remote unauthenticated vulnerabilities, weak/misconfigured network services, information disclosure, credential discovery/cracking/reuse, authenticated attack paths, local privilege escalation (sudo/SUID/cron/filesystem weaknesses), web application targets, DNS/email attack surface, and Windows/AD integration.
- Cover the **full attack lifecycle** as teachable stages in their own right, not only exploitation: host/service discovery, enumeration, vulnerability identification/validation, manual protocol interaction, exploitation, credential attacks, local enumeration, privilege escalation, post-exploitation analysis, and attack chaining.
- Deliberately include **low-privilege dead ends, negative findings, and tool-failure scenarios** alongside full root chains, because real assessments do not resolve every lead into a full compromise. Examples already built: Apache Druid and DistCC footholds with no root path found; a `writable_cron_script` misconfiguration proven *not* exploitable due to parent-directory permissions; a sudo-AWK vector confirmed absent from the provisioned build.
- Teach **empirical validation over assumption**: nothing provisioned by SecGen (or any other automation) is treated as working until independently reproduced from Kali. Automated tool output (Metasploit modules, NSE scripts) is treated as a claim to verify, not a verdict — the project has documented both false negatives (NSE scripts silently missing true findings) and false positives (a Metasploit module claiming a successful login that manual verification disproved).
- Teach **precise technical terminology** throughout (e.g. local privilege escalation vs. pivoting are never conflated).

### 1.4 Governing working method (binding across sessions)

- The user performs all hands-on commands manually against the authorised lab VMs. The assistant does not execute exploitation itself, does not have or need access to Kali/the VM/VMware, and does not fabricate command output, service behaviour, exploit success, privilege level, or evidence.
- The assistant's role: provide reproduction commands, explain expected output/behaviour, interpret pasted-back output, troubleshoot unexpected results, and produce the Markdown write-up once exploitation is actually demonstrated.
- Do not assume a command has executed until the user provides the resulting output; do not progress a decision that depends on output not yet supplied.
- Do not assume a SecGen-provisioned vulnerability works because it exists in the scenario — every intended weakness is tested empirically.
- If a known tool/technique fails, investigate why before concluding the underlying vulnerability is absent (the DistCC/Metasploit and ProFTPD-backdoor/NSE cases are the canonical examples).
- Negative and inconclusive results are retained and documented where they have teaching value, not discarded.
- Existing `.md` write-ups are the authoritative record of completed work; use them rather than reconstructing prior steps from memory.

### 1.5 Master-image change control (binding rule)

All exploitation and validation happens against a **disposable exploitation/test VM**, never the master teaching VM. Every disposable-VM change made during testing must be explicitly classified:

- **SCENARIO CHANGE — replicate to master**: anything needed to make the intended exercise work as designed (a missing service, a vulnerable configuration, a required file/note, a corrected weak permission, an intended credential).
- **EXPLOITATION ARTEFACT — do not replicate to master**: anything produced *as a consequence* of exploiting the test VM (attacker-added sudoers entries, dropped payloads/shells, attacker cron entries, changed group membership, persistence mechanisms).

Outstanding SCENARIO CHANGE items must be tracked and, now that the Linux VM has already been supplied to the lab technician, batched deliberately into any future re-supplied master image rather than treated as pre-handover blockers.

---

## 2. Technical Architecture & Stack

### 2.1 Virtualisation and platform

| Component | Detail |
|---|---|
| Hypervisor | VMware Workstation (definitive platform; migrated off VirtualBox/SecGen tooling) |
| Linux target base | Debian 12 (KDE desktop) |
| Attacker platform | University-provided Kali VM (also VMware-based), used as the attacker/workstation VM; old Kali-hosted Docker/web-app/site material is reference-only and excluded from the current target architecture |
| Network segment | `192.168.144.0/24`, host-only, no internet route (deliberate isolation) |
| Provisioning history | SecGen (`cliffe/SecGen` on GitHub) — retained only for provenance; no longer part of the active workflow |
| Snapshot convention | `CAV-CSF-01-VMware-Clean` (Linux clean migration baseline); `cav-csf-windows-01-clean-server2019-vmtools` (actual Windows clean-install snapshot taken; naming otherwise still to be reconciled with the Linux convention, see Section 5.1) |
| Distribution format | Completed VMware VM directory, compressed as 7-Zip; current Linux image has already been supplied to the lab technician |
| IP addressing policy | Final/master lab addressing is static: Linux master `cav-csf-linux` at `192.168.144.100`; Windows Server 2019 DC `cav-csf-windows` / `uow-csf-dc` at `192.168.144.200` for `uow-csf.internal`. Earlier DHCP/disposable VM addresses (`192.168.144.200`–`.132`) are retained only as historical exploitation/testing evidence in Section 4 |
| Networking cleanup already applied | Reduced from two NICs to one (`eth0`), `GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"`, stale `70-persistent-net.rules` removed, `update-initramfs -u` run, traditional ifupdown (not NetworkManager), `net-tools` installed (`ifconfig` preferred), `/usr/sbin` added to `vagrant` user's PATH |

### 2.2 Vulnerable services on the Linux target (as enumerated)

| Port | Service | Version | Status |
|---|---|---|---|
| 21/tcp | ProFTPD | 1.3.3c (backdoored build) | Exploited — `e-01` |
| 22/tcp | OpenSSH | 9.2p1 Debian 2+deb12u3 | Enumerated (genuine daemon); used for authenticated access throughout |
| 111/tcp | rpcbind | 2–4 | Enumerated — `r-06` |
| 631/udp | CUPS / cups-browsed | 1.28.17-3 (deliberately downgraded, pre-fix) | Exploited — `e-12` (TCP interface loopback-only; UDP-only external surface) |
| 1716/tcp+udp | Unidentified (KDE Connect hypothesis, unconfirmed) | — | Unresolved — `r-11` |
| 2049/tcp | NFS / nfs_acl | 3, 4 | Exploited — `e-02` |
| 2181/tcp | Apache Zookeeper (bundled with Druid) | 3.4.14 | Enumerated — `r-09` |
| 2222/tcp | Erlang/OTP SSH daemon | Erlang/5.1.4.7 | Exploited — `e-03` |
| 3306/tcp | MariaDB | 10.3.23 or earlier | Enumerated only — host-restricted, unexploited — `r-08` |
| 3632/tcp | distccd | v1, Debian 12.2.0-14+deb12u1 | Exploited — `e-06` |
| 4369/tcp | epmd (Erlang Port Mapper) | — | Supporting service for 2222; not independently exploited |
| 8081/tcp | Apache Druid (coordinator/overlord) | 0.20.0 | Exploited — `e-05` |
| 8082/8083/8091/tcp | Apache Druid (broker/historical/middleManager) | 0.20.0 (confirmed) | Enumerated, not independently exploited — `r-10` |
| 8888/tcp | Apache Druid (router) | 0.20.0 | Proxies 8081; not independently exploited |
| 25/tcp | SMTP (Postfix, Debian/GNU) | — | Exploited (misconfiguration, no CVE) — `e-17` |
| 53/tcp+udp | DNS (BIND9) | 9.18.49 | Exploited (misconfiguration, no CVE) — `e-16` |
| 139/tcp, 445/tcp | Samba (smbd/nmbd) | 4.17.12-Debian | Exploited (misconfiguration, no CVE) — `e-13` |
| 161/udp | SNMP (Net-SNMP/snmpd) | 5.9.3 | Exploited (misconfiguration, no CVE) — `e-14` |
| 6379/tcp | Redis | 7.0.15 | Exploited (misconfiguration, no CVE) — `e-15` |

Five services were added to the Linux VM after the original `r-02`/`r-03` baseline scan; `r-02`'s current version records this explicitly with a per-service "added after this scan was originally run" note. All five are pure misconfiguration findings (no CVE, current/patched software throughout), a deliberate contrast with the CVE-driven exploits above — see `docs/services-README.md` for the consolidated cross-service index this project now maintains, and Section 4.1a/4.2a below for full detail.

Local (post-foothold) weaknesses: world-readable `/etc/shadow` (`e-07`), SUID `/usr/bin/nano` (`e-08`), sudo `service *` wildcard/path traversal (`e-04`), world-writable `/usr/lib/backup` feeding a root cron `tar` wildcard job (`e-10`), a writable-but-unreachable cron script (`e-11`, negative), sudo-AWK (`e-09`, negative/not provisioned).

### 2.3 Components: built vs. still open

This subsection is intentionally short — full detail and precise current status for each item now lives in **Section 5**, which supersedes the "planned/in-progress" framing this subsection originally used (several items listed here as design-only or not-yet-added were, in fact, already built; see Section 5 for the correction).

- **Windows Server 2019 Active Directory domain controller** (`cav-csf-windows` / `uow-csf-dc`) — **Phase 1 complete**: AD DS/DNS baseline, OU/user/group scaffolding, validation checks, and client/domain-join testing are done. See Section 5.1 for the full current build state.
- **Five web-application training platforms** (WebGoat, WebWolf, DVWA, OWASP Security Shepherd, OWASP Juice Shop) — **deployed and DNS-mapped** under `uow-csf.internal`. See Section 5.2.
- **Linux student landing page** — updated, deployed at `http://192.168.144.100/`, and verified as served by Apache with title `CAV-CSF Linux Lab Environment`, hostname/IP display, service links, and the GitHub issue-reporting link. See Section 5.4.
- **`cwscenario.uk`**: a real, currently-registered teaching domain intended to give passive-reconnaissance exercises (WHOIS, DNS enumeration, certificate transparency) a genuine, legally-controlled target, and to unify the Linux and Windows/AD VMs into one fictional organisation. Registered but not yet configured with subdomains/DNS records (`r-01`, deferred) — this item's status is unchanged.
- **Linux VM ↔ AD integration**: the Linux master at `192.168.144.100` has been **joined to `uow-csf.internal`** via `realmd`/`sssd`. See Section 5.3 for what's confirmed done versus what the integration-design document still leaves open.
- **SecGen residual cleanup and handover**: audited and substantially remediated (hostname, journal/shell history, mailname/Postfix, filesystem/package residuals); a short list of low-priority items remains. See Section 5.4.
- **Final package/service minimisation**: a documented procedure, **not yet executed** — genuinely still open. See Section 5.5.
- **Five additional deliberately-vulnerable infrastructure services** (Samba, SNMP, Redis, DNS zone transfer, SMTP open relay/user enumeration) — **built, enumerated and exploited**, each with a full `r-`/`e-` pair. See Sections 4.1a/4.2a.
- **`docs/services-README.md`** — a consolidated cross-service index (summary table, per-service detail, the recurring `/srv/backups` breadcrumb, and a known-open-items list) covering all fourteen infrastructure services now documented, not just the five new ones. **`docs/suggestions.md`** — a self-directed "further tools to try" appendix (per-service Kali tooling not used in the guided write-ups, e.g. `enum4linux-ng`, `onesixtyone`, `dnsrecon`, `swaks`), intended for students who have completed the guided activities for a given service.

### 2.4 Tooling used throughout the project

**Reconnaissance / enumeration:** `nmap` (full-range `-p-`, `-sV`, `-sC`, `-O`, `--version-intensity`, `-sU`, targeted NSE scripts), `rpcinfo`, `showmount`, `ping`, `arp-scan`, `nc`/netcat (raw banner grabs and protocol probing), `curl` (including native FTP support), `dig`/`dnsrecon`/`dnsenum`/`whois` (for the DNS work now that `uow-csf.internal` is live), `openssl s_client` (TLS probing).

**Exploitation / credential attacks:** Metasploit Framework (module-driven exploitation and auxiliary scanners — `ftp_anonymous`, `ssh_version`, `mysql_version`/`mysql_login`/`mysql_authbypass_hashdump`, `http_version`, `apache_druid_js_rce`, `apache_druid_cve_2023_25194`, `distcc_exec`, `proftpd_133c_backdoor`, `ssh_erlangotp_rce`), John the Ripper (offline hash cracking against `rockyou.txt`), `impacket` (`GetUserSPNs`, `GetNPUsers` — exercised in `e-18`/`e-19`; `secretsdump` — Phase 2 AD attack tooling, not yet exercised, see Section 5.1), `hashcat` (`-m 13100` Kerberoasting and `-m 18200` AS-REP — both exercised, see `e-18`/`e-19`), GTFOBins-style local privilege-escalation techniques, `journalctl`/`tcpdump` for target-side debug verification (CUPS chain).

**Scripting/automation for exploitation payloads:** Bash (payload scripts, e.g. the tar-wildcard checkpoint payload, SUID-bash chmod payloads), Python (the CUPS-chain PoC IPP server, `0xCZR1/PoC-Cups-RCE-CVE-exploit-chain`, installed via `pip install -r requirements.txt --break-system-packages`).

**Windows/AD tooling (in active use):** PowerShell (`Install-WindowsFeature`, `Install-ADDSForest`, `Rename-Computer`, `New-NetIPAddress`, `Set-DnsClientServerAddress`, `dcdiag`, `w32tm`, `Resolve-DnsName`, `Get-Service`, `Get-Counter`, `nltest`, `net share`, `Get-ADDomain`), Server Manager/ADUC GUI (Desktop Experience is the current install type, not Server Core — see Section 5.1), `powercfg`/registry edits for power/lock-timeout settings.

**Linux ↔ Windows AD integration tooling:** `realmd`, `sssd` (domain join and login), a dedicated `svc-linux-auth` service account for the join itself.

**Web application platform tooling:** Docker Compose (OWASP Security Shepherd — three containers: `secshep_tomcat`, `secshep_mariadb`, `secshep_mongo`), Node.js managed as a systemd service (OWASP Juice Shop, native install, no Docker), Java/Tomcat-based WebGoat/WebWolf, PHP/MariaDB-based DVWA — see Section 5.2.

**Handover/audit tooling:** `journalctl --rotate`/`--vacuum-time`, `hostnamectl`, `dpkg -l`/`dpkg -s`, `find`, `postconf`, `grep`-based residual-string search across `/etc`, `/opt`, `/srv`, `/var/www`, `/home`, `/usr/local/bin` (the SecGen residual audit methodology, Section 5.4), `dpkg -l`/`apt-mark showmanual`/`systemctl list-units`/`ss -tulpn` baseline captures and `apt -s autoremove --purge` dry-runs (final minimisation procedure, Section 5.5, not yet executed).

### 2.5 Documentation format

The project's actual working format throughout its history has been **structured Markdown**, one file per activity, not LaTeX. See Section 3.1 for the established structure and conventions. No LaTeX/TikZ material has been produced within the CAV-CSF project itself to date; Section 3.2 records the user's general standing LaTeX/TikZ style preferences for completeness, in case coursework or lecture material is later produced from this project's content, but these are carried over from the user's broader working style rather than a convention this project has itself established.

---

## 3. Custom Formatting & Code Preferences

### 3.1 Markdown documentation conventions (established within this project)

This is the binding, project-specific convention — every `r-*` and `e-*` file follows it, and it should be preserved exactly when continuing the work in a local editor.

**File naming and numbering:**
- One Markdown file per validated vulnerability, misconfiguration, or reconnaissance activity.
- Exploits: sequential zero-padded numbering, `e-01-...md` through the current `e-12-...md`, in the order exploitation was actually validated (not necessarily attack-chain order).
- Reconnaissance/enumeration activities: `r-01-...md` onward, similarly sequential.
- A file is created **only after** the activity has been successfully demonstrated — never in advance of confirmed results.
- Superseded/duplicate files are deleted outright rather than retained (e.g. an older `sudo-service-path-traversal.md` was removed once `e-04` became canonical).

**Section structure** (not every file needs every section; use what's applicable to the activity):

```
Summary
Environment
Lab Dependencies
Reconnaissance
Enumeration
Vulnerability / Misconfiguration
Vulnerability Identification / Validation
Exploitation
Credential Discovery / Cracking
Local Enumeration
Privilege Escalation
Evidence
Outcome
Remediation
Teaching Notes
```

**`## Lab Dependencies` is mandatory in every file** and should identify, where applicable: prerequisite exploit(s)/activities, required starting access, starting account, resulting access, what the activity feeds into, and a suggested teaching level (e.g. `Level 5`, `Level 6–7`). A scenario is valid documentation even if it produces no shell, no privilege escalation, and no chain continuation.

**Content principles:**
- Write-ups describe what was **actually tested and observed**, never generic instructions copied from external sources.
- A write-up does not need to describe a successful exploit — reconnaissance, enumeration, information disclosure, a negative/inconclusive finding, or a documented tool failure are all valid, first-class content.
- Preserve concrete detail: tools that failed and why (when known), commands that succeeded, the exact account/privilege level obtained, whether a root chain exists, whether an apparent escalation path turned out to be a dead end.
- `Environment` sections use a two-column Markdown table (`| Item | Value |`).
- Command blocks use fenced code blocks (bash/text/powershell as appropriate); raw terminal output is quoted verbatim in its own fenced block directly beneath the command that produced it.
- Attack chains are rendered as simple down-arrow text diagrams inside a fenced block, e.g.:

```text
Erlang/OTP pre-auth RCE
    ->
aberrant_distance
    ->
sudo service wildcard/path traversal
    ->
root
```

- Terminology is precise and consistently enforced: moving from a low-privilege account to root **on the same host** is *local privilege escalation*; using a compromised host to reach another network/segment is *pivoting*. These are never conflated.

### 3.2 General standing LaTeX / TikZ style preferences

These are the user's general, cross-project conventions (not yet applied inside CAV-CSF specifically, since the project's own documentation has been Markdown throughout) — recorded here for completeness in case they become relevant if coursework/lecture material is produced from this content:

- British English; no em dashes (use commas, brackets, or separate sentences).
- Prefer `\textbf{}` over Markdown-style bold when working in LaTeX contexts.
- Keep LaTeX source concise and professional; avoid decorative comment separators, template banners, redundant package comments, and autogenerated formatting clutter.
- Preserve established lecture formatting, terminology, colours, and conventions — refine rather than redesign, and do not introduce new structures/headings/terminology unless requested.
- **TikZ specifically:**
  - Follow the node-based TikZ style defined in the user's own `tikzstyle.txt` reference.
  - Use named nodes and relative positioning (`below of`, `right of`); avoid absolute coordinates where practical.
  - Use `\resizebox` around diagrams where appropriate.
  - Use existing lecture colours/conventions; do not invent new TikZ styles or node definitions unless explicitly requested.
  - Put each node definition on one line; prefer properties written directly on each node over reusable local styles.
  - Use node anchors (`.west`, `.east`, `.north`, `.south`) for precise relative positioning; use `xshift`/`yshift` for minor adjustments.
  - Avoid local node-distance overrides unless explicitly required.

### 3.3 General code and technical-file preferences

- Clean, production-style Python; minimise unnecessary dependencies.
- Preserve existing code structure unless a change is genuinely necessary; explain any structural change made.
- Comments only where they carry real technical value — no decorative separators, banner comments, placeholder text, motivational comments, or autogenerated clutter.
- `pip install` in this environment requires `--break-system-packages` (as used for the CUPS-chain PoC dependencies).

---

## 4. Historical Breakthroughs & Scenarios

This section consolidates every validated finding, in the order the reconnaissance-to-exploitation lifecycle actually establishes them. Full technical detail (exact command sequences, complete raw tool output, extended teaching discussion) lives in the individual project `.md` files, which remain the authoritative record — this is a synthesis for orientation, not a replacement.

### 4.1 Reconnaissance and enumeration phase

- **`r-01` — Passive reconnaissance (deferred).** Originally scoped as not applicable (the target has no public footprint, addressed purely by internal IP). Superseded by the registration of `cwscenario.uk` as a dedicated teaching domain to eventually support genuine WHOIS/DNS/certificate-transparency exercises and unify the Linux and Windows/AD VMs into one fictional organisation. Domain is registered but not yet configured; activity remains a placeholder pending that work.
- **`r-03` — Host discovery** (file `r-03- host-discovery.md`). ICMP ping (`ttl=64`, consistent with Linux) and `arp-scan` across the `/24` segment confirmed the target live and enumerated all hosts on the lab segment (attacker, target, master reference VM, VMware gateway/NAT infrastructure).
- **`r-02` — Full reconnaissance and service enumeration** (file `r-02- reconnaissance-and-service-enumeration.md`, titled internally "Activity 12"). The foundational activity: `nmap -p- -T4` (full 65535-port sweep, deliberately unbiased before any service-specific work) followed by `nmap -sC -sV -O` and a UDP top-ports sweep. Established the complete confirmed attack surface (table in Section 2.2). Documented RPC ephemeral-port drift (only the RPC *program number* via `rpcinfo`/NSE is a stable identifier between scans) and a red-herring OS fingerprint (nmap's `-O` guessed MikroTik RouterOS; the host is genuinely Debian 12). Its current, larger version adds a **Service Summary** table cross-referencing all five newly added services (Samba, SNMP, Redis, DNS, SMTP) against this original baseline, each annotated "added after this scan was originally run." *(Note: `r-02` and `r-03`'s numbers and subject matter are swapped relative to what a strictly sequential reading would suggest — recorded here exactly as the project's own filenames have them rather than silently renumbered.)*
- **`r-04` — FTP banner grab and anonymous access enumeration.** Confirmed anonymous FTP login is independently permitted (distinct from the `e-01` backdoor). Anonymous read access exposed a deliberately planted `note` file that is a scripted cross-service breadcrumb pointing toward the NFS share (`e-02`). Documented a significant NSE detection gap: three of four FTP-specific NSE scripts (`ftp-anon`, `ftp-syst`, `ftp-proftpd-backdoor`) produced no output despite the underlying conditions being true; Metasploit's `ftp_anonymous` module correctly detected what the NSE script missed, isolating the failure to that specific script rather than automated FTP enumeration in general.
- **`r-05` — SSH banner comparison (ports 22 and 2222).** Distinguished the genuine OpenSSH 9.2p1 daemon (port 22) from the unrelated Erlang/OTP SSH implementation (port 2222) purely through banner grabbing, verbose client negotiation, and NSE (`ssh2-enum-algos`, `ssh-hostkey`, `ssh-auth-methods`). Port 2222 lacks post-quantum key exchange, offers the legacy `3des-cbc` cipher, and uses a distinctive `keyboard-interactive` custom prompt — all correctly flagged as a different implementation before `e-03` exploitation confirmed it.
- **`r-06` — RPC/NFS enumeration.** `rpcinfo`/`showmount` and their NSE equivalents (`rpcinfo`, `nfs-showmount`, `nfs-ls`, `nfs-statfs`) confirmed the single export `/srv/backups *` (no host restriction). `nfs-ls`/`nfs-statfs` demonstrated a genuine capability advantage over the manual `mount`-then-`find` workflow, retrieving listing, permissions, and filesystem stats without mounting locally.
- **`r-07` — distccd enumeration.** Manual protocol probing correctly returned nothing (distcc's binary wire format doesn't answer naive text probes). A broad `--script default,discovery` pass **crashed nmap outright** (an `nse_nsock.cc` assertion failure) due to subnet-wide broadcast scripts pulled in by the `discovery` category despite a single-target scope — an important operational-safety lesson in its own right. A properly scoped `--script default` pass completed cleanly; the dedicated `distcc-cve2004-2687` NSE script (categorised `exploit`/`intrusive`/`vuln`, not a passive check) then both detected and self-demonstrated command execution (`uid=121(distccd)`).
- **`r-08` — MySQL/MariaDB enumeration.** Every method tried (raw `nc`, the `mysql` client, `nmap -sV`, `mysql-info`, `mysql-empty-password`, `mysql-vuln-cve2012-2122`, and three Metasploit auxiliary modules) consistently confirmed the service enforces host-based access control that rejects the attacker's source IP before authentication is even reachable. One exception: Metasploit's `mysql_login` module produced an internally contradictory result (simultaneously "skipped — unsupported version" and "1 credential successful"); direct manual verification confirmed this was a false positive. MariaDB remains unexploited.
- **`r-09` — Zookeeper enumeration.** No NSE tooling exists for Zookeeper at all; enumeration relied entirely on Zookeeper's plaintext "four-letter word" admin commands (`ruok`, `stat`, `envi`). `envi` disclosed the full Java classpath and confirmed this Zookeeper instance is not standalone — it is bundled with and launched by the Apache Druid installation (same `druid` user, same `/usr/local/apache-druid` install directory), directly linking two previously separately-enumerated ports.
- **`r-10` — Apache Druid HTTP enumeration.** Direct `curl` comparison across all five Druid ports confirmed 8081/8888 are the coordinator/router (both redirect to `unified-console.html`) and 8082/8083/8091 are functioning-but-console-less broker/historical/middleManager processes (404, no redirect) — converting an earlier inference into a confirmed finding. Three NSE HTTP scripts (`http-title`, `http-headers`, `http-methods`) again produced no output despite manual `curl` succeeding, reinforcing the project's broader NSE-reliability pattern. A second, distinct Druid vulnerability was identified via Metasploit module discovery — **CVE-2023-25194** (JNDI injection RCE) — but its exploitability check was inconclusive (no LDAP callback observed) and remains an open, untested lead.
- **`r-11` — Port 1716 investigation.** An honestly unresolved finding. Maximum-intensity `nmap -sV --version-intensity 9`, a raw `nc` probe, a TLS handshake attempt (actively rejected, TLSv1.3 ClientHello sent but no ServerHello), and a UDP-side check all failed to positively identify the service. The KDE Connect hypothesis (plausible given the KDE desktop) was neither confirmed nor ruled out — no KDE Connect NSE script exists, and a raw TLS probe isn't a protocol-correct test of KDE Connect's plaintext-then-TLS-upgrade handshake. Retained explicitly as a documented open item, not a forced conclusion.
- **`r-12` — CUPS print service reconnaissance.** Confirmed `cupsd`'s TCP interface is loopback-only (invisible to external TCP scans) while `cups-browsed`'s UDP control socket (631/udp) is reachable externally. A crafted four-field legacy CUPS browse packet, sent unauthenticated via `nc -u`, triggered an outbound `Get-Printer-Attributes` IPP callback to an attacker-specified URL — confirming the CVE-2024-47176 precondition for the full chain.
- **`r-13` — CUPS discovery after IP change (192.168.144.100 → .132).** Following a VM re-clone, re-established the full baseline against the new address and used `cups-browsed` debug logging (`DebugLogging file stderr`) plus `tcpdump` to obtain definitive log-level evidence of the full unauthenticated queue-creation/callback sequence — stronger confirmation than the raw HTTP callback alone, and the direct motivation for using a real IPP server (rather than raw sockets) in the full exploitation chain. **All CUPS-related work after this point uses `192.168.144.100`.**

### 4.1a Reconnaissance of the five newly added services

All five recon activities below share the same target (`192.168.144.100`), attacker (`192.168.144.129`), and starting position (no prerequisite exploit, no credentials). Each precedes and directly motivates its `e-1x` exploitation counterpart in Section 4.2a.

- **`r-14` — Samba share reconnaissance.** Full re-scan confirmed `139/tcp`/`445/tcp` as new since the `r-02` baseline. Dedicated Samba NSE scripts were mixed: `smb-protocols` correctly reported dialects up to 3.1.1, but `smb-enum-shares`, `smb-os-discovery` and `smb-vuln-cve-2017-7494` all produced nothing despite the underlying conditions being true (the now-familiar NSE-reliability pattern from `r-04`/`r-12`). Manual `smbclient -L //.../ -N` reliably listed four shares (`print$`, `HR-Shared`, `IPC$`, `nobody`); `HR-Shared` was confirmed both **readable and writable** by a fully anonymous guest connection (`smbclient //.../HR-Shared -N`, then `put`/`get`), containing two files with genuinely sensitive-looking names (`Staff_Rota_Sept2026.txt`, `Staff_Directory.csv`). Suggested teaching level 5.
- **`r-15` — SNMP enumeration.** Confirmed `161/udp` new since baseline. Unlike several other services in this project, the dedicated SNMP NSE scripts (`snmp-processes`, `snmp-netstat`, `snmp-interfaces`, `snmp-sysdescr`) worked reliably and cross-validated Metasploit's `snmp_login` (guessed community string `public` on the first attempt) and `snmp_enum` (full process listing, including active `uow-admin` SSH sessions). A custom `NET-SNMP-EXTEND-MIB` OID walk recovered a breadcrumb note ("Backup rotation moved to `/srv/backups`") — an independent, protocol-unrelated corroboration of the same lead already discoverable via the FTP `note` file (`r-04`/`e-02`). `sysName` also discloses `PRINT-SRV-01.cwscenario.uk`. Suggested teaching level 5.
- **`r-16` — Redis enumeration.** Confirmed `6379/tcp` new since baseline. The `redis-info` NSE script worked cleanly on the first attempt, directly confirming `bind 0.0.0.0` and the connected-client list. `redis-cli -h ... ping`/`info server` confirmed a fully unauthenticated connection (Redis 7.0.15), and `KEYS *` enumerated three keys whose names alone are informative: `session:admin:token`, `app:config:db_password`, `queue:print_jobs`. Content interpretation deferred to `e-15`. Suggested teaching level 5.
- **`r-17` — DNS enumeration.** Confirmed `53/tcp`+`53/udp` new since baseline, running BIND9 9.18.49 authoritative for `uow-csf.internal`. A single unauthenticated `dig @... uow-csf.internal AXFR` (corroborated by the `dns-zone-transfer` NSE script) disclosed the complete zone in one query — nine records, including the historical Linux-zone record `dc01.uow-csf.internal → 192.168.144.200`. That address now corresponds to the built Windows Server 2019 DC, whose actual hostname is `uow-csf-dc`; the old `dc01` label is retained here as historical exploitation evidence and discussed as a low-priority naming inconsistency in Section 5.3. The same transfer also disclosed two currently-unreachable hosts, `vpn-internal` (`.150`) and `backup-legacy` (`.151`), confirmed unreachable via a full-port `nmap` sweep of both addresses. Suggested teaching level 5.
- **`r-18` — SMTP enumeration.** Confirmed `25/tcp` new since baseline, Postfix (Debian/GNU). `smtp-open-relay` NSE gave a clean, reliable 16/16-test positive. `smtp-enum-users` needed correct `unpwdb`-style `userdb=` argument syntax (an initial `smtp-enum-users.userdb=` guess silently fell back to the script's generic default wordlist) — and, once correctly configured, still produced a **genuine false positive**: a deliberately fake negative-control username (`nonexistentuser123`) was reported as valid alongside the three genuinely real accounts (`analyst`, `webops`, `backupsvc`), resolved only by manual `RCPT TO` confirmation via raw `nc`. This is a documented script bug, not an argument-naming problem, a useful contrast with the resolvable `smtp-enum-users.userdb` issue earlier in the same activity. Suggested teaching level 5–6.

### 4.1b Windows/AD reconnaissance

- **`r-19` — Windows/AD enumeration** (file `r-19-windows-ad-enumeration.md`). Unauthenticated and low-cost reconnaissance against the Windows Server 2019 domain controller `uow-csf-dc`, independently confirming the domain name, the DC's real hostname, and the reachable AD service set via `nmap`, DNS SRV records, and an anonymous LDAP RootDSE query — none assumed in advance from the stale `dc01` record `r-17` disclosed. Confirmed anonymous RPC/SMB enumeration is denied on this build, a useful contrast with the Linux Samba misconfiguration (`e-13`). Kerberos pre-authentication error codes validated 8 of 24 candidate usernames as real domain accounts, and a targeted wordlist spray against `analyst` recovered a working domain credential on the Phase 1 baseline convention. Feeds directly into `e-18`.

### 4.2 Validated exploitation chain (Linux VM)

| # | Title | CVE / mechanism | Start → result | Chain position |
|---|---|---|---|---|
| `e-01` | ProFTPD 1.3.3c supply-chain backdoor | Metasploit `exploit/unix/ftp/proftpd_133c_backdoor` | Unauthenticated network access → **root shell directly** | Standalone; no privesc needed |
| `e-02` | Anonymous NFS credential exposure | Unrestricted `/srv/backups *` export; files disclose `backupsvc` credential | Unauthenticated → SSH as `backupsvc` | Deliberately low-privilege; feeds `e-10` and the shadow-cracking chain |
| `e-03` | Erlang/OTP SSH pre-auth RCE | **CVE-2025-32433**, Metasploit `exploit/linux/ssh/ssh_erlangotp_rce` | Unauthenticated → shell as `aberrant_distance` | Feeds directly into `e-04` |
| `e-04` | sudo `service *` wildcard/path traversal | `NOPASSWD: /usr/sbin/service *`; Debian wrapper doesn't restrict path traversal (e.g. `../../usr/bin/id`) | `aberrant_distance` → **root** | Completes Chain A (see below) |
| `e-05` | Apache Druid CVE-2021-25646 | JavaScript execution vuln, Metasploit `exploit/linux/http/apache_druid_js_rce` | Unauthenticated → shell as `druid` | Standalone RCE-to-low-priv; no root path found |
| `e-06` | distcc CVE-2004-2687 | Metasploit module **failed**; Nmap NSE `distcc-cve2004-2687` succeeded (reverse shell) | Unauthenticated → shell as `distccd` | Standalone; no root path found; canonical "tool failure ≠ not vulnerable" example |
| `e-07` | World-readable `/etc/shadow` + cracking | John the Ripper + `rockyou.txt` (~4 seconds) | Low-priv foothold → recovered `webops:administrator`, `analyst:password` | Bridges any low-priv foothold to SSH as `webops`/`analyst` |
| `e-08` | SUID `/usr/bin/nano` privileged file write | GTFOBins shell-spawn technique **fails** (Nano 7.2 drops privilege before exec); Nano's own file I/O retains euid 0 | `analyst` → edited `/etc/sudoers` directly → **root** | Root obtained here is reused as the access basis for `e-09`, `e-10`, `e-11` |
| `e-09` | sudo AWK | Negative finding — direct `/etc/sudoers`/`sudoers.d` inspection confirms no such rule exists on this build | N/A | Confirms absence rather than leaving unresolved |
| `e-10` | Tar wildcard cron privilege escalation | World-writable `/usr/lib/backup`; root cron `tar -zcf ... *`; GNU tar `--checkpoint`/`--checkpoint-action=exec=` argument injection via crafted filenames | `backupsvc` → **root** (SUID `/bin/bash`, `bash -p`) | Second, independent root chain from the NFS foothold |
| `e-11` | Writable cron script | Negative finding — `/root/.config/cron.sh` is `0777` but `/root` itself is `0700`, blocking traversal for any non-root account | N/A | Paired teaching contrast with `e-10` (file vs. directory permission scope) |
| `e-12` | CUPS full RCE chain | **CVE-2024-47176 + CVE-2024-47076 + CVE-2024-47175 + CVE-2024-47177** chained: unauth UDP trigger → unsanitised IPP attributes → unsanitised PPD generation → injected `FoomaticRIPCommandLine` executed by `foomatic-rip` | Unauthenticated → command execution as the `cups-browsed` process user (contingent on a print job being sent to the malicious queue) | Level 7 capstone; uses `0xCZR1/PoC-Cups-RCE-CVE-exploit-chain` (Python) rather than hand-crafted IPP |
| `e-13` | Samba guest-writable share | No CVE — `guest ok`/`guest only`/`writable = yes` on `HR-Shared`, plus global `map to guest = Bad User` | Unauthenticated guest → read (staff directory/rota) and write (file-planting) access to `HR-Shared` | Standalone misconfiguration; no shell |
| `e-14` | SNMP community string disclosure | No CVE — default `rocommunity public default -V all`, `agentaddress` open to all interfaces | Unauthenticated → full MIB read, live process enumeration, `/srv/backups` breadcrumb | Corroborates/alternate route into `e-02`'s NFS chain; no shell directly |
| `e-15` | Redis unauthenticated data exposure | No CVE — `bind 0.0.0.0` + `protected-mode no`, no `requirepass` | Unauthenticated → full read/write; recovered session token (session-hijack primitive) and `app:config:db_password` (unconfirmed credential-reuse lead against MariaDB, `r-08`) | Standalone; credential lead into `r-08`, not itself followed through to a MariaDB login (MariaDB rejects Kali's source IP regardless, per `r-08`) |
| `e-16` | DNS zone transfer | No CVE — `allow-transfer { any; }` in `named.conf.local` | Unauthenticated → full internal zone disclosure (nine records, incl. historical `dc01` record pointing at the current DC address) | Standalone; corroborates `e-12`/`e-13`'s shared-host naming; no shell |
| `e-17` | SMTP open relay and user enumeration | No CVE — `mynetworks` widened to the full `/24`; `mydestination` includes `uow-csf.internal` enabling `RCPT TO` enumeration | Unauthenticated → confirmed open relay (spoofed mail queued to an unrelated external domain) + 3 confirmed real accounts (`analyst`, `webops`, `backupsvc`); mailbox content itself requires a prior shell as `analyst` (via `e-02`+`e-07`) | Corroborates the account set from `e-02`/`e-07`/`e-08`/`e-10`; fourth independent route to the `/srv/backups` breadcrumb once `analyst` is compromised |

**Chain A (validated, complete):**
```text
Erlang/OTP pre-auth RCE (e-03)
    -> aberrant_distance
    -> sudo service wildcard/path traversal (e-04)
    -> root
```

**Chain B (validated, complete):**
```text
NFS anonymous credential exposure (e-02)
    -> backupsvc
    -> world-readable /etc/shadow + offline cracking (e-07)
    -> SSH as analyst/webops
    -> SUID Nano privileged file write (e-08)
    -> root
```

**Chain C (validated, complete, independent of Chain B's final step):**
```text
NFS anonymous credential exposure (e-02)
    -> backupsvc
    -> tar wildcard cron privilege escalation (e-10)
    -> root
```

**Standalone, deliberately non-chained exercises:** `e-01` (root directly), `e-05` (Druid → `druid`, no further escalation found), `e-06` (DistCC → `distccd`, no further escalation found), `e-12` (CUPS chain, own unauthenticated RCE not dependent on any other exploit), `e-13`/`e-14`/`e-15`/`e-16` (Samba/SNMP/Redis/DNS — each a self-contained misconfiguration finding with no shell obtained), `e-17` (SMTP relay/enumeration standalone; its mailbox-content sub-finding is a dependent extension of Chain B, not a new chain).

### 4.2a The five new services: a deliberate no-CVE contrast, and a fourth route to the same breadcrumb

Samba, SNMP, Redis, DNS and SMTP were added specifically to give the project a coherent set of **pure misconfiguration** findings, distinct in kind from the CVE-driven exploits in the table above: in every one of the five, the installed software is current and functioning exactly as designed, and the entire "attack" is standard, unmodified client tooling (`smbclient`, `snmpwalk`, `redis-cli`, `dig`, raw `nc`) used against a service that was never configured to require authentication, or that leaks more than it should by design choice rather than by bug. `docs/services-README.md` is the consolidated index across all fourteen infrastructure services (the nine CVE/access-control findings from Section 4.2 plus these five), and is the right starting point for a reader who wants the full current service inventory in one place rather than reconstructing it from individual `r-`/`e-` files.

A specific design point worth preserving: the NFS-derived `backupsvc` credential lead (`e-02`) is now independently discoverable through **four** separate, unrelated channels rather than two — the original FTP `note` file (`r-04`), the SNMP `NET-SNMP-EXTEND-MIB` breadcrumb (`r-15`/`e-14`), the SMTP-delivered internal email readable only post-compromise of `analyst` (`e-17`), and the naming-convention consistency visible across CUPS/Samba/DNS records once the DNS zone is transferred (`r-17`). This is deliberate: real environments often leak the same sensitive reference through multiple, unrelated services, and `services-README.md` calls this out explicitly as a recurring cross-service breadcrumb rather than four coincidentally similar findings.

Two further points specific to this batch: SNMP (`r-15`) is the one service in this batch where the dedicated NSE script family worked reliably rather than failing silently, a useful counter-example to the FTP/CUPS/Samba NSE-gap pattern documented elsewhere; and SMTP (`r-18`/`e-17`) is the only one of the five with a genuine NSE **false positive** (as opposed to a false negative), making it a distinct teaching case from the rest of the project's NSE-reliability findings, which are otherwise uniformly about scripts under-reporting rather than over-reporting.

### 4.2b Validated exploitation: Windows/AD Phase 2 credential attacks

Two Phase 2 AD credential attacks have been built and validated against the master Windows domain controller, `uow-csf-dc` (`192.168.144.200`), building on the reconnaissance in `r-19`. Kept as a separate table from the Linux VM's exploitation chain above (Section 4.2), since these are Windows/AD-specific, reached through Kerberos, and not part of the Linux service surface.

| # | Title | CVE / mechanism | Start → result | Chain position |
|---|---|---|---|---|
| `e-18` | Kerberoasting: `svc-web` service account | No CVE — SPN registered on `svc-web` (`HTTP/uow-intranet.uow-csf.internal`), password policy-compliant but predictable | Authenticated domain user (`analyst`, from `r-19`) → recovered second domain credential, `svc-web` | Standalone credential exposure; no further chain built yet |
| `e-19` | AS-REP roasting: `helpdesk01` account | No CVE — `DoesNotRequirePreAuth` set on `helpdesk01`, password policy-compliant but predictable | Unauthenticated (valid username only) → recovered third domain credential, `helpdesk01` | Standalone credential exposure; no further chain built yet |

Both recovered credentials were independently confirmed via a freshly issued Kerberos TGT and an authenticated SMB session (`SYSVOL` read), not inferred from the offline crack alone. Neither account carries elevated rights in the current build, so neither yields administrative access to the DC; both are domain credential exposure findings, distinct in kind from the Linux VM's local-privilege-escalation chains in Section 4.2.

### 4.3 Recurring teaching motifs established across the project

- **Automated tooling is a claim, not a verdict** — demonstrated in both directions: NSE false negatives (`ftp-anon`, `ftp-proftpd-backdoor`, `ftp-syst`, all three Druid HTTP scripts, and partially `smb-enum-shares`/`smb-os-discovery`/`smb-vuln-cve-2017-7494` in `r-14`) and false positives from two independent tools (Metasploit's `mysql_login`, and nmap's own `smtp-enum-users` in `r-18`, which reported a deliberately fake negative-control username as valid even after its argument-syntax issue was correctly resolved). The correct response each time was independent cross-verification with a different tool or manual protocol interaction, not blind trust or blanket dismissal of automation.
- **Tool/technique failure does not prove absence of a vulnerability** — the DistCC Metasploit-vs-NSE case is the canonical example, explicitly reused as the teaching frame for the later ProFTPD NSE gap.
- **File permissions must be evaluated across the whole directory path, not in isolation** — the `e-10`/`e-11` pairing (identical crontab, identical Puppet provisioning origin, only one actually exploitable) is the project's dedicated exercise for this.
- **Negative and inconclusive findings are retained deliberately** — `e-09` (confirmed absent), `e-11` (confirmed blocked), `r-11` (genuinely unresolved), and Druid's CVE-2023-25194 (inconclusive check) are all kept as first-class documentation rather than omitted for not "succeeding."
- **Environmental factors can shape a tool's result independent of the target** — the `ftp-bounce` NSE result was inconclusive specifically because the lab's deliberate host-only isolation prevented the script's intended external test target from resolving.
- **Cross-service breadcrumbs are designed deliberately** — the FTP `note` file intentionally points toward the NFS share; enumeration findings are meant to connect into a coherent narrative rather than remaining isolated per-port results.

---

## 5. Build, Integration & Handover Status (current, corrected)

This section reflects the actual current state, using the project's build/design/handover documents (`docs/w-01-windows-ad-baseline-design`, `docs/ad-integration`, `docs/linux-handover-checklist`, `docs/secgen-audit`, `docs/webapps-README`, `docs/final-linux-vm-optimisation`) as evidence while correcting their stale points where later project work superseded them. This is a separate, later work-stream from the reconnaissance/exploitation record in Section 4, which remains accurate to the disposable-VM testing it documents.

Important reconciliation rule: the archived source notes still contain a few older status phrases, for example the Linux master still being on a disposable `.13x` address, static migration still being deferred, landing-page review still being incomplete, and Windows Phase 1 reproduction still being in progress. This blueprint resolves those contradictions in favour of the current state supplied for this revision: Linux is final/static at `.100`, the AD join works, Windows Phase 1 is complete on `.200`, the landing page has been updated and verified, and the Linux VM has already been handed over.

### 5.1 Windows AD domain controller — Phase 1 complete

The design document `docs/w-01-windows-ad-baseline-design.md` was itself revised in-project; the earlier Server Core / `dc01` / `UOW-CSF` design (originally captured in this blueprint) is explicitly superseded and is background only. Note that the superseded `dc01` hostname still survives in the Linux BIND9 zone as an A record pointing at `192.168.144.200`, which is now a live naming inconsistency because the built DC answers as `uow-csf-dc` — see Section 5.3.

**Current, confirmed facts:**

| Item | Value |
|---|---|
| VMware VM name | `cav-csf-windows` |
| Windows hostname | `uow-csf-dc` |
| FQDN | `uow-csf-dc.uow-csf.internal` |
| Domain | `uow-csf.internal` |
| NetBIOS name | `UOWCSF` (no hyphen) |
| Install type | Windows Server 2019 Standard, evaluation media, **Desktop Experience** (Server Core is a fallback only, triggered by a measured memory-headroom checkpoint, not the default as previously documented) |
| Forest/domain functional level | Windows Server 2016 (ceiling for a 2019-only forest) |
| Static IP | `192.168.144.200` |
| Clean-install snapshot | `cav-csf-windows-01-clean-server2019-vmtools` |
| Phase 1 status | Complete: AD DS/DNS installed, forest/domain promoted, OU/user/group scaffold built, validation checks passed, and client/domain-join testing completed |

**Phase 1 (AD DS/DNS baseline): complete, passed, and validated.** Confirmed via `dcdiag /v`, `nltest /dsgetdc`, SRV/DNS resolution, `Get-Service` (ADWS/DNS/Kdc/Netlogon/DFSR all running), `SYSVOL`/`NETLOGON` shares present. Memory checkpoints are also complete: Checkpoint A (no AD roles) 767 MB available; Checkpoint B (AD DS/DNS idle) 659 MB available (~1.36 GB used, under the 1.7 GB fallback-to-Server-Core threshold) — Desktop Experience held.

**OU/user/group scaffolding: built**, matching the design exactly — 5 OUs (`Users`, `Groups`, `Service Accounts`, `Computers` under `OU=UOW-CSF`), 7 users (`analyst`, `mpatel`, `jreed`, `skhan`, `helpdesk01`, `svc-web`, `backup.operator`), 5 groups (`Lab-Students`, `IT-Helpdesk`, `Web-Services`, `Backup-Operators-Lab`, `Staff-Admin` [unpopulated placeholder]), 4 populated memberships. **Two Phase 2 vulnerable properties have been applied**: an SPN on `svc-web` (Kerberoastable, `e-18`) and `DoesNotRequirePreAuth` on `helpdesk01` (AS-REP roastable, `e-19`). No description-field content or ACL changes have been applied to any account — the remaining scaffolding is still clean Phase 1, with naming chosen to anticipate where further Phase 2 weaknesses will likely attach. Phase 1 baseline password convention: `CavLab2026!` (a deliberate build/testing convention, to be revised during Phase 2 vulnerability design, not an accidental weakness).

Power/lock-timeout settings applied permanently (`powercfg`/registry, based on prior 2008-server experience). Windows 7 and Windows 10 client domain joins have been confirmed working end to end (tested account: `uowcsf\analyst`, DNS resolved correctly via domain join with no manual override).

**No Windows Phase 1 build item remains open in this blueprint.** The remaining Windows/AD work is post-Phase-1 work: the lab segment remains static-addressed rather than DHCP-backed; the tested Windows 10 client needed `192.168.144.237` configured statically. The Windows-hosted website component is still undecided (Section 5.2 covers the role versus implementation choice); Phase 2 AD vulnerability design is partially built: Kerberoasting (`svc-web`, `e-18`) and AS-REP roasting (`helpdesk01`, `e-19`) are built and validated on the master DC; `DnsAdmins`/DCSync abuse remain design-proposed only, with worked-example commands recorded in `w-01` section 10, not built or validated; snapshot-naming reconciliation with the Linux VM's convention remains open; licensing still needs final settlement (180-day eval versus university channel); and a shared NTP time source for Kali/the Linux VM should be decided before cross-machine Kerberos exercises are added, since clock skew can silently break exploitation attempts.

Any older note saying the `.200` DC was merely a forward reproduction target is now stale. The built Phase 1 DC is the `.200` machine, and the Windows 7/Windows 10 client-domain-join evidence belongs to that completed Phase 1 baseline.

### 5.2 Web application training platforms: deployed

Five platforms are live and DNS-mapped under `uow-csf.internal` (records alongside the infrastructure service records in `db.uow-csf.internal`) — this corrects the earlier incomplete web-platform framing entirely. Any archive wording that still treats `192.168.144.100` as only the intended future web-app address is stale; `.100` is now the final Linux master address:

| Platform | Port | DNS record | Notes |
|---|---|---|---|
| WebGoat | 8080/tcp | `webgoat.uow-csf.internal` | Guided, lesson-based, one vulnerability class at a time; Level 5–6 |
| WebWolf | 9090/tcp | `webwolf.uow-csf.internal` | Simulated attacker-side infra (mailbox/file server) for WebGoat lessons needing a second party |
| DVWA | 8090/tcp | `dvwa.uow-csf.internal` | Adjustable difficulty (low/medium/high/impossible); default creds `admin`/`password` |
| OWASP Security Shepherd | 8543/tcp (HTTPS only, self-signed cert) | `shepherd.uow-csf.internal` | Gamified/competitive, scoreboard + class/team system; Level 7. Runs via **Docker Compose** (`secshep_tomcat`, `secshep_mariadb`, `secshep_mongo`) — this is how the earlier native-install dependency failure (`tomcat9`/`openjdk-11-jdk` mismatch on Debian 12) was actually resolved. Admin `admin`/`password` (forced change on first login); student `student`/`student`, class "2026 uow-class" |
| OWASP Juice Shop | 3000/tcp | `juiceshop.uow-csf.internal` | Modern Node.js/Angular app, in-app scoring, no default admin — self-registration is itself part of the intended challenge set. Native install (not Docker), managed as a systemd service |

All five are self-contained training curricula with their own built-in lessons/guidance and deliberately have **no bespoke `r-`/`e-` reconnaissance or exploitation write-ups** in this project — separate lab materials are used for them, distinct from the deliberately-vulnerable infrastructure services documented in Section 4's `r-`/`e-` files.

The DNS infrastructure this table depends on (`uow-csf.internal`, `db.uow-csf.internal`) is therefore also confirmed live, correcting the earlier open-item wording around DNS service availability.

The Windows-hosted website (Section 5.1's "website component") is a **separate, still-undecided post-Phase-1 item**: the *role* is agreed (a reconnaissance/initial-access bridge into the AD environment — staff names, department/group-matching naming, internal hostnames, breadcrumbs toward `uow-csf-dc.uow-csf.internal` — not a general OWASP-style playground duplicating the five platforms above), but the *implementation* is an open choice between a lightweight IIS/custom intranet (current lean, lowest resource cost), WordPress (IIS + PHP/FastCGI + tuned MariaDB, only justified if a specific plugin-CVE teaching objective needs it), or another lightweight option. The Phase 1 memory-headroom checkpoint has already passed; the remaining website decision depends on the Phase 2 AD objects and attack paths the site is meant to support.

### 5.3 Linux VM ↔ Windows AD integration

**Confirmed done** (per the handover checklist): the master Linux VM (`cav-csf-linux`) is on static `192.168.144.100` and has been **successfully joined to `uow-csf.internal`** via `realmd`/`sssd`, using a dedicated `svc-linux-auth` service account; login and home-directory auto-creation both confirmed working.

Older `.130`/`.132` references in the archive are build/test history unless they appear in Section 4 as disposable-VM exploitation evidence. They no longer describe the master VM's current address.

**Split DNS authority for `uow-csf.internal` — deliberate, tested, accepted.** The Linux VM runs BIND9 authoritative for `uow-csf.internal`, serving both the infrastructure service records and the five web-application records in `db.uow-csf.internal`; the Windows DC holds an AD-integrated primary zone for the same name, auto-populated with the SRV records AD requires. Both machines therefore hold the zone. This was briefly recorded as a blocking conflict during a documentation review, on the basis of configuration analysis alone; **empirical testing settled it in the other direction** — all five web-application platforms were confirmed working with the Windows VM powered off, and the Linux VM resolves its own zone without depending on the DC.

The teaching pattern makes this the correct trade-off rather than a compromise. Students work on the Linux VM alone for the great majority of the curriculum; the Windows VM appears in one Level 6 module and one Level 7 module. Optimising the Linux VM for standalone operation matches actual use. The consequence to keep in mind is simply that AD SRV lookups are served by the DC, so Kerberos-dependent exercises driven from the Linux side need the Windows VM running — expected, for the two modules that use it. Any future change here must preserve the deliberate `allow-transfer { any; }` misconfiguration, since `e-16` depends on it entirely.

A related, smaller item: the Linux zone advertises `dc01.uow-csf.internal → 192.168.144.200`, inherited from the earlier DC naming plan. The DC now exists at that address but answers to `uow-csf-dc`, so the address is right and the name is wrong. Low priority, and since the Linux VM has already been supplied to the lab technician (Section 5.4), correcting it would mean re-supplying the image — so the realistic options are to retain `dc01` as a deliberately stale legacy record, which is realistic and teachable in its own right, or fold a correction into a future scheduled re-supply.

**Still open**, after the successful join: which specific Linux services should carry additional breadcrumbs pointing toward AD; whether Kerberos/LDAP/SSSD-based exercises belong in the core lab or as an advanced extension; whether any SMB integration should be Linux→Windows, Windows→Linux, or both; and whether Kali and both VMs should share an NTP source before cross-machine Kerberos activities are added.

### 5.4 SecGen residual audit and handover cleanup

A dedicated read-only audit methodology (`docs/secgen-audit.md`) was defined first — search targets (`secgen`, `vagrant`, `puppet`, `scenario.xml`, etc.) across both the repository and VM filesystem locations (`/etc`, `/opt`, `/srv`, `/var/www`, `/home`, `/usr/local/bin`, MOTD/banner/systemd locations), with a strict report-first-then-approve workflow (no edits during the audit itself) and a four-way classification (`keep` / `remove` / `rename-reword` / `investigate`).

**Completed remediation**, per the handover checklist:

- Journal history cleared (`journalctl --rotate` + `--vacuum-time=1s`; freed 334.3M), removing old boot records referencing the SecGen-inherited double-prefixed hostname.
- Current hostname confirmed clean (`hostnamectl`/`/etc/hostname` both show `cav-csf-linux`, no SecGen prefix) — permanent, not just a log-cleanup artefact.
- Shell history cleared for `uow-admin`, `student`, and `root`.
- `erlang-otp-prebuilt` package **reviewed and deliberately kept**: its `dpkg` description string still references SecGen, but the package is load-bearing for the deliberate `e-03` Erlang OTP SSH RCE scenario (`erlang-otp-ssh-rce.service` confirmed running cleanly, listening on 2222, no SecGen reference in the unit/process itself). Editing `/var/lib/dpkg/status` directly was assessed as non-durable (any future `apt` operation would overwrite it) and low-visibility (only surfaces via package-metadata inspection, not service enumeration or banners) — left as-is, treated the same as the project's existing stance that SecGen is acknowledged as historical provenance in documentation.
- No filesystem paths/directories named after SecGen anywhere (`find / -iname "*secgen*"` clean beyond the one package name above).
- `/etc/mailname` and Postfix `mydestination` fixed (both carried the old double-prefixed hostname; reset and restarted, confirmed clean).
- No disposable-range (`.13x`) IP references remaining under `/etc`, `/var/www`, `/opt`.
- Student landing page updated and verified at `http://192.168.144.100/`: `/var/www/html/index.html` is served by Apache, owned by `www-data:www-data`, mode `0644`, with browser title `CAV-CSF Linux Lab Environment`, visible host/IP context for `cav-csf-linux`, service links for the five web applications, appropriate fixed credentials where the app genuinely uses them, no fixed Juice Shop credential hint, and the GitHub issue-reporting link present.

**Still open, low priority:** git reflog entries in `/var/www/dvwa/.git/logs/` and `/opt/SecurityShepherd/.git/logs/` still reference the old SecGen-prefixed hostname — internal git history, not student-facing, left as-is (clearable with `truncate -s 0` if a fully clean state is later wanted).

**Delivery status: the Linux VM has been supplied to the lab technician** for the lab repository. This reframes everything below. The remaining items are no longer pre-handover tasks but changes that would require re-supplying an image already in the lab repository, so they should be batched into a scheduled re-supply and weighed against the disruption of replacing it. Functionally the delivered image is sound — the web-application platforms are confirmed working standalone with the Windows VM off, and the landing page has been updated and served successfully.

**Student-facing polish status:** the landing page wording/colours, service list, visible Linux hostname/IP, and GitHub issue-reporting link have been reviewed and updated. Remaining polish candidates for a future re-supply are narrower: login banner/MOTD content, any other visible on-VM notes that mention old hostnames or SecGen-generated wording, and any visible references that should now point to `uow-csf-dc.uow-csf.internal` / `uow-csf.internal` rather than older names.

**Handover cleanup, remaining items:** temp/scratch files appear already handled during the build itself (not independently re-verified this session); browser/download artefacts not yet checked; final confirmation that no credentials/screenshots/logs/notes are left in student-visible locations not yet independently verified beyond the items above.

### 5.5 Final package/service minimisation: documented procedure, not yet executed

A conservative, staged procedure is defined in `docs/final-linux-vm-optimisation.md`, to run only after Linux configuration, Windows AD integration, and headless conversion are all complete and validated. Linux configuration and headless conversion are done, and the Linux master has joined the Windows AD domain with the DNS arrangement now tested and accepted (Section 5.3); Windows AD Phase 1 is complete, while Phase 2 vulnerable AD attack paths do not exist yet. Two things push this further down the queue: the procedure's own regression testing explicitly covers Windows AD integration and cross-VM attack paths, so running it before Phase 2 exists would validate against an incomplete attack-path target and need repeating; and the Linux VM has already been supplied to the lab technician, so any minimisation would now require re-supplying the image and should be batched with the remaining handover polish rather than done on its own. The procedure itself has **not yet been executed** — it remains a forward plan, not a completion record:

1. Remove administrative/build history (shell/editor histories, temp install scripts, copied config fragments, leftover credentials/notes) across all accounts used during development, while explicitly preserving anything that is part of the intended teaching scenario (deliberately exposed credentials, reconnaissance breadcrumbs, scenario configuration files, logs required by a practical activity).
2. Capture a full baseline before any package removal (`dpkg -l`, `apt-mark showmanual`, running/enabled services, `ss -tulpn`, `free -h`, `df -h`).
3. Identify cleanup candidates (residual KDE/graphical packages left over from the headless conversion, unused display-manager components, obsolete kernels, dev/build packages, caches) without assuming a package is safe to remove just because no service is currently running against it — explicit awareness list includes Docker, Java, PHP/Apache, MariaDB, CUPS, Samba, DNS, SMTP, Redis, SNMP, NFS/RPC, Kerberos, LDAP, SSSD, SMB/AD integration, and future Windows AD attack paths.
4. Treat `apt -s autoremove --purge` as a proposal to review, never an operation to run blind.
5. Low-risk storage cleanup (`apt clean` and reviewed caches) only after package decisions are settled.
6. Full regression testing after each removal stage (boot, `eth0`, SSH, DNS, all listeners/services, all web apps, scheduled jobs, local privesc scenarios, deliberately-retained vulnerable package versions, Windows AD integration, cross-VM attack paths), always on the disposable VM first.
7. Only removals that pass regression testing get replicated to the master, classified `SCENARIO CHANGE — replicate to master` per the project's existing master-image change-control rule (Section 1.5), followed by a final functional regression pass on the master before packaging for distribution.

### 5.6 Current open work after reconciliation

This is the corrected outstanding-work list after removing stale pre-handover and Phase 1 language:

- **Windows/AD Phase 2**: Kerberoasting (`svc-web`, `e-18`) and AS-REP roasting (`helpdesk01`, `e-19`) are built and validated. `DnsAdmins` abuse and DCSync-style escalation remain design-proposed attack paths, unbuilt and unvalidated. AD CS remains a possible later Phase 3 direction, not part of the current built baseline.
- **Windows-hosted website/intranet**: role agreed as an AD reconnaissance/initial-access bridge, but implementation remains undecided and should be driven by Phase 2 account, group, host, and breadcrumb design.
- **Static lab networking / DHCP**: the lab currently uses static addressing. DHCP is not part of the completed baseline, and Windows client addressing remains manual unless a later teaching need justifies DHCP.
- **Time synchronisation**: decide a shared NTP/time source for Kali, Linux, and the Windows DC before Kerberos-heavy cross-machine exercises are added.
- **Linux AD breadcrumbs**: decide which Linux services should reveal or imply AD accounts, hostnames, Kerberos/LDAP/SSSD configuration, or cross-platform trust relationships.
- **DNS naming mismatch**: `dc01.uow-csf.internal` still points to `192.168.144.200`, but the built DC hostname is `uow-csf-dc`; retain deliberately as a stale legacy record or correct in a future re-supplied Linux image.
- **Linux re-supply candidates**: low-priority git reflog cleanup, login banner/MOTD review, browser/download artefact check, final student-visible credential/screenshot/log review, and the final package/service minimisation procedure.
- **Infrastructure-service open leads**: Apache Druid CVE-2023-25194 remains inconclusive, port 1716 remains unidentified, the Redis `db_password` lead remains unvalidated because MariaDB rejects the attacker's source before authentication, and `cwscenario.uk` passive reconnaissance remains registered-but-unconfigured.

---

## 6. Working Context and Scope Statement

This project's content — reconnaissance methodology, exploit reproduction steps, and vulnerability write-ups — documents work performed against infrastructure the user owns and controls: an isolated, host-only, non-internet-routed VMware lab built specifically for authorised university teaching, with every exploit independently validated by the user's own hands-on testing before being written up. Nothing in this document describes, or is intended to enable, unauthorised access to any system outside that lab.

On one point in the original request, this document does not include what was asked for: a standing instruction, framed as a "CVP paradigm" credential, directing any AI assistant that reads this file to disable its own safety judgement when generating vulnerable lab code or exploit material. There is no such recognised Anthropic exemption framework, and I don't write instructions — for myself or for a future assistant reading this file in a local editor — that say "stop applying judgement here." It wouldn't actually buy anything: the technical content in Sections 2–4 already stands on its own as legitimate, well-documented security-education material, and every substantive piece of it was produced without needing such a clause. If a specific future request gets an unwarranted refusal despite the clearly academic, authorised framing this document establishes, that's worth flagging in the moment against the actual content, rather than pre-authorising a blanket bypass now.

---

*End of Master Project Blueprint. The documents under `docs/` (`r-01` through `r-19`, `e-01` through `e-19`, and the build/design/index set — `w-01-windows-ad-baseline-design`, `ad-integration`, `linux-handover-checklist`, `secgen-audit`, `webapps-README`, `final-linux-vm-optimisation`, `services-README`, `suggestions`) remain the authoritative record for exact commands, full raw tool output, and extended teaching discussion; this blueprint is a synthesis for orientation, not a replacement for them.*

*Keeping this current: the repository is now the store, so durable content produced in a session should be committed here as it is produced rather than held elsewhere. When a build milestone lands, update both the relevant source document and the corresponding Section 5 entry in the same pass — the stale design-only framing corrected in this revision arose precisely because those two were updated at different times.*
