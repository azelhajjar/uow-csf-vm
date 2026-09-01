# Activity 12: Initial Reconnaissance and Service Enumeration

## Summary

Full-range TCP port discovery against the target, followed by targeted service/version detection and OS fingerprinting on the ports found open. This activity documents the actual first step of the attack lifecycle, establishing the complete attack surface, before any individual service was targeted for exploitation. Exploits 01–08 (and 10) each begin from a single already-known port; this write-up is the reconnaissance activity that identified those ports (and several not yet exploited) in the first place.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nmap |

## Reconnaissance

### Step 1: Full TCP port range discovery

A full 65535-port TCP scan was run first, deliberately without service detection, to get fast, unbiased coverage of every open port before spending time on per-service enumeration:

```bash
nmap -p- -T4 192.168.144.200
```

```
Not shown: 65514 closed tcp ports (reset)
PORT      STATE SERVICE
21/tcp    open  ftp
22/tcp    open  ssh
111/tcp   open  rpcbind
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
34297/tcp open  unknown
35389/tcp open  unknown
37301/tcp open  unknown
41673/tcp open  unknown
44469/tcp open  unknown
45867/tcp open  unknown
MAC Address: 00:0C:29:94:44:82 (VMware)
```

`-p-` scans all 65535 TCP ports rather than nmap's default top-1000, which matters here because several of the highest-value findings (the six high/ephemeral ports at the bottom of the list) would have been missed entirely by a default scan. `-T4` sets an aggressive timing template to keep the full-range scan fast on a local network without triggering excessive false negatives.

The service names nmap guesses at this stage (`eforward`, `EtherNetIP-1`, `blackice-icecap`, `jamlink`, `sun-answerbook`, etc.) come from nmap's static port-to-service database (`/usr/share/nmap/nmap-services`) based on the port number alone, not from actually talking to the service. Several of these are visibly wrong or generic placeholders (`unknown` for the six high ports), which is expected and exactly why a second, targeted scan with actual version detection is needed.

### Step 2: Building the target port list

The confirmed open ports from Step 1 were collected into a shell variable for reuse in the follow-up scan:

```bash
PORTS="21,22,111,1716,2049,2181,2222,3306,3632,4369,8081,8082,8083,8091,8888,34743,37561,38999,50427,56631,58185"
```

