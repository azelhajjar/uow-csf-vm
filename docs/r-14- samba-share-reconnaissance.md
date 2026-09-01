# Activity: Samba Share Reconnaissance

## Summary

Reconnaissance of the Samba/SMB service, newly added to this VM, port scanning, service identification, and enumeration of available shares, culminating in confirmation that a share (`HR-Shared`) permits fully unauthenticated guest read/write access.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.200 |
| Service | Samba 4.17.12-Debian (smbd/nmbd), ports 139/tcp, 445/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nmap, smbclient |

## Reconnaissance

### Step 1: Full port re-scan confirming new ports

```bash
nmap -p- -T4 192.168.144.200
```

```
PORT      STATE SERVICE
21/tcp    open  ftp
22/tcp    open  ssh
111/tcp   open  rpcbind
139/tcp   open  netbios-ssn
445/tcp   open  microsoft-ds
1716/tcp  open  xmsg
2049/tcp  open  nfs
2181/tcp  open  eforward
2222/tcp  open  EtherNetIP-1
3306/tcp  open  mysql
3632/tcp  open  distccd
4369/tcp  open  epmd
8081/tcp  open  blackice-icecap
8082/tcp  open  blackice-alerts
8083/tcp  open  us-srv
8091/tcp  open  jamlink
8888/tcp  open  sun-answerbook
```

Confirms `139/tcp` (netbios-ssn) and `445/tcp` (microsoft-ds) as new additions relative to the `r-02`/`r-13` baseline, both standard Samba ports. All previously-known services remain unchanged.

### Step 2: Port/service confirmation

```bash
nmap -sV -p 139,445 --script default 192.168.144.200
```

Confirms `smbd`/`nmbd` listening on the standard SMB ports, with the server banner identifying `Samba 4.17.12-Debian` (matching the version confirmed during installation validation).

### Step 3: Samba-specific NSE tooling

Beyond the generic `default` script set, a dedicated Samba/SMB script family exists and was checked for relevance:

```bash
ls -l /usr/share/nmap/scripts/ | grep -i smb
```

A large set of scripts is available (share/user/group enumeration, OS discovery, protocol dialects, several historical vulnerability checks). Four were selected as directly relevant: `smb-enum-shares` (the NSE equivalent of the manual `smbclient -L` listing already performed), `smb-os-discovery`, `smb-protocols`, and `smb-vuln-cve-2017-7494` (checked for completeness, since a real assessment would want to rule out SambaCry even though this VM's current Samba version, 4.17.12, is confirmed well beyond the 2017 vulnerable range).

```bash
nmap -p 139,445 --script smb-enum-shares,smb-os-discovery,smb-protocols,smb-vuln-cve-2017-7494 192.168.144.200
```

```
| smb-protocols:
|   dialects:
|     2.0.2
|     2.1
|     3.0
|     3.0.2
|_    3.1.1
```

**Only `smb-protocols` produced output.** `smb-enum-shares`, `smb-os-discovery`, and `smb-vuln-cve-2017-7494` all ran without error but returned nothing, despite `smb-enum-shares` targeting exactly the same information (anonymous share listing) already confirmed working via `smbclient -L` moments later in this activity (Step 4). This is another instance of the NSE reliability pattern already established across this project: `smb-protocols` correctly and usefully confirms the SMB dialect versions supported (up to 3.1.1, consistent with a current Samba build), while a script targeting essentially the same anonymous-share-listing capability that manual `smbclient` succeeds at moments later produces nothing. As with the CUPS scripts in `r-12`, this is recorded honestly rather than assumed to indicate anonymous access doesn't exist, the subsequent manual steps in this activity settle that question definitively.

### Step 4: Unauthenticated share listing

```bash
smbclient -L //192.168.144.200/ -N
```

```
        Sharename       Type      Comment
        ---------       ----      -------
        print$          Disk      Printer Drivers
        HR-Shared       Disk
        IPC$            IPC       IPC Service (Samba 4.17.12-Debian)
        nobody          Disk      Home Directories
```

`-N` suppresses any password prompt, testing whether the share list itself is available without credentials, and it is: `smbclient` connects and lists all four shares with zero authentication. Two are standard/expected (`print$`, the printer-driver share; `IPC$`, the administrative interprocess-communication share every Samba server exposes). `HR-Shared` and `nobody` (a `[homes]`-style auto-generated home-directory share) are not default and warrant investigation.

The trailing SMB1 protocol negotiation error is expected and unrelated to the shares themselves; it's `smbclient` attempting an obsolete workgroup-listing fallback that modern Samba correctly refuses (SMB1 is disabled by default), not a finding.

### Step 5: Testing guest access to HR-Shared

```bash
smbclient //192.168.144.200/HR-Shared -N
```

```
smb: \> ls
  .                                   D        0  ...
  ..                                  D        0  ...
  Staff_Rota_Sept2026.txt             N       44  ...
  Staff_Directory.csv                 N       94  ...
```

Guest access succeeds and reveals two files with names strongly suggestive of genuine HR/organisational content, no authentication of any kind was required to reach this point.

### Step 6: Testing write access

```
smb: \> put /etc/hostname test_upload.txt
putting file /etc/hostname as \test_upload.txt (1.2 kb/s) (average 1.2 kb/s)
smb: \> ls
  test_upload.txt                     A        5  ...
```

The upload succeeded. This confirms the share is not merely readable but **writable** by an anonymous, unauthenticated guest connection, a materially more serious finding than read-only exposure, since it permits tampering, malicious file planting, or (depending on what consumes the share's contents) potential further exploitation.

The test file was removed immediately after confirmation (`del test_upload.txt`) to leave the share in its intended state.

## Outcome

Confirmed the target exposes a share (`HR-Shared`) that is browseable, readable, and writable by any unauthenticated client, requiring no credentials whatsoever. Two files present on the share (`Staff_Rota_Sept2026.txt`, `Staff_Directory.csv`) suggest genuine sensitive organisational content is exposed; their contents were not yet read in this activity (see `e-13- samba-guest-writable-share.md` for content retrieval and full impact assessment).

## Remediation

See `e-13- samba-guest-writable-share.md` for full remediation guidance.

## Teaching Notes

This is a classic, still very commonly encountered real-world misconfiguration: guest access enabled with write permission on a share containing genuinely sensitive-looking content. Unlike the CVE-based exploits elsewhere in this project, no vulnerability or version-specific bug is involved here at all, the software is fully current and correctly functioning exactly as configured; the risk is entirely in the configuration choice itself. This is a valuable contrast for students: not every serious finding requires a CVE, and misconfiguration review is as important a skill as vulnerability scanning.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None (guest/anonymous)
**Resulting access:** Anonymous read/write access to `HR-Shared`
**Provides access for:** Precedes `e-13- samba-guest-writable-share.md`
**Suggested teaching level:** Level 5 (unauthenticated SMB enumeration and share permission testing)

## What is Samba?

Samba is software that lets Linux/Unix systems participate in Windows-style file and printer sharing (the SMB/CIFS protocol). It allows a Linux server to offer network shares that Windows, Mac, and Linux clients can all browse and access using the same standard protocol Windows itself uses. Samba is extremely common in real organisations for shared drives, department folders, and file servers, and is also the technology that lets a Linux machine participate in a Windows Active Directory domain (relevant later once this VM's environment includes a domain controller).
