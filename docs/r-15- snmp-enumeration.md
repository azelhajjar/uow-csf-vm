# Activity: SNMP Enumeration

## Summary

Reconnaissance of the SNMP service, newly added to this VM, confirming the default `public` read-only community string grants full, unrestricted access to the MIB tree, including a complete running-process listing, an unauthenticated information-disclosure finding independent of any CVE.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.200 |
| Service | Net-SNMP (snmpd) 5.9.3, port 161/udp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | snmpwalk, Metasploit (`auxiliary/scanner/snmp/snmp_login`, `auxiliary/scanner/snmp/snmp_enum`) |

## Reconnaissance

### Step 1: Port confirmation

```bash
nmap -sU -p 161 192.168.144.200
```

Confirms `161/udp` open, consistent with a newly added SNMP service not present in the original `r-02` baseline.

### Step 2: SNMP-specific NSE scripts

```bash
ls -l /usr/share/nmap/scripts/ | grep -i snmp
```

A substantial SNMP script set exists, including several Windows-oriented scripts (`snmp-win32-*`) not relevant to this Linux target. Four were selected: `snmp-sysdescr` (basic system identification), `snmp-processes` (running process enumeration, the NSE equivalent of Metasploit's `snmp_enum` used later in this activity), `snmp-netstat`, and `snmp-interfaces`.

```bash
nmap -sU -p 161 --script snmp-sysdescr,snmp-processes,snmp-netstat,snmp-interfaces --script-args snmpcommunity=public 192.168.144.200
```

Unlike several other services enumerated in this project, these scripts worked correctly and reliably. `snmp-processes` in particular returned a complete process listing (PID, name, path, and launch parameters), including confirmation of the Postfix mail subsystem (`master`, `pickup`, `qmgr`, `tlsmgr`, `cleanup`, `local`) and standard system processes:

```
9493:
  Name: master
  Path: /usr/lib/postfix/sbin/master
  Params: -w
```

This independently corroborates the process-level visibility already demonstrated via Metasploit's `snmp_enum` module (Step 4), obtained here through a completely different tool with consistent results, good cross-validation of the finding.

### Step 3: Community string guessing via Metasploit

```
use auxiliary/scanner/snmp/snmp_login
set RHOSTS 192.168.144.200
run
```

```
[+] 192.168.144.200:161 - Login Successful: public (Access level: read-only); Proof (sysDescr.0): Linux cav-csf-linux 6.1.0-27-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.115-1 (2024-11-01) x86_64
```

The module's built-in wordlist correctly guessed the default community string `public` on the first attempt, confirming both that a weak/default string is in use and that it grants at least read access. `sysDescr.0` is also disclosed as proof, itself a meaningful information leak: exact kernel version and build date, without any authentication.

### Step 4: Full walk via snmpwalk

```bash
snmpwalk -v2c -c public 192.168.144.200 1.3.6.1.2.1.25.1.6.0
```

```
iso.3.6.1.2.1.25.1.6.0 = Gauge32: 275
```

Confirms live system data (running process count) is retrievable, not just static configuration strings. A full unrestricted walk (`snmpwalk -v2c -c public 192.168.144.200`) returns extensive MIB data spanning multiple standard MIB modules (system, host resources, IP, DISMAN event MIB), consistent with the deliberately configured `view all` scope rather than the restrictive `systemonly` default view Debian ships.

### Step 5: Full system enumeration via Metasploit

```
use auxiliary/scanner/snmp/snmp_enum
set RHOSTS 192.168.144.200
run
```

This module retrieves a structured summary far more readable than a raw walk, including a complete running-process listing with PID, state, name, and full command line:

```
5307    runnable   nmbd            /usr/sbin/nmbd --foreground --no-process-group
5319    runnable   smbd            /usr/sbin/smbd --foreground --no-process-group
6041    running    snmpd           /usr/sbin/snmpd -LOw -u Debian-snmp ...
5730    runnable   sshd            sshd: uow-admin@pts/3
3668    runnable   cups-browsed    /usr/sbin/cups-browsed
```

**This is a significant, independently corroborating finding.** An unauthenticated attacker can enumerate every running process on the host, including which services are active (confirming CUPS and Samba, both already separately identified and exploited via `e-12` and `e-13`), and which user accounts have active interactive sessions (`uow-admin` shown with live SSH sessions and pty assignments), all without sending a single packet to any of those services directly. This demonstrates a real-world risk of SNMP misconfiguration beyond simple device information: full process-level visibility into a host can materially assist an attacker in prioritising and planning further attacks, entirely passively from the target's own perspective.

### Step 6: SNMP-extended breadcrumb

Beyond the standard MIB fields, the target's `snmpd.conf` includes a custom `extend` directive exposing the contents of a small note file via SNMP itself, discoverable only by walking the `NET-SNMP-EXTEND-MIB` subtree.

```bash
snmpwalk -v2c -c public 192.168.144.200 1.3.6.1.4.1.8072.1.3.2
```

```
iso.3.6.1.4.1.8072.1.3.2.3.1.1.7.105.116.45.110.111.116.101 = STRING: "Backup rotation moved to /srv/backups - contact IT if missing"
```

Also, `sysName` is set to `PRINT-SRV-01.cwscenario.uk`, giving the host a specific internal-looking name consistent with the CUPS print server role already established.

This is a deliberate cross-service breadcrumb, delivered via an entirely different protocol and discovery mechanism than the FTP `note` file (`r-04`), but pointing to the same underlying location (`/srv/backups`, the NFS export investigated in `e-02- nfs-anonymous-credential-exposure.md`). A student who discovers this via SNMP receives independent corroboration of the same lead already discoverable via FTP, reinforcing the organisational narrative and demonstrating that real environments often leak the same sensitive reference through multiple, unrelated channels.

## Outcome

Confirmed SNMP is exposed with the default `public` community string granting read access to the full MIB tree, including live process enumeration and a custom-extended breadcrumb pointing to `/srv/backups`, corroborating the FTP-discovered lead from `r-04`/`e-02` via an independent channel. This is a pure misconfiguration finding (default credentials plus an overly permissive view), not a software vulnerability; the installed Net-SNMP version is current.

## Remediation

See `e-14- snmp-community-string-disclosure.md` for full remediation guidance.

## Teaching Notes

This activity is a strong complement to the Samba misconfiguration in `r-14`/`e-13`: both are pure configuration issues with no CVE involved, but SNMP's weakness is specifically a **weak/default credential** (the community string) rather than an access-control toggle, a useful distinction for students to understand two different root causes that both fall under the general "misconfiguration" umbrella. The process-enumeration result is also a good demonstration that information disclosure from one service (SNMP) can corroborate and extend findings from entirely unrelated services (CUPS, Samba) discovered separately, reinforcing the value of building a complete picture across all reconnaissance activities rather than treating each service as isolated.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Read-only SNMP access; full MIB tree and process enumeration
**Provides access for:** Precedes `e-14- snmp-community-string-disclosure.md`; corroborates findings from `e-12- cups-full-rce-chain.md` and `e-13- samba-guest-writable-share.md`
**Suggested teaching level:** Level 5 (weak/default credential discovery, SNMP protocol fundamentals)

## What is SNMP?

SNMP (Simple Network Management Protocol) is used for infrastructure monitoring and management, letting network administrators remotely query and, in some configurations, modify settings on routers, switches, printers, servers, and other network devices from a central monitoring system. It exposes a structured tree of information (the MIB, or Management Information Base) covering things like system identity, hardware status, network interfaces, and running processes. Authentication in the older, still widely used SNMPv1/v2c versions is a simple shared "community string" rather than a real username/password, which is the root of the misconfiguration explored in this activity.
