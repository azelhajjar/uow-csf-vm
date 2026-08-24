Here is a clean project-context summary you can save and give Claude.

---

# CAV-CSF Vulnerable VM Project Context

## Project purpose

We are building a deliberately vulnerable Linux VM for the CAV-CSF cyber security teaching environment.

The VM is intended to support practical exploitation exercises across penetration testing, network security, web application security and related cyber security modules.

The original VM was generated using SecGen, but SecGen is no longer part of the active workflow. The generated Debian VM has been migrated into VMware Workstation and all further modification, cleanup, validation and extension is being done directly on the VMware VM.

The final student distribution will be the complete tested VMware VM directory compressed as a 7-Zip archive.

The environment is an authorised, intentionally vulnerable teaching lab under our control.

## Base VM

- Debian 12 KDE.
- Originally generated using SecGen.
- Migrated from VirtualBox into VMware Workstation.
- VMware is now the definitive platform.
- Existing university Kali VM is also VMware-based and is being used as the attacker machine.
- SecGen source/project information is retained only for provenance and historical context.

Suggested provenance statement for later documentation:

> This virtual machine was initially generated using the SecGen framework (`cliffe/SecGen` on GitHub) and subsequently modified and extended for use within the CAV-CSF cyber security teaching environment.

## VMware/network cleanup completed

The imported VM originally had two NICs. One was removed and the remaining interface has been normalised to:

`eth0`

GRUB contains:

```text
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
```

A stale persistent udev rule that forced the NIC to `ens33` was removed:

```text
/etc/udev/rules.d/70-persistent-net.rules
```

`update-initramfs -u` was subsequently run.

The VM uses Debian's traditional ifupdown configuration rather than NetworkManager for `eth0`.

`net-tools` has been installed because `ifconfig` is preferred for routine interface work. `/usr/sbin` was added persistently to the `vagrant` user's PATH.

A VMware snapshot was created/planned around this clean migration point:

```text
CAV-CSF-01-VMware-Clean
```

Do not rely on fixed IP addresses in documentation because DHCP is being used.

## Existing lab accounts from the SecGen build

Current scenario-created accounts include:

```text
backupsvc
webops
analyst
```

Known deliberately weak credentials currently include:

```text
webops:administrator
analyst:password
```

There are additional generated/service accounts associated with individual vulnerabilities, including `aberrant_distance`, `druid` and `distccd`.

Final hostname, usernames and visible VM naming still need tidying before release.

## Validated exploitation work

The exploitation phase has already started from Kali. The objective is hands-on exploitation, not merely checking whether a vulnerability appears to exist.

For every successful vulnerability or misconfiguration, we are creating a dedicated Markdown file containing the actual tested attack path, commands, evidence, result, remediation and useful teaching observations.

Eight attack paths have already been validated.

### 01 - ProFTPD 1.3.3c supply-chain backdoor

ProFTPD 1.3.3c was successfully exploited remotely without authentication and produced a root shell directly.

This provides a simple, high-impact remote exploitation exercise requiring no subsequent privilege escalation. 

Documentation:

```text
01-proftpd-1.3.3c-backdoor.md
```

### 02 - Anonymous NFS credential exposure

An unrestricted NFS export exposes `/srv/backups`.

Files on the share disclose enough information to reconstruct credentials for `backupsvc`, which then provides an SSH foothold.

This path intentionally remains low privilege rather than automatically leading to root.

It is useful for teaching enumeration, NFS, information disclosure, credential correlation and credential reuse. 

Documentation:

```text
02-nfs-anonymous-credential-exposure.md
```

### 03 - Erlang/OTP SSH pre-authentication RCE

CVE-2025-32433 was successfully exploited against the Erlang/OTP SSH daemon.

The attack is unauthenticated and produces a shell as:

```text
aberrant_distance
```

This foothold feeds directly into the following privilege escalation. 

Documentation:

