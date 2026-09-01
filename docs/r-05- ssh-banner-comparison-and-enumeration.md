# Activity: SSH Banner Comparison and Enumeration (Ports 22 and 2222)

## Summary

The target exposes two distinct services that speak the SSH protocol, on port 22 and port 2222. A naive port scan might treat both as "SSH" and assume they are two instances of the same software, but manual banner grabbing, verbose client negotiation, and dedicated NSE enumeration scripts together reveal they are entirely unrelated implementations: port 22 is the genuine OpenSSH system daemon, while port 2222 is an Erlang/OTP application that happens to implement the SSH wire protocol for its own purposes, and is the deliberately vulnerable service exploited separately in `e-03- erlang-otp-ssh-rce-cve-2025-32433.md`. This activity documents the full enumeration performed to distinguish the two before any exploitation was attempted, and reflects the pre-credential stage of the engagement (no valid username/password for either service was known at this point).

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.200 |
| Services | OpenSSH 9.2p1 (port 22/tcp), Erlang/OTP SSH daemon (port 2222/tcp) |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nc, ssh (verbose mode), nmap NSE (`ssh2-enum-algos`, `ssh-hostkey`, `ssh-auth-methods`), Metasploit (`auxiliary/scanner/ssh/ssh_version`) |

## Reconnaissance

### Step 1: Banner grab on both ports

```bash
nc -nv 192.168.144.200 22
```

```
Connection to 192.168.144.200 22 port [tcp/*] succeeded!
SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u3
```

```bash
nc -nv 192.168.144.200 2222
```

```
Connection to 192.168.144.200 2222 port [tcp/*] succeeded!
SSH-2.0-Erlang/5.1.4.7
```

The SSH protocol requires the server to send its identification string immediately upon connection, before any authentication takes place, which is why a raw `nc` connection is sufficient to retrieve it without an actual SSH client. The two banners are immediately and obviously different: `OpenSSH_9.2p1 Debian-2+deb12u3` versus `Erlang/5.1.4.7`. The word "SSH" in both is only the protocol identifier; the software behind each banner is unrelated. `Erlang/5.1.4.7` is not an OpenSSH fork or variant, it is Erlang/OTP's own SSH implementation, part of Erlang's standard library, used here to expose a remote shell interface for an Erlang application rather than for general system login.

### Step 2: Verbose SSH client negotiation against port 22

```bash
ssh -v 192.168.144.200
```

Key extracts from the verbose output:

```
debug1: Remote protocol version 2.0, remote software version OpenSSH_9.2p1 Debian-2+deb12u3
debug1: compat_banner: match: OpenSSH_9.2p1 Debian-2+deb12u3 pat OpenSSH* compat 0x04000000
debug1: kex: algorithm: sntrup761x25519-sha512@openssh.com
debug1: kex: host key algorithm: ssh-ed25519
debug1: Server host key: ssh-ed25519 SHA256:2MdHKbBhDT7XOqkHN3l3i9vEqRBVxfE1OUYelVLneY0
debug1: Authentications that can continue: publickey,password
```

This confirms port 22 is a standard, modern OpenSSH configuration: the client and server successfully negotiate a post-quantum-resistant key exchange (`sntrup761x25519-sha512@openssh.com`), consistent with a fully up-to-date OpenSSH build, and offers the conventional `publickey,password` authentication methods. No warnings or anomalies were raised by the client at any point in this negotiation. The connection was deliberately not completed (no password was supplied), since at this stage of the engagement no valid credentials for any account were yet known; the goal here is purely to observe the service's identity and configuration, not to attempt access.

### Step 3: Verbose SSH client negotiation against port 2222

```bash
ssh -v -p 2222 192.168.144.200
```

Key extracts:

```
debug1: Remote protocol version 2.0, remote software version Erlang/5.1.4.7
debug1: compat_banner: no match: Erlang/5.1.4.7
debug1: kex: algorithm: curve25519-sha256
debug1: kex: host key algorithm: ecdsa-sha2-nistp256
debug1: Server host key: ecdsa-sha2-nistp256 SHA256:EVMOG+b2gu9/3kEs1r5DrUMwfdgDjoj5wAnYB5yptwU
The authenticity of host '[192.168.144.200]:2222 ([192.168.144.200]:2222)' can't be established.
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
debug1: Authentications that can continue: publickey,keyboard-interactive,password
debug1: Next authentication method: keyboard-interactive
SSH server
Enter password for "kali"
```

Several meaningful differences from port 22 emerge here:

- **`compat_banner: no match: Erlang/5.1.4.7`** — the OpenSSH client's internal compatibility database has no entry for this software at all, confirming it recognises this as genuinely different software rather than a themed or renamed OpenSSH build.
- **Different key exchange algorithm negotiated** — `curve25519-sha256` rather than the post-quantum `sntrup761x25519-sha512@openssh.com` used against port 22, triggering the client's own security warning about the connection not using a post-quantum-resistant algorithm. This is expected for an older or differently-implemented SSH stack (Erlang's `ssh` module) rather than a deliberately weakened configuration, but is still a genuine, observable difference in security posture between the two services.
- **Different host key type** — `ecdsa-sha2-nistp256` on port 2222 versus `ssh-ed25519` on port 22, again consistent with two entirely independent SSH implementations rather than the same daemon running twice.
- **Additional authentication method offered**: `publickey,keyboard-interactive,password` on port 2222 versus just `publickey,password` on port 22. The presence of `keyboard-interactive` here is consistent with Erlang's SSH daemon implementation and its own custom prompt ("SSH server / Enter password for..."), visibly different in wording from OpenSSH's standard password prompt.
- **Non-standard prompt text**: `Enter password for "kali"` framed under a literal `SSH server` banner line is distinctive and clearly not OpenSSH's usual prompt format, a further confirmation this is bespoke Erlang application code rather than a patched or re-banded OpenSSH.

As with port 22, this connection was not completed; no password was supplied, and this step was purely to observe and compare the service's negotiation behaviour without attempting authentication.

### Step 4: NSE-based algorithm, host key, and authentication method enumeration

