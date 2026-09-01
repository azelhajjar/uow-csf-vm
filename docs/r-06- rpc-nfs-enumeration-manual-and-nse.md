# Activity: RPC and NFS Enumeration (Manual Tools vs. NSE)

## Summary

Enumeration of the RPC portmapper service (port 111) and the NFS export it advertises (port 2049), comparing the standard command-line tools (`rpcinfo`, `showmount`) against their nmap NSE script equivalents. This activity documents the reconnaissance step that precedes and motivates `e- 02-nfs-anonymous-credential-exposure.md`, and additionally demonstrates that the NSE `nfs-ls` script can retrieve file listings and metadata directly through the scripting engine, without requiring the share to be manually mounted first, a capability distinct from what `showmount` alone provides.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | rpcbind (111/tcp, 111/udp), NFS export (2049/tcp) |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | rpcinfo, showmount, nmap NSE (`rpcinfo`, `nfs-showmount`, `nfs-ls`, `nfs-statfs`) |

## Reconnaissance

### Step 1: Manual RPC service enumeration with `rpcinfo`

```bash
rpcinfo -p 192.168.144.200
```

```
   program vers proto   port  service
    100000    4   tcp    111  portmapper
    100000    3   tcp    111  portmapper
    100000    2   tcp    111  portmapper
    100000    4   udp    111  portmapper
    100000    3   udp    111  portmapper
    100000    2   udp    111  portmapper
    100005    1   udp  43495  mountd
    100005    1   tcp  41673  mountd
    100005    2   udp  58602  mountd
    100005    2   tcp  44469  mountd
    100005    3   udp  39460  mountd
    100005    3   tcp  45867  mountd
    100024    1   udp  33505  status
    100024    1   tcp  34297  status
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100227    3   tcp   2049  nfs_acl
    100021    1   udp  46617  nlockmgr
    100021    3   udp  46617  nlockmgr
    100021    4   udp  46617  nlockmgr
    100021    1   tcp  35389  nlockmgr
    100021    3   tcp  35389  nlockmgr
    100021    4   tcp  35389  nlockmgr
```

`rpcinfo -p` queries the portmapper (rpcbind) directly and lists every RPC program registered with it, along with the version(s) supported, transport protocol, and current port. This confirms the presence of `mountd` (the mount protocol daemon, handles mount requests), `nfs` (the actual NFS file-sharing protocol), `nfs_acl` (NFS access control list extension), `status` and `nlockmgr` (NFS file locking support services). This is the authoritative source for the current ports of these services, as already noted in `r-02- reconnaissance-and-service-enumeration.md`, since they are dynamically reallocated on each query/restart and cannot be relied upon from a previous scan.

### Step 2: Manual export enumeration with `showmount`

```bash
showmount -e 192.168.144.200
```

```
Export list for 192.168.144.200:
/srv/backups *
```

`showmount -e` queries the `mountd` service specifically (rather than the full RPC program list) and asks it directly which filesystem paths are exported and to which clients. The output confirms a single export, `/srv/backups`, with `*` as the allowed client specification, meaning no host restriction is configured and any client can request to mount this share. This is the single most important finding of this enumeration phase and is what directly enables the credential-disclosure exploit documented in `e- 02-nfs-anonymous-credential-exposure.md`.

### Step 3: NSE equivalent of `rpcinfo`

```bash
nmap -p 111 --script rpcinfo 192.168.144.200
```