```text
03-erlang-otp-ssh-rce-cve-2025-32433.md
```

### 04 - sudo service wildcard/path traversal privilege escalation

The `aberrant_distance` account has:

```text
NOPASSWD: /usr/sbin/service *
```

The Debian `service` wrapper concatenates the supplied service name with `/etc/init.d` without properly restricting path traversal.

Using a service name such as:

```text
../../usr/bin/id
```

causes an arbitrary executable outside `/etc/init.d` to run as root.

This provides a clean exploitation chain:

```text
Erlang pre-auth RCE
    ->
aberrant_distance
    ->
sudo service wildcard/path traversal
    ->
root
```



Documentation:

```text
04-sudo-service-wildcard-privesc.md
```

### 05 - Apache Druid CVE-2021-25646

Apache Druid 0.20.0 was successfully exploited using its JavaScript execution vulnerability.

It produced a shell as:

```text
druid
```

No root escalation was found from this account during testing, which is acceptable and useful because not every remote RCE needs to become a root chain.

This is therefore retained as a standalone unauthenticated RCE-to-low-privilege-shell exercise. 

Documentation:

```text
05-apache-druid-cve-2021-25646.md
```

### 06 - DistCC CVE-2004-2687

The exposed distccd service is configured to allow connections from anywhere.

The Metasploit module failed against this build despite the target genuinely being vulnerable.

The Nmap NSE script:

```text
distcc-cve2004-2687
```

successfully demonstrated command execution, and was then used to obtain a reverse shell as:

```text
distccd
```

No root chain was identified from that account.

This is particularly useful educationally because it demonstrates that a Metasploit module failing does not prove that the vulnerability is absent. 

Documentation:

```text
06-distcc-cve-2004-2687.md
```

### 07 - World-readable /etc/shadow and offline credential cracking

`/etc/shadow` is incorrectly configured as world-readable.

Any low-privilege foothold can therefore retrieve password hashes.

Using John the Ripper with `rockyou.txt`, the following credentials were recovered rapidly:

```text
webops:administrator
analyst:password
```

This provides a useful bridge between an initial low-privilege service compromise and authenticated SSH access using another account. 

Documentation:

```text
07-readable-shadow-credential-cracking.md
```

### 08 - SUID Nano privileged file write

`/usr/bin/nano` is setuid root.

The standard GTFOBins Nano shell-spawn technique does not work on Nano 7.2 because Nano drops privilege before executing external commands.

Testing confirmed, however, that Nano itself retains effective UID 0 for file operations.

A low-privilege user can therefore edit privileged files such as:

```text
/etc/sudoers
```

The exploit was demonstrated from `analyst` by adding a NOPASSWD sudo rule and obtaining root.

This is particularly useful because students cannot simply copy the obvious GTFOBins command; they must diagnose why the usual method fails and identify the retained privileged-file-write primitive. 

Documentation:

```text
08-suid-nano-privileged-file-write.md
```

## Current exploitation philosophy

Do not assume that SecGen provisioning means a vulnerability works.

Every intended weakness must be tested ourselves from Kali.

A vulnerability should only be treated as part of the final lab when we have reproduced the actual exploit path.

Negative findings are valuable and should be retained where educationally useful.

Examples already encountered:

- Metasploit's DistCC module failed even though DistCC was exploitable.
- Modern Nmap no longer supports the historical SUID `--interactive` escalation.
- Nano's common shell-spawn escalation fails, but privileged file editing works.
- Several service accounts provide useful low-privilege footholds but deliberately have no immediate root escalation.

This produces a more realistic environment than making every vulnerability trivially lead to root.

## Multi-level teaching coverage

This VM is not only for Level 7. It will also be used across Level 5 and Level 6 modules, so the attack surface must include a range of difficulty levels.

Do not optimise every scenario for full compromise, complex chaining or root access.