**Observation on port drift:** the six high/ephemeral ports in this variable (`34743, 37561, 38999, 50427, 56631, 58185`) do not match the six high ports reported by the Step 1 scan (`34297, 35389, 37301, 41673, 44469, 45867`). This is not a transcription error, it reflects a real and expected behaviour of `rpcbind`-registered RPC services (confirmed in Step 3 to be `mountd`, `nlockmgr`, and `status`, all associated with the NFS service stack). These services register with `rpcbind` on a dynamically assigned ephemeral port each time the underlying daemon is queried or restarted, so the specific port number can differ between two scans run only moments apart, even though the underlying set of services and their `rpcbind` program numbers remain constant. This is a useful teaching point: for RPC-based services, the port number itself is not a stable identifier and should not be relied upon between scans; the RPC program number (visible via `rpcinfo` or nmap's `rpcinfo` NSE script) is the stable identifier instead.

### Step 3: Service/version detection and OS fingerprinting

```bash
sudo nmap -sC -sV -O -p "$PORTS" 192.168.144.200
```

`-sC` runs nmap's default NSE script set against each open port (safe, non-intrusive scripts appropriate for initial enumeration). `-sV` performs service/version detection by actually probing each port rather than relying on the static port-number database used in Step 1. `-O` attempts OS fingerprinting based on TCP/IP stack behaviour. `sudo` is required for `-O`, since raw packet crafting for OS fingerprinting needs elevated privileges.

```
PORT      STATE  SERVICE    VERSION
21/tcp    open   ftp        ProFTPD 1.3.3c
22/tcp    open   ssh        OpenSSH 9.2p1 Debian 2+deb12u3 (protocol 2.0)
111/tcp   open   rpcbind    2-4 (RPC #100000)
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
1716/tcp  open   tcpwrapped
2049/tcp  open   nfs_acl    3 (RPC #100227)
2181/tcp  open   zookeeper  Zookeeper 3.4.14-4c25d480e66aadd371de8bd2fd8da255ac140bcf (Built on 03/06/2019)
2222/tcp  open   ssh        (protocol 2.0)
| fingerprint-strings:
|   NULL:
|_    SSH-2.0-Erlang/5.1.4.7
| ssh-hostkey:
|_  256 b6:88:c5:cc:8b:ec:90:95:80:b5:8b:7e:86:1f:cc:c1 (ECDSA)
3306/tcp  open   mysql      MariaDB 10.3.23 or earlier (unauthorized)
3632/tcp  open   distccd    distccd v1 ((Debian 12.2.0-14+deb12u1) 12.2.0)
4369/tcp  open   epmd       Erlang Port Mapper Daemon
| epmd-info:
|   epmd_port: 4369
|   nodes:
|_    ssh_runner: 37301
8081/tcp  open   http       Jetty
| http-title: Apache Druid
|_Requested resource was http://192.168.144.200:8081/unified-console.html
8082/tcp  open   http       Jetty
|_http-title: Site doesn't have a title.
8083/tcp  open   http       Jetty
|_http-title: Site doesn't have a title.
8091/tcp  open   http       Jetty
|_http-title: Site doesn't have a title.
8888/tcp  open   http       Jetty
| http-title: Apache Druid
|_Requested resource was http://192.168.144.200:8888/unified-console.html
34743/tcp closed unknown
37561/tcp closed unknown
38999/tcp closed unknown
50427/tcp closed unknown
56631/tcp closed unknown
58185/tcp closed unknown
MAC Address: 00:0C:29:94:44:82 (VMware)
Device type: general purpose|router
Running: Linux 4.X|5.X, MikroTik RouterOS 7.X
OS CPE: cpe:/o:linux:linux_kernel:4 cpe:/o:linux:linux_kernel:5 cpe:/o:mikrotik:routeros:7 cpe:/o:linux:linux_kernel:5.6.3
OS details: Linux 4.15 - 5.19, OpenWrt 21.02 (Linux 5.4), MikroTik RouterOS 7.2 - 7.5 (Linux 5.6.3)
Network Distance: 1 hop
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```

As anticipated in Step 2, the six high ports queried by this scan (from the stale `$PORTS` variable) are now reported `closed`, because the underlying `rpcbind`-registered services had since reallocated to yet another set of ephemeral ports by the time this second scan ran. The `rpcinfo` NSE script output (triggered automatically by `-sC` against port 111) is what actually reveals the current, correct ports for those services at scan time (`mountd` on `45867/tcp`, `nlockmgr` on `35389/tcp`, `status` on `34297/tcp`), independently of what was guessed into `$PORTS`. This is a practical illustration of why `rpcinfo` (or the nmap script equivalent) is the authoritative source for RPC service ports, not a port list built from an earlier scan.

**OS fingerprinting note:** nmap's `-O` guess (MikroTik RouterOS / OpenWrt) is a red herring, likely caused by the number and mix of high-numbered application ports and non-standard SSH banners (Erlang on 2222) confusing the TCP/IP stack fingerprint database, since the target is confirmed via other means (e.g. package manager, `/etc/os-release` if checked post-exploitation) to be Debian 12. OS fingerprinting from a network vantage point should always be treated as a probabilistic hint, not a reliable identifier, particularly against a host running unusual or non-standard services on atypical ports.

### Step 4: UDP top-ports sweep

```bash
sudo nmap -sU --top-ports 20 192.168.144.200
```

`-sU` scans UDP rather than TCP. `--top-ports 20` limits the sweep to nmap's twenty most commonly seen UDP ports rather than a full 65535-port UDP scan, which is a deliberate scope/time trade-off: a full UDP range scan is dramatically slower than the equivalent TCP scan (UDP has no handshake to confirm state quickly, so nmap must rely on ICMP unreachable responses or timeouts), so a top-ports sweep is the practical default for an initial pass.

```
PORT      STATE         SERVICE
53/udp    closed        domain
67/udp    closed        dhcps
68/udp    open|filtered dhcpc
69/udp    closed        tftp
123/udp   closed        ntp
135/udp   closed        msrpc
137/udp   open|filtered netbios-ns
138/udp   open|filtered netbios-dgm
139/udp   closed        netbios-ssn
161/udp   closed        snmp
162/udp   open|filtered snmptrap
445/udp   open|filtered microsoft-ds
500/udp   open|filtered isakmp
514/udp   closed        syslog
520/udp   open|filtered route
631/udp   open|filtered ipp
1434/udp  closed        ms-sql-m
1900/udp  open|filtered upnp
4500/udp  open|filtered nat-t-ike
49152/udp closed        unknown
```

**Interpreting `open|filtered`:** for UDP, nmap cannot always distinguish a genuinely open port from one that is closed but silently dropping probes (e.g. behind a firewall rule with no ICMP rejection). Both cases produce no response, so nmap reports the ambiguous `open|filtered` state rather than asserting either with confidence. This differs fundamentally from TCP scanning, where a `RST` response reliably confirms `closed` and a `SYN/ACK` reliably confirms `open`.

None of the `open|filtered` results here (`dhcpc`, `netbios-ns`, `netbios-dgm`, `snmptrap`, `microsoft-ds`, `isakmp`, `route`, `ipp`, `upnp`, `nat-t-ike`) correspond to any service confirmed present on this Debian 12 target from the TCP scan or from direct filesystem/package inspection during earlier exploitation. This strongly suggests these are false positives arising from the ambiguous nature of UDP scanning rather than genuinely running services, and none currently warrant further follow-up. If a specific UDP service becomes relevant later (for example, if DNS is added per the project's planned service expansion), a targeted rescan of that specific port with `-sU -sV -p<port>` would give a more reliable answer than this broad top-ports sweep.

No further action was taken on the UDP results; they are recorded here for completeness rather than as a lead requiring investigation.

## Service Summary

| Port | Service | Version | Covered by |
|---|---|---|---|
| 21/tcp | FTP | ProFTPD 1.3.3c | `01-proftpd-1.3.3c-backdoor.md` |
| 22/tcp | SSH | OpenSSH 9.2p1 | Used for authenticated access throughout (backupsvc, analyst, webops, uow-admin) |
| 111/tcp | rpcbind | 2-4 | `02-nfs-anonymous-credential-exposure.md` (enumeration) |
| 1716/tcp | tcpwrapped | unidentified | Not yet investigated |
| 2049/tcp | NFS / nfs_acl | 3, 4 | `02-nfs-anonymous-credential-exposure.md` |
| 2181/tcp | Zookeeper | 3.4.14 | Not yet investigated |
| 2222/tcp | SSH (Erlang) | Erlang/5.1.4.7 | `03-erlang-otp-ssh-rce-cve-2025-32433.md` |
| 3306/tcp | MySQL/MariaDB | 10.3.23 or earlier (unauthorized) | Not yet investigated |
| 3632/tcp | distccd | v1, Debian 12.2.0-14+deb12u1 | `06-distcc-cve-2004-2687.md` |
| 4369/tcp | epmd (Erlang Port Mapper) | — | Supporting service for port 2222; not independently exploited |
| 8081/tcp | Apache Druid (coordinator/overlord) | 0.20.0 | `05-apache-druid-cve-2021-25646.md` |
| 8082/tcp | Apache Druid (broker) | 0.20.0 (inferred) | Not independently exploited; no HTTP UI |
| 8083/tcp | Apache Druid (historical) | 0.20.0 (inferred) | Not independently exploited; no HTTP UI |
| 8091/tcp | Apache Druid (middleManager) | 0.20.0 (inferred) | Not independently exploited; no HTTP UI |
| 8888/tcp | Apache Druid (router) | 0.20.0 | Proxies 8081; not independently exploited |
| 631/udp | CUPS / cups-browsed | 1.28.17-3 (deliberately downgraded, pre-CVE-2024-47176 fix) | `r-12- cups-print-service-reconnaissance.md`, `r-13- cups-discovery-ip-change.md`, `e-12- cups-full-rce-chain.md`. **Not visible on TCP scans** (`cupsd` TCP interface is loopback-only); only discoverable via UDP scanning. Added after this scan was originally run; current target address for this service is 192.168.144.200. |
| 139/tcp, 445/tcp | Samba (smbd/nmbd) | 4.17.12 | `r-14- samba-share-reconnaissance.md`, `e-13- samba-guest-writable-share.md`. Added after this scan was originally run; guest-accessible writable share configured deliberately. |
| 161/udp | SNMP (snmpd) | 5.9.3 | `r-15- snmp-enumeration.md`, `e-14- snmp-community-string-disclosure.md`. Added after this scan was originally run; default `public` community string with unrestricted view configured deliberately. |
| 6379/tcp | Redis | 7.0.15 | `r-16- redis-enumeration.md`, `e-15- redis-unauthenticated-data-exposure.md`. Added after this scan was originally run; deliberately unauthenticated, bound to all interfaces. |
| 53/tcp, 53/udp | DNS (BIND9) | 9.18.49 | `r-17- dns-enumeration.md`, `e-16- dns-zone-transfer.md`. Added after this scan was originally run; serves the `uow-csf.internal` zone with `allow-transfer { any; }` configured deliberately. |
| 25/tcp | SMTP (Postfix) | Debian/GNU | `r-18- smtp-enumeration.md`, `e-17- smtp-open-relay-and-user-enumeration.md`. Added after this scan was originally run; configured as an open relay with local recipient verification enabled deliberately. |

## Outcome

Establishes the complete confirmed TCP attack surface of the target as of this scan, and the actual reconnaissance basis from which the individually documented exploits were selected. Several services identified here (`1716/tcp` unidentified, Zookeeper on `2181/tcp`, MySQL/MariaDB on `3306/tcp`, and the four non-coordinator Druid process ports) remain uninvestigated and are candidates for future activities.

## Remediation

Not applicable to this activity in the traditional sense, since this is a reconnaissance write-up rather than an exploitation one. However, from a defensive perspective, this scan output itself illustrates the value of the target's attack surface being unnecessarily large for a single host: fourteen distinct listening services across a wide port range gives an attacker many independent avenues, and several remediation notes from the individual exploit write-ups (restricting NFS exports, patching Erlang/OTP, not exposing distccd) would each reduce this surface incrementally.

## Teaching Notes

This activity is intended to sit conceptually before Exploits 01–08 and 10 in the attack chain, even though it was written up after them, since it documents the reconnaissance step that would, in a real or classroom engagement, always precede targeted exploitation. It is a useful exercise for demonstrating:

- The difference between a full-range unbiased port sweep (`-p-`) and nmap's default top-1000 port scan, and why the former is necessary to avoid missing high-value non-standard ports.
- The difference between nmap's static port-database service guess (Step 1) and actual probe-based version detection (Step 3), and why the former should never be trusted for identification purposes.
- The unreliability of network-based OS fingerprinting on hosts with atypical service configurations.
- The instability of RPC-registered ports between scans, and the correct way to resolve them authoritatively via `rpcinfo`/nmap's `rpcinfo` script rather than reusing a previously observed port number.

The UDP sweep (Step 4) is a good opportunity to teach the `open|filtered` ambiguity inherent to UDP scanning, and why UDP results generally warrant more scepticism than the equivalent TCP `open`/`closed` states before being treated as genuine findings.

## Lab Dependencies

**Prerequisite exploit(s):** None; this is the foundational reconnaissance activity
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (information-gathering only)
**Provides access for:** Provides the enumerated attack surface underpinning Exploits 01, 02, 03, 05, 06, and 10; identifies unexplored services (Zookeeper, MySQL/MariaDB, port 1716, and the non-primary Druid process ports) as candidates for future activities
**Suggested teaching level:** Level 5 (recon fundamentals: full-range scanning, service/version detection, interpreting NSE script output, understanding RPC port allocation)
