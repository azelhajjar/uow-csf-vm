## Status

Not yet executed. This is a forward plan, not a completion record, and no step below has been run on either the disposable or the master VM.

Prerequisite state as it currently stands:

- Linux VM configuration: complete.
- Headless conversion: complete.
- Windows AD integration: domain join done and working, DNS arrangement tested and accepted (see `ad-integration.md`); Windows AD Phase 2 is now substantially built and validated.
- Delivery: the Linux VM has already been supplied to the lab technician for the lab repository.

Two reasons to defer. Windows AD Phase 2 is now substantially built and validated, but the regression testing below explicitly covers Windows AD integration and cross-VM attack paths, so running this procedure before the remaining Windows documentation/testing decisions (`ad-integration.md`, Remaining Open Decisions) are settled would still validate against a moving target and need repeating. And because the image has already been supplied, any minimisation now means re-supplying it, which should be batched with the outstanding student-facing polish in `linux-handover-checklist.md` rather than done on its own.

Sequence this after the remaining Windows documentation/testing decisions are settled, as part of a single planned re-supply.

## Final Linux cleanup

Once the Linux VM configuration, Windows AD integration and headless conversion have all been completed and validated, perform a final cleanup before preparing the VMware distribution.

The cleanup must distinguish between harmless build artefacts and anything that could affect the intended teaching environment.

### Remove administrative and build history

Remove shell and tooling history generated while building, configuring and testing the VM.

Review all accounts that were used during development, including `root` and any administrative/build accounts.

Relevant artefacts may include:

- Bash or other shell history files;
- root command history;
- editor histories;
- temporary installation scripts;
- copied configuration fragments;
- temporary downloads;
- test files created during provisioning;
- command-output files that are no longer required;
- credentials or notes accidentally left behind during development.

For example, Bash history may exist in:

~~~text
~/.bash_history
/root/.bash_history
~~~

Clear the active shell history as well as the persisted history file where necessary.

Do **not** indiscriminately remove logs, files or histories that form part of an intended teaching scenario.

In particular, preserve:

- deliberately exposed credentials;
- reconnaissance breadcrumbs;
- deliberately vulnerable configuration files;
- scenario files such as those used by NFS, Samba, SMTP or SNMP;
- logs that are intentionally required by a practical activity;
- files used by documented exploitation or privilege-escalation paths.

The objective is to remove evidence of how the VM was built, not evidence deliberately placed for students to discover.

## Final package and system minimisation

After the environment is completely functional, consider whether additional packages, services or files can safely be removed to reduce the final VM footprint.

This is potentially much more disruptive than removing the desktop environment and must therefore be treated conservatively.

Perform all investigation and removal on the disposable VM first.

### Capture another baseline

Before attempting any package removal, record:

~~~bash
dpkg -l > ~/packages-before-final-minimisation.txt
~~~

~~~bash
apt-mark showmanual > ~/manual-packages-before-final-minimisation.txt
~~~

~~~bash
systemctl list-units --type=service --state=running > ~/services-before-final-minimisation.txt
~~~

~~~bash
systemctl list-unit-files --state=enabled > ~/enabled-services-before-final-minimisation.txt
~~~

~~~bash
ss -tulpn > ~/listeners-before-final-minimisation.txt
~~~

Also record:

~~~bash
free -h
df -h
~~~

### Identify candidates rather than deleting immediately

Review possible cleanup candidates such as:

- residual KDE or graphical packages left after the headless conversion;
- unused display-manager components;
- obsolete kernels;
- unused development/build packages;
- package caches;
- temporary installation files;
- packages installed during experimentation but not required by the final environment;
- disabled services that are genuinely unrelated to any teaching scenario;
- libraries that are no longer required by any installed package.

Do not assume that a package is unnecessary simply because it has no currently running service.

Some packages may be required by:

- exploitation scenarios;
- scheduled jobs;
- web applications;
- Docker containers or host-side Docker tooling;
- Java applications;
- PHP/Apache components;
- Python tooling;
- MariaDB;
- CUPS;
- Samba;
- DNS;
- SMTP;
- Redis;
- SNMP;
- NFS/RPC;
- Kerberos;
- LDAP;
- SSSD;
- SMB/AD integration;
- future Windows AD attack paths.

### Treat `autoremove` as a proposal

Before accepting package removal, inspect what APT intends to remove:

~~~bash
apt -s autoremove --purge
~~~

Do not run the real operation until the complete proposed package list has been reviewed.

If any package has an unclear role, retain it.

The objective is not to produce the smallest possible Debian installation. The objective is to remove clearly unnecessary components without destabilising the teaching environment.

### Low-risk storage cleanup

Once package removal decisions are complete, low-risk storage cleanup may include clearing downloaded package archives:

~~~bash
apt clean
~~~

Other caches and temporary files may also be reviewed, but they should not be removed automatically without first confirming that they do not contain scenario material.

### Regression testing

After each significant removal stage, repeat the same regression testing used for the headless conversion.

Verify:

- successful boot into the intended headless environment;
- network configuration and `eth0`;
- SSH access;
- DNS resolution;
- all expected TCP and UDP listeners;
- all infrastructure services;
- all deployed web applications;
- scheduled jobs;
- local privilege-escalation scenarios;
- vulnerable package versions that must remain deliberately installed;
- Windows AD integration;
- cross-VM attack paths.

Compare the resulting service and network surface against the captured baseline.

Representative exploitation and privilege-escalation paths should again be reproduced on the disposable VM if packages related to those paths were removed.

### Replication to the master

Only removals that have passed regression testing on the disposable VM should be applied to the master.

Classify accepted removals as:

`SCENARIO CHANGE — replicate to master`

Apply exactly the validated changes rather than independently attempting another cleanup on the master.

Afterwards, perform a final functional regression test on the master before packaging it for student distribution.