We also need simpler, lower-privilege and reconnaissance-oriented exercises that are useful on their own, particularly for earlier modules.

Suitable examples include:

- service and version enumeration;
- identifying exposed services;
- anonymous or weakly authenticated access;
- information disclosure;
- insecure file shares;
- weak/default credentials;
- credential discovery without immediate privilege escalation;
- basic password attacks;
- overly permissive files/directories;
- basic web-application weaknesses;
- simple command execution that results only in a low-privilege shell;
- service misconfiguration that exposes data but does not provide code execution;
- DNS enumeration/misconfiguration;
- email service enumeration and weak configuration;
- accessible backups/configuration files;
- basic local privilege observations that do not necessarily lead to root;
- dead ends and red herrings that require students to recognise that an apparent weakness is not exploitable further.

A successful exercise does not need to end in root or form part of a longer chain.

When adding or evaluating a vulnerability, also consider its likely teaching level:

### Level 5

- basic enumeration;
- service discovery;
- weak credentials;
- information disclosure;
- simple misconfiguration;
- introductory exploitation.

### Level 6

- more involved service exploitation;
- credential reuse;
- local privilege escalation;
- multi-step attacks;
- web/application weaknesses.

### Level 7

- complex exploitation;
- CVE analysis;
- chained attacks;
- alternative exploitation methods;
- troubleshooting failed tooling;
- deeper privilege-escalation and attack-path reasoning.

These are guidelines rather than rigid classifications. The same service may support exercises at more than one level.

When documenting a new exploit or misconfiguration, add a field to `## Lab Dependencies`:

**Suggested teaching level:** Level 5 / Level 6 / Level 7
Where appropriate, more than one level can be listed, for example:
**Suggested teaching level:** Level 5–6
The goal is to build a varied teaching VM with both simple standalone weaknesses and advanced chained exploitation paths, rather than making every vulnerability a high-difficulty Level 7 exercise.

## Existing attack chains

A strong existing chain is:

```text
Erlang/OTP pre-auth RCE
    ->
aberrant_distance
    ->
sudo service wildcard/path traversal
    ->
root
```

Another possible family of chains is:

```text
Remote service RCE / NFS foothold
    ->
low-privilege account
    ->
world-readable /etc/shadow
    ->
offline cracking
    ->
SSH as analyst/webops
    ->
local privilege escalation
```

SUID Nano has already been validated as one such escalation from `analyst`.

## Remaining provisioned vulnerabilities/misconfigurations to test

There are additional intended local weaknesses from the SecGen build that still need hands-on validation, including:

- writable cron script;
- tar wildcard cron;
- sudo AWK;
- sudo service configurations beyond the already validated path where relevant;
- writable `/etc/group`;
- other SUID binaries or account-specific privilege assignments that remain exposed.

Each successful attack should receive its own numbered `.md` file following the existing format.


## Full attack-lifecycle teaching coverage

The VM should support practical activities across the full attack lifecycle, not only exploitation and privilege escalation.

Students at different levels should be able to use the VM for reconnaissance, enumeration, vulnerability identification, exploitation, post-exploitation analysis and attack-path reasoning.

Activities should therefore include useful tasks even where no exploit or privilege escalation follows.

### Reconnaissance

Include activities that require students to identify the target and understand its exposed attack surface before attempting exploitation.

Examples include:

- host discovery;
- identifying live systems;
- basic network reconnaissance;
- identifying exposed TCP and UDP services;
- identifying unusual or non-standard service ports;
- initial service fingerprinting;
- operating-system fingerprinting where appropriate;
- comparing active and passive information where relevant.

### Service enumeration

Students should be able to enumerate individual services in more detail after identifying them.

Examples include:

- Nmap service and version detection;
- Nmap default scripts;
- targeted Nmap NSE scripts;
- FTP enumeration;
- SSH enumeration;
- NFS enumeration;
- RPC enumeration;
- DNS enumeration;
- SMTP enumeration;
- HTTP/HTTPS enumeration;
- SMB enumeration where relevant later;
- database-service enumeration;
- identifying banners, versions and exposed functionality.

