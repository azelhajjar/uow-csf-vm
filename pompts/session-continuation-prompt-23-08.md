# CAV-CSF Exploitation Session — Continuation Prompt

We are continuing hands-on exploitation and lab documentation for the CAV-CSF deliberately vulnerable Linux VM used for cyber security teaching at the University of Westminster.

The VM was originally generated with SecGen using Debian 12 KDE, but it has now been migrated into VMware Workstation. SecGen is no longer part of the active workflow. All remaining cleanup, modification, validation, extension and testing is being done directly on the VMware VM.

The final student distribution will be the completed VMware VM folder compressed as a 7-Zip archive.

The environment is an authorised, intentionally vulnerable teaching lab under our control.

## Working method — important

- I, the user, perform all commands and exploitation manually in the authorised lab environment.
- Claude does not need access to Kali, the vulnerable VM, VMware, or any other machine and should not attempt to execute or perform exploitation itself.
- Claude's role is to provide the commands and procedures for me to reproduce the vulnerability, explain what output or behaviour to look for, interpret the output I paste back, troubleshoot unexpected results, and produce the Markdown documentation once exploitation has been successfully demonstrated.
- Treat every command Claude provides as an instruction for me to run manually.
- Do not assume a command has executed until I provide the resulting output.
- Do not fabricate command output, service behaviour, exploit success, privilege level, evidence or results.
- When the next decision depends on command output, wait for my actual output before progressing.
- Do not repeat commands, checks or explanations that have already been completed unless I ask for clarification or a new error specifically requires them.
- Do not re-explain basic Linux, networking, penetration-testing or exploitation concepts unless I ask.
- Do not assume a SecGen-provisioned vulnerability works simply because it exists in the scenario. We test every intended exploit empirically ourselves.
- I run the exploit from Kali or from the appropriate existing foothold. Claude provides the reproduction procedure and analyses the result.
- Once an exploit or misconfiguration has been successfully demonstrated, create the next sequential `.md` write-up based on what we actually tested, not a generic exploit description.
- Existing `.md` exploit files are the authoritative record for exploits already completed. Use them rather than reconstructing previous attack steps from memory.
- If a known technique or tool fails, investigate why rather than immediately concluding that the underlying vulnerability is absent.
- Negative results can be useful teaching material and should be documented where relevant.
- Keep terminology technically precise. In particular, moving from a low-privilege account to root on the same host is local privilege escalation, not pivoting. Reserve pivoting for using a compromised host to reach another network or network segment.

## VM state

- Debian 12 KDE.
- Originally generated with SecGen.
- Migrated from VirtualBox into VMware Workstation.
- VMware is now the definitive platform.
- Existing university Kali VM is also VMware-based and is being used as the attacker machine.
- SecGen source/project information is now historical context only and is not needed for continuing exploitation work.
- Final student distribution will be the VMware VM directory compressed as a 7-Zip archive.
- The VM uses DHCP. Do not hard-code IP addresses into permanent documentation unless specifically needed for a transient exploitation example.

## VMware/network cleanup already completed

The imported VM originally had two NICs. One was removed.

The remaining interface was normalised to:

```text
eth0
```

GRUB contains:

```text
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
```

A stale persistent udev rule that forced the interface to `ens33` was removed:

```text
/etc/udev/rules.d/70-persistent-net.rules
```

`update-initramfs -u` was run afterwards.

The VM uses Debian's traditional ifupdown configuration rather than NetworkManager for `eth0`.

`net-tools` was installed because `ifconfig` is preferred for routine interface work.

`/usr/sbin` was added persistently to the `vagrant` user's PATH.

Snapshot around the clean VMware migration point:

```text
CAV-CSF-01-VMware-Clean
```

## VM cleanup status

Major VMware migration and networking cleanup has already been completed.

Do not redo completed cleanup.

Before producing the final master image, verify that no obsolete migration artefacts remain and complete the genuinely outstanding items:

- stale oVirt rules/remnants;
- MariaDB `/etc/mysql/debian-start` root-authentication error;
- SSSD dependency/socket warnings;
- any remaining VirtualBox or Vagrant artefacts that still genuinely exist;
- hostname;
- usernames;
- visible VM naming and presentation cleanup;
- lower-priority KDE warnings only if they continue to matter.

A previous MariaDB boot issue reported:

```text
ERROR 1045 (28000): Access denied for user 'root'@'localhost'
```

during `/etc/mysql/debian-start`.

Do not assume this still exists. Verify before changing anything.

## Disposable exploitation instance

The VM currently being exploited is a disposable test instance used to validate exploits before they are incorporated into the final teaching image.

It is not the master VM that will eventually be distributed to students.

Persistent changes caused by exploitation are acceptable on this test instance.

For example, exploit 8 deliberately appended:

```text
analyst ALL=(ALL) NOPASSWD:ALL
```

to `/etc/sudoers` and that change was deliberately left in place on the disposable instance.

Reset notes in the Markdown documentation are only there to identify exploitation artefacts created during testing. The master VM is never exploited; it only receives the intended vulnerable starting configuration and any SCENARIO CHANGE items discovered during validation.

## Existing scenario-created accounts

Relevant accounts currently include:

```text
backupsvc
webops
analyst
aberrant_distance
druid
distccd
```

Known deliberately weak credentials include:

```text
webops:administrator
analyst:password
```

Additional service/generated accounts may exist.

Final username and visible account naming cleanup is still required before release.

## Exploit documentation method

A dedicated Markdown file is created for every successfully exploited vulnerability or misconfiguration.

Files are numbered sequentially in the order in which exploitation is validated:

```text
01-...
02-...
03-...
```

Each write-up should reflect what we actually did and observed.

Typical sections are:

```text
- Summary
- Environment
- Lab Dependencies
- Reconnaissance
- Enumeration
- Vulnerability / Misconfiguration
- Vulnerability Identification / Validation
- Exploitation
- Credential Discovery / Cracking
- Local Enumeration
- Privilege Escalation
- Evidence
- Outcome
- Remediation
- Teaching Notes

```

Not every file needs every heading if a section is not applicable.

`## Lab Dependencies` should be included consistently and should identify, where applicable:

- prerequisite exploit(s) or activities;
- required starting access;
- starting account;
- resulting access;
- what later activity or exploit it can feed into;
- suggested teaching level.

A scenario may therefore be valuable even if it does not produce a shell, does not escalate privileges, and does not form part of a larger attack chain.

## Confirmed exploits so far — 8 total

### 01 — ProFTPD 1.3.3c supply-chain backdoor

File:

```text
01-proftpd-1.3.3c-backdoor.md
```

ProFTPD 1.3.3c was successfully exploited remotely without authentication.

Metasploit module:

```text
exploit/unix/ftp/proftpd_133c_backdoor
```

The exploit produced a root shell directly.

No privilege-escalation stage is required.

This is a clean remote unauthenticated root-compromise exercise.

### 02 — Anonymous NFS credential exposure

File:

```text
02-nfs-anonymous-credential-exposure.md
```

An unrestricted NFS export exposes:

```text
/srv/backups
```

Files on the share disclose enough information to reconstruct credentials for:

```text
backupsvc
```

Those credentials provide an SSH foothold.

This path intentionally remains low privilege and is useful for teaching:

- NFS enumeration;
- insecure exports;
- information disclosure;
- correlation of information across files;
- credential discovery;
- credential reuse.

SUID Nmap was investigated from this account but was a dead end because the installed modern Nmap version no longer supports the historical `--interactive` escalation technique.

### 03 — Erlang/OTP SSH pre-authentication RCE

File:

```text
03-erlang-otp-ssh-rce-cve-2025-32433.md
```

CVE-2025-32433 was successfully exploited against the Erlang/OTP SSH daemon.

Metasploit module:

```text
exploit/linux/ssh/ssh_erlangotp_rce
```

The attack is unauthenticated and produces a foothold as:

```text
aberrant_distance
```