The verbose `ssh -v` client output in Steps 2 and 3 only shows the single algorithm actually *negotiated* for each category (the first mutually supported option from each side's ordered preference list), not the full set of algorithms each server is willing to offer. To see the complete picture, three NSE scripts were run against both ports together.

```bash
nmap -p 22,2222 --script ssh2-enum-algos 192.168.144.200
```

```
22/tcp   open  ssh
| ssh2-enum-algos:
|   kex_algorithms: (11)
|       sntrup761x25519-sha512@openssh.com
|       curve25519-sha256
|       curve25519-sha256@libssh.org
|       ecdh-sha2-nistp256
|       ecdh-sha2-nistp384
|       ecdh-sha2-nistp521
|       diffie-hellman-group-exchange-sha256
|       diffie-hellman-group16-sha512
|       diffie-hellman-group18-sha512
|       diffie-hellman-group14-sha256
|       kex-strict-s-v00@openssh.com
|   server_host_key_algorithms: (4)
|       rsa-sha2-512
|       rsa-sha2-256
|       ecdsa-sha2-nistp256
|       ssh-ed25519
|   encryption_algorithms: (6)
|       chacha20-poly1305@openssh.com
|       aes128-ctr
|       aes192-ctr
|       aes256-ctr
|       aes128-gcm@openssh.com
|       aes256-gcm@openssh.com
|   mac_algorithms: (10)
|       umac-64-etm@openssh.com
|       umac-128-etm@openssh.com
|       hmac-sha2-256-etm@openssh.com
|       hmac-sha2-512-etm@openssh.com
|       hmac-sha1-etm@openssh.com
|       umac-64@openssh.com
|       umac-128@openssh.com
|       hmac-sha2-256
|       hmac-sha2-512
|       hmac-sha1
|   compression_algorithms: (2)
|       none
|_      zlib@openssh.com
2222/tcp open  EtherNetIP-1
| ssh2-enum-algos:
|   kex_algorithms: (12)
|       curve25519-sha256
|       curve25519-sha256@libssh.org
|       curve448-sha512
|       ecdh-sha2-nistp521
|       ecdh-sha2-nistp384
|       ecdh-sha2-nistp256
|       diffie-hellman-group-exchange-sha256
|       diffie-hellman-group16-sha512
|       diffie-hellman-group18-sha512
|       diffie-hellman-group14-sha256
|       ext-info-s
|       kex-strict-s-v00@openssh.com
|   server_host_key_algorithms: (3)
|       ecdsa-sha2-nistp256
|       rsa-sha2-512
|       rsa-sha2-256
|   encryption_algorithms: (10)
|       aes256-gcm@openssh.com
|       aes256-ctr
|       aes192-ctr
|       aes128-gcm@openssh.com
|       aes128-ctr
|       chacha20-poly1305@openssh.com
|       aes256-cbc
|       aes192-cbc
|       aes128-cbc
|       3des-cbc
|   mac_algorithms: (6)
|       hmac-sha2-512-etm@openssh.com
|       hmac-sha2-256-etm@openssh.com
|       hmac-sha2-512
|       hmac-sha2-256
|       hmac-sha1-etm@openssh.com
|       hmac-sha1
|   compression_algorithms: (3)
|       none
|       zlib@openssh.com
|_      zlib
```

`ssh2-enum-algos` connects to the target, initiates the SSH key exchange handshake, and reports the complete `KEXINIT` payload each server sends, every kex algorithm, host key type, cipher, MAC, and compression method it is willing to negotiate, rather than only the one algorithm actually chosen. This gives a materially fuller picture than the earlier `ssh -v` output:

- **Port 22 offers `sntrup761x25519-sha512@openssh.com`** (a post-quantum-resistant hybrid key exchange) as its top preference, consistent with a genuinely current OpenSSH build. Port 2222 does **not** offer this algorithm at all, its strongest offering is the classical `curve25519-sha256`, confirming again that this is an older or independently-implemented SSH stack rather than a recent OpenSSH release.
- **Port 2222 uniquely offers `3des-cbc`** among its encryption algorithms, a legacy cipher considered weak by modern standards (64-bit block size, vulnerable to birthday-bound attacks such as SWEET32 in high-volume scenarios) and one that current OpenSSH releases no longer offer by default. Its presence here is a genuine, independently-observable weakness of the Erlang SSH implementation, separate from the CVE-2025-32433 RCE vulnerability it is otherwise known for.
- **Port 2222 also offers `ext-info-s`** in its kex algorithm list, an SSH extension-negotiation marker rather than a true key exchange algorithm, again typical of certain non-OpenSSH SSH library implementations advertising protocol extension support.
- Both ports support `chacha20-poly1305@openssh.com` as an encryption option and share several MAC algorithms, indicating enough protocol-level interoperability for either to be usable by a generic SSH client, despite being fundamentally different implementations.

```bash
nmap -p 22,2222 --script ssh-hostkey --script-args ssh_hostkey=full 192.168.144.200
```

```
22/tcp   open  ssh
| ssh-hostkey:
|   ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC1bksBn49+p5xjSV77gPWxyeTuBYwP5mSIWq1VF/OF9GOfWHMJNE5gzLZhawEYlNob4aZ2OwaH34KMI3faNc4E=
|_  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIqoUh7c1dPl0/wpg/Y3atabtH/Y48Bn/WJHHPh+6h0h
2222/tcp open  EtherNetIP-1
| ssh-hostkey:
|_  ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEV9hhmUSzxzUXM/eRWvcqJry2zUlG9dZRL61lzADl1PK4l4qRZNQ1HmbV5PYqKyxwKs7/+Ztsu8V0Xp8q6lWOU=
```

The `ssh_hostkey=full` script argument prints the complete base64-encoded public key material rather than just the abbreviated SHA256 fingerprint seen in the earlier `ssh -v` output. Port 22 presents two host keys (`ecdsa-sha2-nistp256` and `ssh-ed25519`), a normal OpenSSH configuration where multiple key types are generated so the server can negotiate whichever type the connecting client prefers. Port 2222 presents only a single host key type (`ecdsa-sha2-nistp256`), consistent with the more limited `server_host_key_algorithms` list already seen in the `ssh2-enum-algos` output for that port (three algorithms offered, but backed by only one actual key). The two `ecdsa-sha2-nistp256` keys shown are visibly different base64 values, confirming these are two independently generated key pairs, not the same host key reused across both services.

```bash
nmap -p 22,2222 --script ssh-auth-methods 192.168.144.200
```

```
22/tcp   open  ssh
| ssh-auth-methods:
|   Supported authentication methods:
|     publickey
|_    password
2222/tcp open  EtherNetIP-1
| ssh-auth-methods:
|   Supported authentication methods:
|     publickey
|     keyboard-interactive
|_    password
```

This directly confirms, via a dedicated enumeration script rather than by reading through verbose client debug output, that port 2222 offers one additional authentication method (`keyboard-interactive`) not offered by port 22. This matches the custom `SSH server` / `Enter password for "kali"` prompt observed manually in Step 3, keyboard-interactive authentication is what allows an SSH server to present arbitrary custom prompts rather than being restricted to the standard password exchange, which is exactly the mechanism Erlang's SSH daemon uses for its bespoke login sequence.

**Note on nmap's service label for port 2222:** nmap's output continues to display `EtherNetIP-1` as the guessed service name for port 2222 in these results, this is the same static port-database guess seen in the original full-range scan (`r-02- reconnaissance-and-service-enumeration.md`) and is incorrect; it is included here only because it is nmap's default column output, not because it reflects the actual service. The `ssh2-enum-algos`, `ssh-hostkey`, and `ssh-auth-methods` script results themselves all correctly interacted with and enumerated the real SSH-protocol service running on that port, regardless of the misleading label nmap prints alongside it.

### Cross-check: Metasploit `ssh_version` module

For a further comparison against a different tool, Metasploit's own SSH version-scanning module was run against both ports.

```
use auxiliary/scanner/ssh/ssh_version
set RHOSTS 192.168.144.200
set RPORT 22
run
```

```
[*] 192.168.144.200 - SSH server version: SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u3
[*] 192.168.144.200 - Server Information and Encryption
=================================
  Type                     Value                                 Note
  ----                     -----                                 ----
  encryption.host_key      ecdsa-sha2-nistp256                   Weak elliptic curve
  encryption.host_key      ssh-ed25519
  encryption.key_exchange  sntrup761x25519-sha512@openssh.com
  ...
  os.cpe23                 cpe:/o:debian:debian_linux:12.0
  os.family                Linux
  os.product               Linux
  os.vendor                Debian
  os.version               12.0
  service.cpe23            cpe:/a:openbsd:openssh:9.2p1
  service.product          OpenSSH
  service.vendor           OpenBSD
  service.version          9.2p1
```

```
set RPORT 2222
run
```

```
[*] 192.168.144.200 - SSH server version: SSH-2.0-Erlang/5.1.4.7
[*] 192.168.144.200 - Server Information and Encryption
=================================
  Type                     Value                                 Note
  ----                     -----                                 ----
  encryption.encryption    aes256-cbc                            Deprecated
  encryption.encryption    aes192-cbc                            Deprecated
  encryption.encryption    aes128-cbc                            Deprecated
  encryption.encryption    3des-cbc                              Deprecated
  encryption.host_key      ecdsa-sha2-nistp256                   Weak elliptic curve
```

This module produces largely the same underlying algorithm data as nmap's `ssh2-enum-algos`, but with two notable differences worth highlighting for teaching purposes:

- **Metasploit automatically annotates weak or deprecated algorithms inline** (`Weak elliptic curve` next to `ecdsa-sha2-nistp256`; `Deprecated` next to every CBC-mode cipher and `3des-cbc` on port 2222), whereas nmap's `ssh2-enum-algos` simply lists every algorithm without commentary, leaving the analyst to independently recognise which entries represent weaknesses. This is a genuine usability advantage for less experienced analysts, though it also means relying on such annotations without understanding the underlying reasoning risks missing context a script's author did or didn't choose to flag.
- **Metasploit's module performed OS and service fingerprinting from the SSH banner and host key data**, correctly identifying `os.vendor: Debian`, `os.version: 12.0`, and the precise OpenSSH/OpenBSD service attribution for port 22, using its own `recog` fingerprint database. This is additional derived intelligence beyond what nmap's SSH-specific scripts provided in this activity, though it duplicates (and confirms) the OS information nmap's own `-O` flag had already suggested elsewhere with far less confidence, in `r-02- reconnaissance-and-service-enumeration.md`, nmap's `-O` guess was a red herring (MikroTik RouterOS), whereas Metasploit's SSH-banner-based fingerprinting correctly and confidently identified Debian 12.

Notably, no equivalent `os.*`/`service.*` fingerprint fields were returned for port 2222, consistent with Metasploit's `recog` database (like OpenSSH's own client compatibility database observed earlier) having no specific signature for the Erlang SSH implementation, again reinforcing that this is genuinely unrecognised, non-standard software from the perspective of mainstream SSH tooling.