Nmap NSE should be used where it adds value rather than treating Nmap only as a port scanner.

Examples may include:

~~~bash
nmap -sV <target>
nmap -sC -sV <target>
nmap --script <relevant-script> <target>
~~~

The exact NSE scripts should depend on the service being investigated.

### Kali tooling

Activities should expose students to appropriate Kali tools beyond a single exploitation framework.

Depending on the service and teaching level, this may include:

- Nmap;
- Nmap NSE;
- `rpcinfo`;
- `showmount`;
- `dig`;
- `dnsrecon`;
- `dnsenum`;
- `whois` where appropriate;
- `curl`;
- `wget`;
- `netcat`;
- `telnet` for basic protocol interaction where useful;
- `openssl s_client`;
- FTP clients;
- SSH clients;
- SMTP interaction tools;
- web-content discovery tools;
- Burp Suite;
- OWASP ZAP;
- password-auditing/cracking tools such as John the Ripper;
- Metasploit where appropriate;
- alternative tools or manual techniques when Metasploit is unsuitable or fails.

Do not design activities around tool usage for its own sake. The tool should support a clear reconnaissance, enumeration, validation or exploitation objective.

### Vulnerability identification and validation

Students should have activities where they identify likely weaknesses before exploiting them.

Examples include:

- correlating service versions with known vulnerabilities;
- recognising insecure service configuration;
- identifying weak/default credentials;
- discovering anonymously accessible resources;
- identifying excessive permissions;
- identifying exposed configuration or backup files;
- recognising potentially dangerous sudo rules;
- identifying SUID binaries;
- examining cron jobs;
- identifying world-readable sensitive files;
- interpreting Nmap NSE vulnerability results;
- validating whether a suspected vulnerability is actually exploitable.

A scanner result alone should not automatically count as successful exploitation.

### Manual protocol interaction

Where useful, include activities that require students to interact directly with a service rather than relying entirely on automated tools.

Examples include:

- manually issuing SMTP commands;
- querying DNS records directly;
- interacting with HTTP endpoints using `curl`;
- testing FTP access manually;
- examining RPC/NFS services;
- checking service banners;
- manually validating credentials;
- sending simple requests to understand protocol behaviour.

This is particularly useful at Level 5 because it helps students understand what automated tools are actually doing.

### Exploitation

The VM should contain exploitation activities at different levels of complexity.

These may include:

- simple exploitation using an established tool;
- exploitation based on weak/default credentials;
- exploiting service misconfiguration;
- exploiting known CVEs;
- web-application exploitation;
- command execution;
- obtaining a low-privilege shell;
- obtaining direct root access;
- exploiting manually where automated tooling is unavailable;
- using an alternative technique where the obvious tool fails.

Not every successful exploit needs to produce root access.

### Credential attacks

Include activities involving credentials at several stages of the attack lifecycle.

Examples include:

- discovering credentials in configuration files;
- identifying credentials in exposed backups;
- weak/default credentials;
- password reuse;
- offline password cracking;
- authenticated access using recovered credentials;
- identifying which services accept recovered credentials;
- comparing credential exposure with privilege level.

### Local enumeration

After obtaining a foothold, students should have tasks involving enumeration of the compromised host before attempting privilege escalation.

Examples include:

- identifying the current user and groups;
- examining sudo permissions;
- finding SUID/SGID binaries;
- inspecting file permissions;
- examining scheduled jobs;
- identifying writable scripts or directories;
- examining running services;
- identifying local users;
- locating sensitive files;
- identifying weak configuration;
- checking installed software and versions;
- examining network connections and listening services.

The student should not be directed immediately from shell access to the privilege-escalation command. Local enumeration should form part of the exercise where appropriate.