This foothold feeds directly into exploit 04.

### 04 — sudo service wildcard/path traversal privilege escalation

File:

```text
04-sudo-service-wildcard-privesc.md
```

The `aberrant_distance` account has a NOPASSWD sudo rule permitting:

```text
/usr/sbin/service *
```

The Debian `service` wrapper concatenates the supplied service name with `/etc/init.d` without sufficiently restricting path traversal.

A path such as:

```text
../../usr/bin/id
```

can therefore escape `/etc/init.d` and execute an arbitrary program as root.

Validated chain:

```text
Erlang/OTP pre-auth RCE
    ->
aberrant_distance
    ->
sudo service wildcard/path traversal
    ->
root
```

An older duplicate file called:

```text
sudo-service-path-traversal.md
```

was removed.

`04-sudo-service-wildcard-privesc.md` is canonical.

### 05 — Apache Druid CVE-2021-25646

File:

```text
05-apache-druid-cve-2021-25646.md
```

Apache Druid 0.20.0 was successfully exploited through its JavaScript execution vulnerability.

Metasploit module:

```text
exploit/linux/http/apache_druid_js_rce
```

The in-memory Unix target was used.

The exploit produced a shell as:

```text
druid
```

No root escalation was found from this account during the validation session.

This is intentionally retained as a standalone unauthenticated RCE-to-low-privilege-shell exercise.

### 06 — DistCC CVE-2004-2687

File:

```text
06-distcc-cve-2004-2687.md
```

The distccd service is deliberately configured to allow connections from anywhere.

The Metasploit module:

```text
exploit/unix/misc/distcc_exec
```

failed consistently despite the service genuinely being vulnerable.

TCP connectivity and service reachability were confirmed.

The exploit was instead reproduced successfully using Nmap's:

```text
distcc-cve2004-2687
```

NSE script.

The `.cmd` argument was passed through a `--script-args-file` because direct shell quoting conflicted with the NSE script's own quoting.

A reverse shell was obtained as:

```text
distccd
```

No root escalation was found from that account.

This is useful teaching material because it demonstrates that:

- Metasploit failure does not prove that a target is patched;
- alternative tooling may succeed;
- reading exploit/NSE source can explain tool behaviour;
- students should understand the protocol and attack rather than depend exclusively on one framework.

### 07 — World-readable `/etc/shadow` and offline credential cracking

File:

```text
07-readable-shadow-credential-cracking.md
```

`/etc/shadow` is incorrectly world-readable.

Any low-privilege local foothold can therefore retrieve password hashes.

The hashes for `webops` and `analyst` were cracked with John the Ripper and `rockyou.txt` in approximately four seconds.

Recovered credentials:

```text
webops:administrator
analyst:password
```

This creates a useful attack transition:

```text
low-privilege service compromise
    ->
read /etc/shadow
    ->
offline cracking
    ->
credentials
    ->
SSH as another user
    ->
local privilege escalation
```

### 08 — SUID Nano privileged file write

File:

```text
08-suid-nano-privileged-file-write.md
```

`/usr/bin/nano` is setuid root.

The standard GTFOBins Nano shell-spawn technique was tested and does not work on the installed Nano version.

Nano drops effective privilege before executing child commands.

This behaviour was verified by examining the running process state.

However, Nano's own file-open/save operations retain root privilege.

The actual exploit therefore uses privileged file I/O rather than shell spawning.

From the `analyst` account:

```text
/etc/sudoers
```

was opened directly in Nano and modified to add:

```text
analyst ALL=(ALL) NOPASSWD:ALL
```

Root access was then confirmed.

This is particularly valuable educationally because the obvious GTFOBins technique fails and requires investigation before the actual exploitable primitive is identified.

## Existing useful attack chains

### Chain A

```text
Erlang/OTP pre-auth RCE
    ->
aberrant_distance
    ->
sudo service wildcard/path traversal
    ->
root
```

### Chain B