## Outcome

Confirmed that ports 22 and 2222 host two entirely unrelated pieces of software that merely share the SSH wire protocol. Port 22 is a standard, current OpenSSH installation with no anomalies observed, offering post-quantum key exchange and multiple modern host key types. Port 2222 is an Erlang/OTP SSH daemon, distinguishable by its banner, unmatched client compatibility string, absence of post-quantum key exchange, presence of the legacy `3des-cbc` cipher, a single host key type, and a distinctive `keyboard-interactive`-driven custom authentication prompt; this is the same service later confirmed vulnerable to CVE-2025-32433 and exploited in `e-03- erlang-otp-ssh-rce-cve-2025-32433.md`. No credentials were used or obtained during this activity; it represents the enumeration phase that precedes and motivates that exploit, rather than a continuation of it.

## Remediation

- Do not expose an Erlang/OTP SSH-protocol interface on a routable or easily scannable port unless strictly necessary; if required for legitimate administrative purposes, bind it to loopback only or restrict access via firewall rules to specific management hosts.
- Where a non-OpenSSH service must expose an SSH-compatible interface, ensure it is kept patched to the same standard as would be expected of OpenSSH itself; the underlying vulnerability here (CVE-2025-32433) stems from outdated Erlang/OTP SSH library code, not from the concept of using Erlang's SSH module itself.
- Remove legacy, weak ciphers such as `3des-cbc` from the Erlang SSH daemon's offered algorithm list where the implementation allows it to be configured; offering deprecated ciphers increases the attack surface for downgrade-style attacks even where the client ultimately negotiates a stronger option.
- More generally, running two distinct services that both present as "SSH" on the same host is a legitimate but often confusing configuration; where both are operationally required, clear internal documentation of which port serves which purpose reduces the risk of administrators or automated tooling mistaking one for the other.