```
PORT    STATE SERVICE
111/tcp open  rpcbind
| rpcinfo:
|   program version    port/proto  service
|   100000  2,3,4        111/tcp   rpcbind
|   100000  2,3,4        111/udp   rpcbind
|   100000  3,4          111/tcp6  rpcbind
|   100000  3,4          111/udp6  rpcbind
|   100003  3,4         2049/tcp   nfs
|   100003  3,4         2049/tcp6  nfs
|   100005  1,2,3      39460/udp   mountd
|   100005  1,2,3      40086/udp6  mountd
|   100005  1,2,3      45867/tcp   mountd
|   100005  1,2,3      56035/tcp6  mountd
|   100021  1,3,4      35389/tcp   nlockmgr
|   100021  1,3,4      39285/tcp6  nlockmgr
|   100021  1,3,4      46617/udp   nlockmgr
|   100021  1,3,4      52155/udp6  nlockmgr
|   100024  1          33271/tcp6  status
|   100024  1          33505/udp   status
|   100024  1          34297/tcp   status
|   100024  1          46789/udp6  status
|   100227  3           2049/tcp   nfs_acl
|_  100227  3           2049/tcp6  nfs_acl
```

This NSE script produces the same underlying information as the standalone `rpcinfo` CLI tool, the same RPC program numbers, versions, and services, but presented as part of a broader nmap scan output rather than a standalone command. Two differences are worth noting:

- **IPv6 (`tcp6`/`udp6`) entries appear here but not in the CLI `rpcinfo -p` output.** This is because the NSE script queries both IPv4 and IPv6 RPC registrations by default, whereas the standalone `rpcinfo -p` in this instance queried only via IPv4. This is a genuinely useful piece of additional information the NSE version surfaces that the plain CLI invocation did not.
- **The specific ephemeral ports for `mountd`, `nlockmgr`, and `status` again differ slightly** from those seen in the manual `rpcinfo -p` run moments earlier (e.g. `mountd` on `41673/tcp` in Step 1 versus `45867/tcp` here), reinforcing the port-drift behaviour already documented in `r-02- reconnaissance-and-service-enumeration.md`: these services reallocate ephemeral ports between queries, so the specific port number should never be treated as stable, only the RPC program number is a reliable identifier across scans.

The practical takeaway: the NSE script and the CLI tool return equivalent core information, but the NSE version is more convenient when RPC enumeration is only one part of a broader nmap-driven scan, while the standalone CLI tool remains useful for quick, standalone checks or scripting outside of nmap.

### Step 4: NSE export enumeration, directory listing, and filesystem statistics

```bash
nmap -p 111,2049 --script nfs-showmount,nfs-ls,nfs-statfs 192.168.144.200
```

```
PORT     STATE SERVICE
111/tcp  open  rpcbind
| nfs-showmount:
|_  /srv/backups *
| nfs-ls: Volume /srv/backups
|   access: Read Lookup NoModify NoExtend NoDelete NoExecute
| PERMISSION  UID  GID  SIZE  TIME                 FILENAME
| rwxr-xr-x   0    0    4096  2026-08-22T03:46:54  .
| ??????????  ?    ?    ?     ?                    ..
| rw-rw-rw-   0    0    22    2026-08-22T03:46:54  backup-service.txt
| rw-rw-rw-   0    0    175   2026-08-22T03:46:55  backup.conf
| rw-rw-rw-   0    0    17    2026-08-22T03:46:54  hosts.txt
|_
| nfs-statfs:
|   Filesystem    1K-blocks   Used       Available   Use%  Maxfilesize  Maxlink
|_  /srv/backups  29754340.0  8477688.0  19739884.0  31%   16.0T        32000
2049/tcp open  nfs
```

This is where the NSE approach demonstrates a genuine capability advantage over the manual toolchain used in `e- 02`:

- **`nfs-showmount`** reproduces the standalone `showmount -e` result exactly (`/srv/backups *`), confirming the same finding via a different tool.
- **`nfs-ls` retrieves the full directory listing of the export directly through the NSE script**, without requiring the share to first be mounted locally with `mount -t nfs`, as was done manually in `e- 02`. The output shows the same three files later investigated there (`backup-service.txt`, `backup.conf`, `hosts.txt`), along with file permissions, ownership (UID/GID 0, i.e. root-owned), sizes, and modification timestamps, all retrieved in a single non-interactive command. The `access:` line (`Read Lookup NoModify NoExtend NoDelete NoExecute`) also confirms the NFS-level access permissions granted to an anonymous/unauthenticated client: read and directory-lookup access, but not write, extend, delete, or execute, consistent with a read-only-by-anonymous-clients export even though the underlying export itself has no host restriction.
- **`nfs-statfs`** retrieves filesystem-level statistics for the mounted export (total, used, and available space, maximum file size, maximum hard link count), information that has no direct equivalent in the manual `showmount`/`mount` workflow unless a student separately ran `df` after mounting the share locally.