### Local privilege escalation

Include both straightforward and more analytical privilege-escalation activities.

Examples include:

- sudo misconfiguration;
- SUID binaries;
- writable privileged files;
- writable cron scripts;
- wildcard exploitation;
- insecure group/file permissions;
- weak service configuration;
- credential-based escalation;
- chained local weaknesses.

Some apparent privilege-escalation opportunities should also be dead ends where this has educational value.

### Post-exploitation analysis

Some activities should continue after successful compromise without necessarily requiring persistence or further attack.

Examples include:

- determining the privilege level obtained;
- identifying accessible sensitive data;
- establishing which accounts or services are exposed;
- identifying possible further attack paths;
- examining credentials;
- documenting evidence of compromise;
- determining what additional access the compromised account provides;
- distinguishing between a limited foothold and full system compromise.

### Attack chaining

At higher levels, individual weaknesses should be combined into coherent attack paths.

Examples include:

~~~text
service enumeration
    ->
remote code execution
    ->
low-privilege shell
    ->
local enumeration
    ->
sudo misconfiguration
    ->
root
~~~

or:

~~~text
NFS enumeration
    ->
information disclosure
    ->
credential recovery
    ->
SSH access
    ->
readable /etc/shadow
    ->
offline cracking
    ->
different account
    ->
local privilege escalation
~~~

Students should understand why each stage enables the next rather than treating the chain as a sequence of unrelated commands.

### Failed techniques and alternative approaches

Where useful, retain scenarios where a commonly suggested tool or technique fails.

Students may then need to:

- interpret the failure;
- confirm that the service is still vulnerable;
- inspect another tool;
- use an NSE script;
- test manually;
- inspect exploit/module behaviour;
- find an alternative exploitation method.

The existing DistCC exercise is a good example: the Metasploit module failed while the Nmap NSE script successfully demonstrated command execution.

The SUID Nano exercise is another example: the commonly cited shell-spawn technique fails, but Nano's privileged file-write capability remains exploitable.

### Teaching level

Activities should be suitable across Level 5, Level 6 and Level 7.

#### Level 5

Emphasise:

- reconnaissance;
- port scanning;
- service/version detection;
- Nmap NSE;
- basic service enumeration;
- manual protocol interaction;
- weak/default credentials;
- information disclosure;
- insecure shares;
- basic web enumeration;
- introductory exploitation;
- obtaining and recognising a low-privilege foothold.

#### Level 6

Emphasise:

- targeted enumeration;
- vulnerability identification;
- more involved service exploitation;
- credential attacks;
- local enumeration;
- local privilege escalation;
- web-application attacks;
- chaining two or more weaknesses;
- interpreting tool output rather than simply running commands.

#### Level 7

Emphasise:

- detailed vulnerability analysis;
- CVE-based exploitation;
- advanced enumeration;
- troubleshooting failed tooling;
- alternative/manual exploitation methods;
- complex local privilege escalation;
- multi-stage attack chains;
- attack-path reasoning;
- comparing exploitation approaches;
- explaining why a technique succeeds or fails.

These are guidelines rather than strict boundaries.

### Documentation requirement

For each teaching scenario, record not only the exploit but also the useful activities that precede and follow it.

Where applicable, the Markdown documentation should identify:

~~~markdown
**Suggested teaching level:** Level 5 / Level 6 / Level 7  
**Starting point:** Network access / existing foothold / authenticated account  
**Reconnaissance activities:** ...  
**Enumeration activities:** ...  
**Vulnerability identification:** ...  
**Exploitation activity:** ...  
**Local enumeration:** ...  
**Privilege escalation:** ...  
**Resulting access:** ...  
**Can feed into:** ...
~~~

A scenario does not need to populate every field.

The objective is for the VM to support complete practical exercises from discovery through analysis and exploitation, rather than functioning only as a collection of targets for known exploit commands.

## Services still to add