## Teaching Notes

This activity is a strong demonstration of why banner grabbing and manual protocol interaction matter even when a port scanner has already labelled two ports with the same service name. Nmap's own scan (`r-02- reconnaissance-and-service-enumeration.md`) correctly distinguished the two via version detection, but a student relying only on the coarse `ssh` service label from a basic port scan (rather than `-sV` output) could easily assume both ports are the same service and treat them identically, missing the fact that one is a fully patched standard daemon and the other is bespoke application code with its own, independent vulnerability history.

The verbose `ssh -v` client output is also a good teaching tool in its own right: it exposes the full protocol negotiation (key exchange algorithm selection, host key type, authentication methods offered) that is normally hidden during an ordinary login, and shows how the SSH client's own compatibility database and security warnings (the post-quantum key exchange warning) can themselves be a source of reconnaissance information about the server's age and implementation.

The NSE-based enumeration (Step 4) builds on this further and is worth emphasising as a distinct skill from reading verbose client debug output: `ssh2-enum-algos`, `ssh-hostkey`, and `ssh-auth-methods` each extract a single, specific piece of information cleanly and are far quicker to run and interpret at scale than manually working through `ssh -v` output, particularly if enumerating many hosts. Students should come away understanding that `ssh -v` and dedicated NSE scripts are complementary techniques: the former gives an authentic view of what a real client actually negotiates, while the latter gives a complete inventory of everything a server is willing to offer, which is more useful for spotting weak or legacy configuration options (such as the `3des-cbc` cipher found here) that would never be surfaced by an ordinary client connection, since a modern client would simply never choose to negotiate them.

Also worth noting for students: nmap's own service-name column continued to mislabel port 2222 as `EtherNetIP-1` throughout this entire enumeration, even while the SSH-specific NSE scripts correctly interacted with and fingerprinted the real underlying service. This reinforces the lesson from `r-02- reconnaissance-and-service-enumeration.md` that nmap's default service guess is not authoritative and should never be relied upon over the actual script/probe output.

The Metasploit cross-check adds a further comparison point: two independent tools (nmap NSE and Metasploit) converged on the same underlying algorithm data for both ports, giving confidence that this specific information is reliably and consistently obtainable regardless of which tool is used, unlike the FTP anonymous-access finding in `r-04- ftp-banner-grab-and-anonymous-access.md`, where the two tools disagreed and required explicit reconciliation. Students should note the contrast: when multiple independent tools agree, confidence in a finding increases considerably; when they disagree, as with the FTP case, further investigation is warranted before drawing a conclusion either way. Metasploit's additional OS/service fingerprinting (correctly identifying Debian 12 from the SSH banner and host key) is also a useful demonstration that different tools bring different strengths even when covering overlapping ground, nmap's OS detection (`r-02`) was unreliable here, while Metasploit's SSH-specific fingerprinting was accurate, illustrating that the right tool for a given fingerprinting task is not always the most general-purpose one.

## Lab Dependencies

**Prerequisite exploit(s):** None (no credentials required or used)
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (enumeration only; no authentication attempted or completed on either service)
**Provides access for:** Precedes and motivates `e-03- erlang-otp-ssh-rce-cve-2025-32433.md`, which exploits the Erlang SSH service identified and distinguished here
**Suggested teaching level:** Level 5 (banner grabbing, distinguishing services by protocol negotiation detail rather than port-scanner labels alone)

## What is SSH?

SSH (Secure Shell) is the standard protocol for securely logging into and administering remote systems over a network, providing an encrypted replacement for older, insecure protocols like Telnet. Almost every Linux/Unix server exposes SSH for remote administration, making it one of the most consistently present and heavily targeted services on any network. Because SSH is so ubiquitous, any software that also happens to speak the SSH protocol (as seen in this activity) can easily be mistaken for the genuine system service unless properly enumerated and compared.
