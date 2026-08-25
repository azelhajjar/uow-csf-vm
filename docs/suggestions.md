# Further Tools to Try

A list of tools preinstalled on Kali that were **not** used in the documented reconnaissance/exploitation activities on this VM. Intended as a self-directed appendix for students to explore independently once they've completed the guided activities for a given service, not something covered or demonstrated in the lab write-ups themselves.

## General / Cross-Service

- **`autorecon`** — automated multi-service recon orchestrator; runs many of the individual tools below automatically and organises output by host/port. Good for comparing an automated "run everything" approach against the deliberate, tool-by-tool method used throughout the lab activities.
- **`legion`** — GUI-based recon automation tool, similar purpose to AutoRecon.
- **`netdiscover`** — alternative to `arp-scan` for host discovery.

## FTP

- **`hydra`** — brute-force login attempts against FTP (and most other services below); useful once the significance of anonymous access is understood, as a contrast against brute-forcing a service that requires real credentials.
- **`lftp`** / **`wget -r ftp://...`** — bulk mirroring of an entire anonymous FTP share, rather than manual interactive browsing.

## SSH

- **`ssh-audit`** — dedicated SSH configuration auditing tool; produces a more opinionated security report than manual `ssh2-enum-algos` interpretation alone.
- **`hydra`** / **`medusa`** — credential brute-forcing against SSH, once a candidate username list exists (e.g. from SMTP enumeration).

## RPC/NFS

- **`rpcclient`** — deeper RPC interaction than `rpcinfo`/`showmount` alone (more commonly associated with SMB/Windows RPC, but worth exploring for comparison).
- Independently investigating whether any NFS export permits write access, and what that would enable.

## distcc

- No strong additional native Kali tooling beyond what's already covered (`nc`, NSE, Metasploit). Students could explore writing a minimal raw-socket PoC to understand the distcc protocol at a lower level than Metasploit/NSE abstracts.

## MySQL/MariaDB

- **`hydra`** — credential brute-forcing (would hit the same host-based access restriction already documented; a useful thing to observe and explain rather than something expected to succeed).

## Zookeeper / Apache Druid

- **`whatweb`** — automated web technology fingerprinting, faster than manual header/response inspection.
- **`gobuster`** / **`ffuf`** — directory and endpoint brute-forcing against the Druid HTTP ports, since Druid's API surface was not deeply explored beyond the known RCE.

## CUPS

- No strong additional native Kali attack tooling beyond what's already covered; the PoC repository and Metasploit module remain the realistic options for the full chain.

## Samba

- **`enum4linux-ng`** — modern, actively maintained replacement for the classic `enum4linux`; performs deep SMB/domain enumeration (shares, users, groups, policies) in a single pass.
- **`smbmap`** — quick, readable per-share permission enumeration across a host.
- **`netexec`** (formerly `crackmapexec`) — broad SMB enumeration and credential-spraying, standard tooling in real engagements.
- **`rpcclient`** — low-level SMB/RPC interaction beyond what `smbclient` alone offers.

## SNMP

- **`onesixtyone`** — fast SNMP community-string brute-forcer/scanner, a good comparison against Metasploit's `snmp_login`.
- **`snmp-check`** — produces a structured, readable summary report from a single command, worth comparing against raw `snmpwalk` output.

## Redis

- **`redis-cli --scan`** — a non-blocking alternative to `KEYS *`, worth adopting as correct practice even though `KEYS *` is safe to use in this isolated lab.

## DNS

- **`dnsrecon`** — automated DNS enumeration covering zone transfers, brute-forcing, and more in a single tool.
- **`dnsenum`** — similar purpose to `dnsrecon`, different implementation; useful to compare output between the two.
- **`fierce`** — domain reconnaissance tool with a different enumeration approach again.

## SMTP

- **`swaks`** (Swiss Army Knife for SMTP) — a purpose-built SMTP testing tool, considerably cleaner than raw `nc` for constructing relay tests and enumeration attempts once the underlying protocol is understood manually.




