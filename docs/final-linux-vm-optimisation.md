# Final VM Optimisation — Headless Conversion

Once the VM build is otherwise complete, consider removing the Debian KDE graphical desktop and converting the VM to a headless server-style build.

This should be done **only at the very end of the build process**, after:

- all intended infrastructure services have been installed;
- all intended web applications have been installed;
- all reconnaissance activities have been validated;
- all exploitation/misconfiguration activities have been validated;
- all required `SCENARIO CHANGE` items have been replicated to the master;
- no further major package installation or service provisioning is expected.

The purpose is to reduce RAM usage, disk footprint, boot overhead and irrelevant desktop-process noise while preserving the complete teaching attack surface.

The web applications do not require a local graphical environment because students access them remotely from Kali using a browser.

## Testing workflow

Do **not** remove KDE from the master first.

The headless conversion must initially be performed on the disposable/test VM.

Before making the change, capture a baseline of the current system.

### Debian-side baseline

Record the currently running services:

~~~bash
systemctl list-units --type=service --state=running
~~~

Record listening TCP and UDP sockets:

~~~bash
ss -tulpn
~~~

Record the installed package set:

~~~bash
dpkg -l > ~/packages-before-kde-removal.txt
~~~

Also record current resource use:

~~~bash
free -h
df -h
~~~

### Kali-side network baseline

Capture the complete TCP attack surface:

~~~bash
nmap -sC -sV -p- <target> -oA cav-csf-before-kde-removal
~~~

Capture the important UDP surface separately:

~~~bash
sudo nmap -sU -sV --top-ports 100 <target> -oA cav-csf-udp-before-kde-removal
~~~

Keep these results for comparison after the headless conversion.

## Conversion sequence

Do the change in stages rather than combining desktop removal and aggressive package cleanup in a single operation.

Suggested sequence:

1. Set Debian to boot to `multi-user.target`.
2. Disable the graphical display manager.
3. Remove the KDE desktop/display-manager packages.
4. Reboot.
5. Perform the full regression test below.
6. Only after that, consider `apt autoremove --purge`.
7. **Inspect the packages proposed for autoremove before accepting them.**
8. Re-run the regression test after any autoremove operation.

Do not blindly accept an autoremove list. This VM contains a large number of manually added services and application runtimes, and an apparently unused dependency may still be required by a teaching service.

## Regression testing after KDE removal

After rebooting the disposable VM, repeat:

~~~bash
systemctl --failed
systemctl list-units --type=service --state=running
ss -tulpn
free -h
df -h
~~~

Repeat the Kali TCP and UDP scans and compare them with the pre-removal baseline.

Every expected service should still be present.

At minimum, verify the infrastructure currently documented in `services-README.md`, including:

- ProFTPD;
- OpenSSH;
- RPC/NFS;
- Erlang/OTP SSH;
- MariaDB;
- distccd;
- Zookeeper;
- Apache Druid;
- CUPS / cups-browsed;
- Samba;
- SNMP;
- Redis;
- BIND9 DNS;
- Postfix SMTP.

Also verify every web application present on the master at the time of conversion, including:

- WebGoat;
- WebWolf;
- DVWA;
- OWASP Security Shepherd;
- any additional web application subsequently validated and replicated to the master.

Do not merely confirm that the relevant TCP port is open.

For web applications, load the application remotely from Kali and confirm that it operates normally.

For network services, perform an appropriate functional check, for example:

- NFS exports are still visible;
- Erlang SSH still exposes the expected service/banner;
- Druid's API remains reachable;
- DistCC remains reachable and retains its intended vulnerable configuration;
- CUPS discovery behaviour remains intact;
- Samba shares remain enumerable;
- SNMP responds using the intended community configuration;
- Redis retains the intended unauthenticated/misconfigured state;
- DNS serves the intended zone and retains the configured AXFR behaviour;
- SMTP retains the intended enumeration/open-relay scenario.

## Attack-path regression

Do not assume that an unchanged port means the teaching scenario still works.

Check that the important vulnerable starting conditions remain intact, including:

- ProFTPD vulnerable build;
- NFS export and scenario files;
- Erlang/OTP vulnerable SSH service;
- `sudo service *` privilege-escalation configuration;
- Druid vulnerable configuration;
- DistCC vulnerable configuration;
- world-readable `/etc/shadow`;
- SUID Nano;
- tar wildcard cron scenario;
- CUPS vulnerable package/configuration state;
- Samba guest-writable share;
- SNMP community-string exposure;
- Redis unauthenticated data exposure;
- DNS zone-transfer configuration;
- SMTP enumeration/open-relay configuration.

A quick configuration/functional check is sufficient initially. Fully reproduce representative attack chains afterwards to confirm that removal of the graphical environment has not altered exploit behaviour.

At least one remote exploitation path and one local privilege-escalation chain should be reproduced end-to-end on the disposable headless VM.

## Resource comparison

Compare the before/after results for:

- idle RAM usage;
- disk usage;
- number of running services/processes;
- boot behaviour;
- network attack surface.