This demonstrates a genuinely faster reconnaissance path: where the manual method (`e- 02`) required running `showmount`, then `mount`, then `find`/`cat` on the mounted share to reach the same three filenames, this single NSE command achieves file listing, permissions, and filesystem statistics all at once, without ever mounting anything locally on the attacker machine.

## Outcome

Both manual CLI tools (`rpcinfo`, `showmount`) and their NSE equivalents (`rpcinfo`, `nfs-showmount`) produced consistent, corroborating results: a single NFS export, `/srv/backups`, exported to any client (`*`) with no host restriction. The NSE `nfs-ls` and `nfs-statfs` scripts additionally demonstrated the ability to retrieve export contents and filesystem statistics directly through nmap's scripting engine, without needing to mount the share locally first, a genuine efficiency advantage over the manual workflow used in `e- 02-nfs-anonymous-credential-exposure.md`. Unlike the FTP NSE scripts documented in `r-04- ftp-banner-grab-and-anonymous-access.md`, every NFS/RPC-related NSE script tested here worked correctly and reliably corroborated the manually-obtained findings; no detection gaps were observed in this instance.

## Remediation

See `e- 02-nfs-anonymous-credential-exposure.md` for the full remediation guidance (restricting exports to trusted hosts, enabling authentication, not storing credentials on an unauthenticated share). No additional remediation points arise specifically from the enumeration methodology itself.

## Teaching Notes

This activity pairs well with `r-04- ftp-banner-grab-and-anonymous-access.md` as a contrasting case study: where the FTP NSE scripts largely failed to corroborate manually-confirmed findings, the NFS/RPC NSE scripts here worked cleanly and consistently, and even offered genuine functional advantages over the manual toolchain (direct file listing and filesystem statistics without mounting). Students should take away that NSE script reliability varies significantly by protocol and script maturity, and that the correct habit is to test both manual and automated approaches on any new target rather than assuming either one is universally more or less trustworthy.

This is also a good opportunity to reinforce the RPC ephemeral port drift behaviour first observed in `r-02- reconnaissance-and-service-enumeration.md`: the specific high ports for `mountd`, `nlockmgr`, and `status` changed yet again between this activity's Step 1 and Step 3, despite being run only moments apart, further demonstrating that these port numbers are never a reliable target for direct connection or firewall rules, only the RPC program number is a stable identifier.

## Lab Dependencies

**Prerequisite exploit(s):** None (all commands run unauthenticated)
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (enumeration only; file contents observed via `nfs-ls` were not yet acted upon or correlated into credentials in this activity, that step is documented separately in `e- 02-nfs-anonymous-credential-exposure.md`)
**Provides access for:** Precedes and directly motivates `e- 02-nfs-anonymous-credential-exposure.md`
**Suggested teaching level:** Level 5 (RPC/NFS enumeration fundamentals, comparing manual and automated tooling, understanding RPC program numbers vs. ephemeral ports)

## What is RPC/NFS?

RPC (Remote Procedure Call) is a general mechanism that lets a program on one computer request a service from a program on another computer as if it were a local function call; `rpcbind` is the service that keeps track of which RPC programs are running on which ports. NFS (Network File System) is one of the most common services built on RPC, and lets a Linux/Unix server export directories that other machines can mount and use as if they were local folders, similar in purpose to Samba/SMB but native to the Unix world rather than Windows. NFS shares are common in real organisations for centralised storage and backups, and misconfigured exports (as investigated here) are a long-standing, still-common source of unauthorised access.
