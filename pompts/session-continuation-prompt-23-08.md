# CAV-CSF Exploitation Session — Continuation Prompt

We are continuing hands-on exploitation and lab documentation for the CAV-CSF deliberately vulnerable Linux VM (cyber security teaching environment, University of Westminster).

## Working method (unchanged, important)

- I (the user) run all commands manually on Kali against the target VM and paste the output back.
- Claude does not execute anything itself, gives commands/guidance, interprets output, and writes the Markdown documentation once an exploit is confirmed working.
- A dedicated `.md` write-up is created for every successfully exploited vulnerability or misconfiguration, covering: summary, environment, vulnerability mechanism, reconnaissance, exploitation steps, evidence, privilege escalation check (if applicable), outcome, and remediation.
- Files are numbered sequentially in the order exploited (`01-...md`, `02-...md`, etc.) and produced as downloadable files.

## Important environment clarification

The box being exploited in this session (`192.168.144.131`, hostname `cav-csf-linux`) is a **disposable test instance** used purely to validate exploits before they go into the teaching materials. It is not the master/production VM that will be distributed to students. This means:

- It's fine to leave persistent changes on it (e.g. `analyst ALL=(ALL) NOPASSWD:ALL` was appended to its `/etc/sudoers` during exploit 8 and was deliberately left in place).
- Any "reset before distribution" guidance in the write-ups applies to whoever later builds or resets the actual master image, not to this working test box.
- We can keep reusing this same test box for further exploitation without worrying about contaminating a production artefact.

## Confirmed exploits so far (8 total, all documented)

**Initial access / remote, no privilege needed to start:**

1. `01-proftpd-1.3.3c-backdoor.md` — ProFTPD 1.3.3c supply-chain backdoor (CVE-2010-20103), direct unauthenticated root via Metasploit `exploit/unix/ftp/proftpd_133c_backdoor`.
2. `02-nfs-anonymous-credential-exposure.md` — anonymous NFS export of `/srv/backups` discloses `backupsvc` credentials, SSH foothold (uid 1001). SUID nmap tested as a dead end here (nmap 7.93 doesn't support `--interactive`).
3. `03-erlang-otp-ssh-rce-cve-2025-32433.md` — Erlang/OTP SSH pre-auth RCE on port 2222, Metasploit `exploit/linux/ssh/ssh_erlangotp_rce`, foothold as `aberrant_distance` (uid 1006).
5. `05-apache-druid-cve-2021-25646.md` — Apache Druid 0.20.0 JavaScript engine RCE, Metasploit `exploit/linux/http/apache_druid_js_rce` (target 1, in-memory), foothold as `druid` (uid 1005). No privesc chain found.
6. `06-distcc-cve-2004-2687.md` — distccd wide-open (`ALLOWEDNETS=0.0.0.0/0`) command execution. **Metasploit module `exploit/unix/misc/distcc_exec` failed consistently** ("did not reply") despite confirmed reachability; worked instead via the nmap `distcc-cve2004-2687` NSE script's `.cmd` argument, passed through `--script-args-file` to dodge shell-quoting conflicts with the script's own internal quoting. Good teaching moment: tooling doesn't always work, know how to read the script source and improvise. Foothold as `distccd` (uid 121).

**Local privilege escalation (needs an existing foothold):**

4. `04-sudo-service-wildcard-privesc.md` — `sudo /usr/sbin/service *` NOPASSWD combined with unsanitised path concatenation in the `service` wrapper script, path traversal to arbitrary root command execution. Chained from exploit 3's `aberrant_distance` foothold. (Note: an earlier duplicate `sudo-service-path-traversal.md` from a prior session was removed by the user; file 04 is canonical.)
7. `07-readable-shadow-credential-cracking.md` — `/etc/shadow` is world-readable (`0644` instead of `0640 root:shadow`). Hashes for `webops` and `analyst` cracked via John/rockyou.txt in ~4 seconds (`webops:administrator`, `analyst:password`), confirming the known weak scenario credentials.
8. `08-suid-nano-privileged-file-write.md` — SUID root `/usr/bin/nano`. Standard GTFOBins shell-spawn technique (`Ctrl+R`/`Ctrl+X` execute-command) **does not work**, confirmed nano explicitly drops effective UID back to real UID before exec'ing a child process (proven via `/proc/<pid>/status` showing `Uid: 1003 0 0 0` while nano itself runs privileged). The actual bypass: nano's own file open/save still runs with root privilege, so `/etc/sudoers` was opened and edited directly inside nano to add `analyst ALL=(ALL) NOPASSWD:ALL`, confirmed with `sudo su` → `uid=0(root)`. Chained from exploit 7's cracked `analyst` credentials.

## Investigated but not yet resolved

- **Sudo AWK**: none of the accounts checked so far have it (`backupsvc`, `webops`, `analyst`, `aberrant_distance`, `druid`, `distccd` all show only the harmless `(root) NOPASSWD: /usr/bin/sudo -l` baseline entry). Not yet confirmed whether this SecGen module actually provisioned on this build, or whether it belongs to an account not yet reached. Next step: now that a root shell exists (via exploit 8), run `grep -r "awk" /etc/sudoers /etc/sudoers.d/` directly as root to settle this.

## Remaining from the original vulnerability/misconfiguration list

- sudo AWK (investigate as above, now that root access is available)
- writable cron script
- tar wildcard cron
- writable `/etc/group`

## Not yet started

- Adding and testing: DNS service, email service, WebGoat, WebWolf, Security Shepherd (Security Shepherd previously failed to provision under SecGen due to `tomcat9`/`openjdk-11-jdk` fitting issues on Debian 12; will need a fresh native install approach).
- VM cleanup items (VirtualBox Guest Additions remnants, oVirt remnants, MariaDB `debian-start` root access error, SSSD dependency/socket failures, Vagrant-specific config, hostname/username/presentation tidy-up).
- Later: integration with the separate Windows AD/DC VM.
- Final: master VMware VM export for student distribution (7-Zip archive).

## Terminology note for consistency

"Pivoting" is reserved for using a compromised host to reach a different network segment. What we're doing when moving from a low-privilege shell to root on the same host is **local privilege escalation**, not pivoting. Keep this distinction consistent across write-ups and any teaching materials built from them.

## Immediate continuation point

Pick up with: confirming sudo AWK ownership via the root shell obtained in exploit 8, then work through writable cron script, tar wildcard cron, and writable `/etc/group` in the same tested-and-documented manner as exploits 1–8. After the local privesc set is exhausted, move on to provisioning and testing the missing DNS/email/WebGoat/WebWolf/Security Shepherd services.
