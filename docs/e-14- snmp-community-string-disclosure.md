# Activity: SNMP Community String Disclosure

## Summary

Exploitation of the default `public` SNMP community string confirmed in `r-15- snmp-enumeration.md`, retrieving sensitive system configuration data and full process enumeration with zero authentication required.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.200 |
| Service | Net-SNMP (snmpd) 5.9.3, port 161/udp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | snmpwalk, Metasploit (`auxiliary/scanner/snmp/snmp_enum`) |

## Vulnerability

`snmpd.conf` is configured with `rocommunity public default -V all`, granting read access to the entire MIB tree to any client presenting the string `public`, SNMP's long-standing, widely known default. Combined with `agentaddress udp:161` (listening on all interfaces rather than loopback only), this exposes extensive host information to any network client with zero authentication. This is CWE-798 (Use of Hard-coded Credentials) / CWE-521 (Weak Password Requirements) territory applied to SNMPv2c's community-string model, not a software vulnerability.

## Exploitation

**On Kali**, retrieving organisational configuration data:

```bash
snmpwalk -v2c -c public 192.168.144.200 1.3.6.1.2.1.1.4.0
snmpwalk -v2c -c public 192.168.144.200 1.3.6.1.2.1.1.6.0
```

Returns the configured `sysContact` and `sysLocation` values:
```
IT Support <it-support@cwscenario.uk>
CAV-CSF Server Room, cwscenario.uk
```

This discloses genuine organisational detail (a contact email address and physical location description tied to the `cwscenario.uk` domain), useful reconnaissance for an attacker building a picture of the target organisation, consistent with the breadcrumb style already established via the FTP note and CUPS print queue naming.

**On Kali**, full process enumeration:

```
use auxiliary/scanner/snmp/snmp_enum
set RHOSTS 192.168.144.200
run
```

Retrieves the complete running-process list (see `r-15` for full output), confirming active services (`cups-browsed`, `smbd`, `nmbd`, `snmpd`) and active user sessions (`uow-admin` via SSH) without any direct interaction with those services.

**On Kali**, retrieving the extended breadcrumb note:

```bash
snmpwalk -v2c -c public 192.168.144.200 1.3.6.1.4.1.8072.1.3.2
```

```
iso.3.6.1.4.1.8072.1.3.2.3.1.1.7.105.116.45.110.111.116.101 = STRING: "Backup rotation moved to /srv/backups - contact IT if missing"
```

This confirms a working `NET-SNMP-EXTEND-MIB` custom OID deliberately configured to expose organisational note content, and, notably, independently corroborates the exact same `/srv/backups` lead already discoverable via the FTP anonymous access finding in `e-02- nfs-anonymous-credential-exposure.md` and `r-04- ftp-banner-grab-and-anonymous-access.md`, this time via an entirely unrelated protocol and enumeration path.

**Using this lead:** the note points directly at `/srv/backups`. A student reaching this breadcrumb via SNMP, whether or not they have already found the equivalent FTP note, can follow it directly without needing to consult another file first:

```bash
showmount -e 192.168.144.200
```
```
Export list for 192.168.144.200:
/srv/backups *
```

```bash
mkdir /tmp/backups_mnt
sudo mount -t nfs 192.168.144.200:/srv/backups /tmp/backups_mnt
ls -la /tmp/backups_mnt
cat /tmp/backups_mnt/backup.conf
```

This mounts the anonymous NFS export and recovers the `backupsvc` credential from `backup.conf`, exactly as detailed in `e-02- nfs-anonymous-credential-exposure.md` (consult that file for the full recovered credential and further detail). That credential provides an SSH foothold as `backupsvc`, which is the starting point for the rest of the low-privilege exploitation chain on this VM: shadow-file credential cracking (`e-07`), SUID nano privilege escalation (`e-08`), and the tar-wildcard cron privilege escalation (`e-10`).

For students working through the reconnaissance phase methodically (Level 5-6), the value of this activity is recognising that a single line of disclosed text is enough to redirect enumeration effort toward a specific, high-value target rather than scanning blindly, this is the same judgement call a real assessor makes constantly when a lead like this surfaces. For students already working through the exploitation chain independently (Level 7), this activity mainly serves as corroboration, confirming the same target is reachable through a second, unrelated channel, and is a good prompt to discuss why real environments often leak the same sensitive reference through multiple services rather than assuming a single point of exposure is the full picture.

## Outcome

Confirmed unauthenticated disclosure of system configuration (kernel version, contact/location metadata) and full process-level visibility into the target host via the default `public` SNMP community string. No credentials, no CVE, and no prior access were required.

## Remediation

- Change the community string from the default `public` to a long, unique, unguessable value, or migrate to SNMPv3, which supports proper per-user authentication and encryption rather than a shared plaintext string.
- Restrict `agentaddress` to loopback or a specific trusted management interface unless network-wide SNMP polling is a genuine requirement.
- Restore the restrictive `view systemonly` (or a similarly narrow, purpose-built view) rather than exposing the full MIB tree (`view all`).
- Apply source-IP restrictions (`com2sec`/`access` ACL directives) to limit which hosts may query the agent at all, even with the correct community string.

## Teaching Notes

Paired with `r-15`, this activity reinforces that SNMP's community-string model is fundamentally a shared-password mechanism, and `public`/`private` remaining unchanged is one of the most persistent, decades-old misconfigurations still found in real assessments. The process-enumeration capability specifically is worth emphasising: students should come away understanding SNMP misconfiguration as a genuine reconnaissance and intelligence-gathering risk in its own right, not merely a minor information leak, since it can meaningfully assist an attacker in planning further action against other services on the same host.

## Lab Dependencies

**Prerequisite exploit(s):** `r-15- snmp-enumeration.md`
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Read-only SNMP data disclosure; no shell or further system access directly, but the disclosed note provides an alternate discovery path into the NFS/credential-exposure chain documented in `e-02- nfs-anonymous-credential-exposure.md`
**Provides access for:** Corroborates and provides an alternate route into `e-02- nfs-anonymous-credential-exposure.md`, from which the `backupsvc` foothold and subsequent chain (`e-07`, `e-08`, `e-10`) become reachable
**Suggested teaching level:** Level 5