The VM still needs broader service coverage.

Planned additions include:

- DNS service;
- email service;
- WebGoat;
- WebWolf;
- Security Shepherd.

These should be installed directly onto the VMware VM, deliberately configured for the required teaching scenarios, and then tested ourselves from Kali.

The objective is not merely to have the ports/services present. Each service should support one or more meaningful reconnaissance, exploitation or misconfiguration exercises.

WebGoat and WebWolf were originally expected from the SecGen configuration but need to be verified/re-added as required.

Security Shepherd failed during SecGen provisioning because its old module expected dependencies such as `tomcat9` and `openjdk-11-jdk` that did not fit the Debian 12 environment. It therefore needs a manual installation suited to the current VM.

## Future Windows AD component

A separate Windows Active Directory/domain controller VM is planned later.

AD-related Linux packages are already present on the Debian VM.

The eventual aim is to add Windows/AD attack paths alongside the Linux vulnerabilities rather than forcing everything into a single machine.

## Remaining VM cleanup

Before final release, remaining migration/provisioning artefacts still need review, including:

- remaining VirtualBox Guest Additions remnants;
- stale oVirt files/rules;
- any remaining Vagrant configuration;
- MariaDB startup/authentication issue;
- SSSD dependency/socket warnings;
- hostname;
- usernames;
- visible VM naming;
- unnecessary generated artefacts;
- lower-priority KDE warnings if still present.

MariaDB previously reported:

```text
ERROR 1045 (28000): Access denied for user 'root'@'localhost'
```

during `/etc/mysql/debian-start`, so this needs resolving, particularly because future web applications may depend on MariaDB.

## Exploit documentation structure

Maintain one Markdown file per validated vulnerability/misconfiguration.

Current numbering:

```text
01-proftpd-1.3.3c-backdoor.md
02-nfs-anonymous-credential-exposure.md
03-erlang-otp-ssh-rce-cve-2025-32433.md
04-sudo-service-wildcard-privesc.md
05-apache-druid-cve-2021-25646.md
06-distcc-cve-2004-2687.md
07-readable-shadow-credential-cracking.md
08-suid-nano-privileged-file-write.md
```

Continue sequential numbering.

The write-ups should describe what we actually tested and observed rather than generic instructions copied from external sources.

A write-up does not need to describe exploitation. It may document reconnaissance, enumeration, information disclosure, credential discovery, service misconfiguration, vulnerability validation, local enumeration, privilege escalation, a failed technique with teaching value, or another meaningful stage of the attack lifecycle.

Use sections appropriate to the activity being documented. Typical sections may include:

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

Not every write-up needs every section.

`## Lab Dependencies` should be included consistently and should identify, where applicable:

- prerequisite exploit(s) or activities;
- required starting access;
- starting account;
- resulting access;
- what later activity or exploit it can feed into;
- suggested teaching level.

A scenario may therefore be valuable even if it does not produce a shell, does not escalate privileges, and does not form part of a larger attack chain.

## Final objective

The finished CAV-CSF environment should provide a coherent vulnerable infrastructure rather than simply a collection of unrelated CVEs.

It should contain:

- remote unauthenticated vulnerabilities;
- vulnerable network services;
- weak/misconfigured network services;
- information disclosure;
- credential discovery and cracking;
- credential reuse;
- authenticated attack paths;
- local privilege escalation;
- SUID/sudo/cron permission weaknesses;
- web application targets;
- DNS and email attack surfaces;
- eventually Windows/Active Directory integration.

Each important attack path must be reproducibly exploitable from Kali and documented in its own Markdown file before inclusion in the final release.

Current position: eight validated exploit/misconfiguration exercises are complete. Continue testing the remaining Linux weaknesses, produce `.md` documentation for successful findings, then add and validate the missing DNS, mail, WebGoat, WebWolf and Security Shepherd services before moving on to AD integration and final VM cleanup/distribution.