```text
Remote RCE / NFS foothold
    ->
low-privilege shell
    ->
world-readable /etc/shadow
    ->
offline password cracking
    ->
SSH as analyst/webops
    ->
local privilege escalation
```

SUID Nano has already been validated as one escalation route from `analyst`.

## Investigated but unresolved

### sudo AWK

The following accounts checked so far did not reveal the intended sudo AWK rule:

```text
backupsvc
webops
analyst
aberrant_distance
druid
distccd
```

They showed only the harmless baseline sudo entry allowing `sudo -l`, except where another exploit-specific rule existed.

It is not yet known whether the SecGen sudo-AWK module was actually provisioned, whether the rule belongs to a different account, or whether it failed during generation.

Because root access now exists on the disposable test instance through exploit 08, settle this directly from the target by inspecting the sudoers configuration.

If an AWK rule exists, identify exactly which account it belongs to and then test the actual privilege-escalation path from that account.

If no rule exists, record that the intended SecGen weakness was not provisioned and decide whether to add an equivalent scenario manually.

## Remaining original Linux vulnerabilities/misconfigurations to test

Still to work through:

- sudo AWK;
- writable cron script;
- tar wildcard cron;
- writable `/etc/group`.

The same methodology applies to each:

1. establish exactly where/how the misconfiguration exists;
2. identify the account/foothold from which it is reachable;
3. reproduce the attack manually;
4. confirm the resulting privilege level;
5. create the next numbered `.md` file only after exploitation is successfully demonstrated.

Do not simply inspect the configuration and declare it exploitable.

## Services still to add

The VM still needs broader service coverage.

Planned additions:

- DNS service;
- email service;
- WebGoat;
- WebWolf;
- Security Shepherd.

These should be added directly to the VMware VM.

The objective is not merely to expose additional ports.

Each added service should provide meaningful teaching opportunities such as:

- reconnaissance;
- service enumeration;
- insecure configuration;
- weak credentials;
- information disclosure;
- protocol abuse;
- vulnerable software;
- web exploitation;
- attack chaining where appropriate.

After each service is added, test it manually from Kali using the same empirical methodology as the existing targets.

Create dedicated Markdown documentation for successful exploitation scenarios.

## Security Shepherd

Security Shepherd did not provision successfully during the original SecGen build.

The old SecGen provisioner expected dependencies such as:

```text
tomcat9
openjdk-11-jdk
```

in a way that did not fit the Debian 12 environment.

Do not try to revive the old SecGen provisioner.

Use a fresh manual/native deployment approach appropriate to the current VMware Debian environment.

After installation, verify and test the application from Kali before treating it as part of the lab.

## WebGoat and WebWolf

These were expected from the original scenario but still need to be verified/re-added as necessary.

Treat them as current service-addition tasks rather than assuming the SecGen provisioning succeeded.

## DNS and email

DNS and mail services are new coverage that should be added to broaden the attack surface.

When designing these, prefer realistic intentionally insecure configurations or vulnerable service scenarios that support actual exercises rather than simply running default daemons.

The exact weakness should be chosen, configured and then tested manually before being documented.

## Future Windows Active Directory component

A separate Windows AD/domain controller VM will be added later.

AD-related Linux packages already exist on the Debian VM.

The eventual environment should include Windows/AD attack paths alongside the Linux exercises rather than forcing every scenario into the Linux VM.

AD integration is not the immediate task.

## Current exploitation philosophy

Do not assume anything works because SecGen provisioned it.

Everything must be tested from the attacker perspective.

The lab should include a mixture of:

- direct unauthenticated root compromise;
- unauthenticated low-privilege RCE;
- information disclosure;
- credential discovery;
- credential cracking;
- credential reuse;
- authenticated footholds;
- local privilege escalation;
- chained attacks;
- dead ends/red herrings;
- tool failures that require alternative techniques.

Not every exploit should lead directly to root.

Low-privilege footholds with no immediate escalation are useful and realistic.

Likewise, failed exploitation methods can have teaching value if the vulnerability itself remains exploitable through another path.

## Tool failure handling

If a tool fails:

- do not immediately conclude that the vulnerability is absent;
- verify service/version/configuration;
- inspect error behaviour;
- try an alternative implementation or manual technique;
- inspect exploit/NSE/module source where useful;
- document the difference if it provides educational value.

The DistCC exercise is the model example: Metasploit failed while Nmap NSE exploitation succeeded.

## Documentation quality

Write-ups should not be generic vulnerability summaries.

They should capture the actual lab behaviour.

Preserve details such as:

- tools that failed;
- why they failed when known;
- commands that succeeded;
- account obtained;
- exact privilege level;
- whether a root chain exists;
- whether an apparent privilege-escalation technique turned out to be a red herring;
- what made the exercise educationally useful.

## Terminology

Use precise terminology throughout.

Local privilege escalation:

```text
low-privilege user -> root/admin on the same host
```

Pivoting:

```text
using a compromised host to reach another network or otherwise inaccessible target
```

Do not call local privilege escalation pivoting.

Master-image change control
All exploitation and validation is performed against the disposable exploitation/test VM. The master teaching VM is not used for exploitation.
If testing shows that a vulnerable scenario needs a configuration change, missing file, service adjustment, credential, vulnerable setting or other modification in order for the intended exercise to work, that underlying change must also be applied to the master VM.
This is the same approach already used with the FTP notes/credential scenario: testing on the exploitation VM showed what content was required for the exercise, and the corresponding vulnerable starting condition was then added to the master VM.
Changes made to create, repair or complete the vulnerable scenario must be replicated to the master. Examples include:
- adding a missing service or vulnerable configuration;
- adding files or notes required for information disclosure;
- correcting deliberately weak permissions required by an exercise;
- adding intended credentials or account configuration;
- fixing a broken vulnerable service so that the planned exploit can be reproduced;
- adding any other prerequisite required for the student attack path.
Changes produced as a consequence of actually exploiting the test VM must not be copied to the master. Examples include:
- sudoers entries added during privilege escalation;
- files modified as the result of an exploit;
- payloads or shells dropped during exploitation;
- attacker-created cron entries;
- group membership changed during exploitation;
- persistence mechanisms;
- other post-exploitation artefacts.
Whenever we modify the exploitation VM during testing, classify the change explicitly as either:
SCENARIO CHANGE — replicate to master
or
EXPLOITATION ARTEFACT — do not replicate to master
Keep track of all SCENARIO CHANGE items so they can later be applied to the master VM before final student distribution.

## Final objective

The final CAV-CSF vulnerable environment should be a coherent teaching infrastructure rather than a random CVE collection.

Desired coverage includes:

- remote unauthenticated vulnerabilities;
- vulnerable network services;
- network-service misconfiguration;
- NFS/file-share weaknesses;
- DNS;
- email;
- SSH;
- credential leakage;
- weak passwords;
- offline password cracking;
- credential reuse;
- sudo misconfiguration;
- SUID weaknesses;
- cron weaknesses;
- filesystem permission weaknesses;
- web application vulnerabilities;
- chained attack paths;
- eventually Windows/Active Directory attacks.

Every important exploit must be reproducible from Kali and documented before inclusion in the final release.

## Immediate continuation point

Start from the current disposable test VM state, where root access has already been obtained during exploit 08.

First settle whether the intended sudo AWK rule actually exists and identify which account it applies to.

Then work through, one at a time:

```text
writable cron script
tar wildcard cron
writable /etc/group
```

For each scenario:

- Claude provides the reproduction procedure;
- I manually run the commands;
- I paste the output;
- Claude interprets the result;
- if necessary, we troubleshoot;
- only after exploitation is confirmed do we create the next sequential `.md` file.

Once the original Linux privilege-escalation/misconfiguration set is exhausted, move on to adding and testing:

```text
DNS
email
WebGoat
WebWolf
Security Shepherd
```

After those are working and documented, complete the outstanding VM cleanup/presentation work, then later proceed to the separate Windows AD/DC integration and final VMware teaching-image preparation.