The conversion is worthwhile only if it reduces unnecessary overhead without changing the intended teaching environment.

## Outstanding project items

The following items remain open and must be resolved, validated or explicitly closed before the final teaching environment is considered complete.

### Security Shepherd

- Fix or work around the broken HTTP-to-HTTPS redirect, which currently redirects to `https://localhost/` without the required port.
- Generate a local lab CA and reissue the Security Shepherd TLS certificate against it.
- Import the lab CA root certificate into the rebuilt Kali VM as part of the Kali setup.
- Decide whether to replace the upstream default database root password (`CowSaysMoo`) with a project-specific value.
- Re-test Security Shepherd after any TLS, redirect or database configuration changes.

### Kali

- Rebuild/update the Kali VM.
- Reinstall or verify the tools required by the documented `r-` and `e-` activities.
- Import the lab CA root certificate once the local CA has been created.
- Regression-test the documented reconnaissance, enumeration and exploitation tooling from the rebuilt Kali VM.

### DNS and static addressing

- Move the master Linux VM to its intended static address:

~~~text
192.168.144.100
~~~

- Update all DNS records that depend on the Linux VM address, including the Security Shepherd record and all other service/application A records.
- Re-test forward DNS resolution after the migration.
- Re-test services and web applications using hostnames rather than relying only on direct IP access.
- Verify that any future Windows AD DNS integration remains consistent with the Linux-side zone configuration.

### Landing page

A central landing page for the teaching VM has not yet been created.

It should provide students with convenient links to the web training applications using the confirmed working entry points documented in `webapps-README.md`.

Current entry points include:

- WebGoat — application root;
- WebWolf — `/login`;
- DVWA — application root;
- Security Shepherd — HTTPS on port `8543`.

Only add applications to the landing page once they have been validated on the master VM.

If additional applications such as OWASP Juice Shop are later validated and replicated to the master, add them at that point.

### Passive reconnaissance scenario

The `cwscenario.uk` passive-reconnaissance activity remains deferred pending the required domain/subdomain configuration.

Do not treat this activity as complete until the external/domain-side infrastructure required for realistic passive reconnaissance has been configured and tested.

### Apache Druid CVE-2023-25194

CVE-2023-25194 remains an unconfirmed lead.

It has been identified as potentially relevant to the installed Druid environment but has not been empirically validated.

Do not document it as a confirmed vulnerability unless it is successfully reproduced on the disposable VM.

### Windows Active Directory

The separate Windows AD/domain-controller VM has not yet been built.

This remains a major final-stage component of the environment.

The AD work must include:

- building and configuring the Windows AD VM;
- validating the intended DNS integration;
- validating Linux-to-Windows and Windows-to-Linux connectivity;
- identifying and testing the intended AD reconnaissance and attack paths;
- identifying any Linux-side breadcrumbs or credentials that lead into the AD environment;
- confirming whether existing Linux packages such as SSSD, Kerberos, LDAP or SMB components are actually required;
- documenting validated AD activities using the same evidence-based approach as the Linux VM;
- performing a final cross-VM regression test from Kali.

The Linux VM should not be considered fully final until the intended Windows AD integration has been validated.

## Windows AD integration checkpoint

The Linux VM should not be treated as final until the separate Windows Active Directory/domain controller VM has been built and the intended integration between the two environments has been validated.

The final optimisation/headless-conversion stage should therefore take place only after the AD-related design is complete enough to confirm that removing KDE or other packages does not affect any Linux-side components required for the Windows/AD exercises.

Before finalising the Linux VM, verify the intended cross-system integration, including where applicable:

- DNS resolution between the Linux VM and the Windows AD environment;
- the planned AD-related DNS records;
- connectivity to the domain controller and relevant Windows services;
- any Linux-side Kerberos, LDAP, SMB, SSSD or domain-integration components required by the teaching scenarios;
- any credentials, files, service references or breadcrumbs on the Linux VM that lead into the Windows/AD environment;
- any attack paths that begin on the Linux VM and continue against the Windows/AD VM;
- any attack paths that begin in the Windows/AD environment and depend on services or information hosted on the Linux VM.

Do not remove Linux packages merely because they appear unused before the Windows AD scenarios have been validated. In particular, retain any AD-related packages until their role in the final environment is known.

Once the Windows/AD component is available, perform an integration regression test from Kali covering the Linux VM, the Windows AD VM and any intended cross-host attack paths.

If the headless Linux conversion has already been tested on the disposable VM before the Windows AD VM is completed, repeat the relevant integration checks once the AD environment becomes available before applying the final change to the master.


## Replication to the master

If the disposable VM passes the full regression test, classify the conversion as:

`SCENARIO CHANGE — replicate to master`

Apply the same headless conversion to the master VM.

Then run the same service, web-application and network regression checks against the master before preparing the final VMware distribution.

The master must not be used for exploitation testing. Full exploit validation remains on the disposable VM; the master requires functional verification that the intended vulnerable starting conditions and services have been preserved.