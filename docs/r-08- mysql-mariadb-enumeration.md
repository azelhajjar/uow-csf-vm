# Activity: MySQL/MariaDB Enumeration

## Summary

Enumeration of the MariaDB service on port 3306, previously identified only by version banner in `r-02- reconnaissance-and-service-enumeration.md` and otherwise untouched. Every connection attempt against this service, whether via raw netcat, the standard `mysql` client, nmap NSE scripts, or Metasploit auxiliary modules, was consistently rejected at the network/host level before any authentication was attempted, due to MariaDB's built-in host-based access control. Six independent tools/methods confirmed the identical restriction. One Metasploit module (`mysql_login`) produced an internally contradictory and ultimately false-positive result claiming a successful login, which was identified as such through direct manual verification rather than accepted at face value, a valuable demonstration of why every automated finding, positive or negative, should be independently corroborated before being trusted.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | MariaDB, port 3306/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nc, mysql client, nmap NSE (`mysql-info`, `mysql-empty-password`, `mysql-vuln-cve2012-2122`), Metasploit (`auxiliary/scanner/mysql/mysql_version`, `auxiliary/scanner/mysql/mysql_login`, `auxiliary/scanner/mysql/mysql_authbypass_hashdump`) |

## Reconnaissance

### Step 1: Manual protocol probe

Unlike distcc, MySQL/MariaDB sends a protocol handshake packet immediately on connection, without requiring the client to speak first. A raw netcat connection was sufficient to observe this:

```bash
nc -nv 192.168.144.200 3306
```

```
Connection to 192.168.144.200 3306 port [tcp/*] succeeded!
J.jHost '192.168.144.129' is not allowed to connect to this MariaDB server
```

**This is the key finding of this entire activity, surfacing at the very first step.** Rather than the expected initial handshake packet (which would normally include the server's version string, a connection ID, and supported capability flags, exactly the kind of information nmap's `-sV` version probe parses to report `MariaDB 10.3.23 or earlier`), the server immediately returned an error packet stating the connecting host is not permitted to connect at all. Some binary handshake bytes (`J.j` and similar) precede the readable error text; these are protocol framing bytes (packet length and sequence number) rather than meaningful content.

This confirms MariaDB is enforcing **host-based access control** (MySQL/MariaDB's own `Host` column restriction in its internal `mysql.user` grant table) against the connecting client's source IP, rejecting the connection before any username or password is even requested. This is a fundamentally different, and earlier, rejection point than an authentication failure; the server never asked for credentials at all, because it decided the client's network origin was not permitted to proceed to that stage.

### Step 2: Discovering available NSE tooling

```bash
ls -l /usr/share/nmap/scripts/ | grep -i mysql
```

```
-rw-r--r-- 1 root root  6688 Apr  9 10:18 mysql-audit.nse
-rw-r--r-- 1 root root  2977 Apr  9 10:18 mysql-brute.nse
-rw-r--r-- 1 root root  2945 Apr  9 10:18 mysql-databases.nse
-rw-r--r-- 1 root root  3263 Apr  9 10:18 mysql-dump-hashes.nse
-rw-r--r-- 1 root root  2020 Apr  9 10:18 mysql-empty-password.nse
-rw-r--r-- 1 root root  3413 Apr  9 10:18 mysql-enum.nse
-rw-r--r-- 1 root root  3455 Apr  9 10:18 mysql-info.nse
-rw-r--r-- 1 root root  3714 Apr  9 10:18 mysql-query.nse
-rw-r--r-- 1 root root  2811 Apr  9 10:18 mysql-users.nse
-rw-r--r-- 1 root root  3265 Apr  9 10:18 mysql-variables.nse
-rw-r--r-- 1 root root  6977 Apr  9 10:18 mysql-vuln-cve2012-2122.nse
```

A substantially larger tool set exists for MySQL/MariaDB than was available for distcc, reflecting how much more commonly targeted and well-understood the MySQL wire protocol is. Three scripts were selected for this activity based on their relevance to what could plausibly be checked without existing credentials: `mysql-info` (basic version/capability enumeration, a safe default-style check), `mysql-empty-password` (checks whether any account, most commonly `root`, accepts an empty password), and `mysql-vuln-cve2012-2122` (a specific, well-known authentication-bypass vulnerability in certain older MySQL/MariaDB builds, arising from an unsafe `memcmp()`-based password comparison that can, under certain library/platform conditions, be bypassed by repeated connection attempts).

### Step 3: Safe default version/service scan

```bash
nmap -sV -p 3306 --script default 192.168.144.200
```

```
PORT     STATE SERVICE VERSION
3306/tcp open  mysql   MariaDB 10.3.23 or earlier (unauthorized)
```

Nmap's own version probe explicitly reports `(unauthorized)` alongside the version guess, nmap's version-detection engine encountered the same host-restriction error observed manually in Step 1, and inferred the approximate version from the error packet's protocol version field rather than from a full, successful handshake. This is a good example of nmap extracting partial, still-useful information (`MariaDB 10.3.23 or earlier`) even from a connection that was ultimately rejected.

### Step 4: Standard client connection attempt

```bash
mysql -h 192.168.144.200 -u root
```

```
ERROR 2002 (HY000): Received error packet before completion of TLS handshake. The authenticity of the following error cannot be verified: 1130 - Host '192.168.144.129' is not allowed to connect to this MariaDB server
```

The standard `mysql` command-line client reaches the identical conclusion via a different path: it also receives the host-restriction error (MySQL/MariaDB error code `1130`, the standard internal error number for exactly this host-access-denied condition) before any TLS negotiation or password prompt occurs. No username or password was requested at any point, since the connection was rejected before authentication was even reachable.

### Step 5: NSE script confirmation

```bash
nmap -p 3306 --script mysql-info 192.168.144.200
```

```
PORT     STATE SERVICE
3306/tcp open  mysql
```

`mysql-info` produced no output at all when run in isolation. Since this script relies on parsing the initial handshake packet for server details, and that handshake never completes due to the host restriction, the script has nothing to report; this is a genuine, explainable silent result (consistent with the underlying cause already established in Step 1), not the same kind of unexplained detection gap observed with the FTP scripts in `r-04- ftp-banner-grab-and-anonymous-access.md`.

```bash
nmap -p 3306 --script mysql-empty-password 192.168.144.200
```

```
PORT     STATE SERVICE
3306/tcp open  mysql
|_mysql-empty-password: Host '192.168.144.129' is not allowed to connect to this MariaDB server
```

This script, unlike `mysql-info`, does surface the host-restriction error message directly in its output, giving a fourth independent confirmation of the same underlying finding.

```bash
nmap -p 3306 --script mysql-vuln-cve2012-2122 192.168.144.200
```

```
PORT     STATE SERVICE
3306/tcp open  mysql
```

No output was produced. Since this vulnerability check also depends on being able to attempt an authentication exchange in the first place (repeatedly, to test the flawed comparison logic), and the host restriction prevents authentication from ever being attempted at all, this script cannot meaningfully test for the vulnerability here; its silence is explainable by the same root cause rather than indicating either a positive or negative result for CVE-2012-2122 specifically.

### Cross-check: Metasploit MySQL auxiliary modules

To further test the host-restriction finding with independent tooling, and to check specifically for the CVE-2012-2122 authentication bypass using a purpose-built module, three Metasploit auxiliary modules were run against the same service.

```
use auxiliary/scanner/mysql/mysql_version
set RHOSTS 192.168.144.200
run
```

```
[*] 192.168.144.200:3306 - 192.168.144.200:3306 is running MySQL, but responds with an error: \x04Host '192.168.144.129' is not allowed to connect to this MariaDB server
[*] 192.168.144.200:3306 - Scanned 1 of 1 hosts (100% complete)
```

A fifth independent confirmation of the identical host-restriction finding, consistent with every method tried so far.

```
use auxiliary/scanner/mysql/mysql_authbypass_hashdump
set RHOSTS 192.168.144.200
run
```

```
[-] 192.168.144.200:3306  - 192.168.144.200:3306 Unable to login from this host due to policy (may still be vulnerable)
[*] 192.168.144.200:3306  - Scanned 1 of 1 hosts (100% complete)
```

This module, purpose-built to test for CVE-2012-2122 specifically, correctly and explicitly reports that the host-based access policy prevented it from reaching the authentication stage at all (`Unable to login from this host due to policy`), while honestly noting the target `may still be vulnerable`, an appropriately cautious phrasing given the module genuinely could not test the condition rather than confirming its absence. This is the correct, trustworthy behaviour: a sixth tool independently confirming the same access restriction, and correctly declining to claim a negative result it cannot actually support.

```
use auxiliary/scanner/mysql/mysql_login
set RHOSTS 192.168.144.200
set USERNAME root
set PASSWORD ""
run
```

```
[-] 192.168.144.200:3306  - 192.168.144.200:3306 - Unsupported target version of MySQL detected. Skipping.
[*] 192.168.144.200:3306  - Scanned 1 of 1 hosts (100% complete)
[*] 192.168.144.200:3306  - Bruteforce completed, 1 credential was successful.
[*] 192.168.144.200:3306  - You can open an MySQL session with these credentials and CreateSession set to true
```

**This result is contradictory and required independent verification before being trusted.** The module's own first line states it detected an unsupported MariaDB version and explicitly skipped testing this target, yet its summary lines claim a credential (`root` with an empty password) succeeded. These two statements cannot both be true: a skipped target cannot simultaneously produce a successful login result.

To resolve this, the supposedly successful credential was tested directly and independently:

```bash
mysql -h 192.168.144.200 -u root -p
```

(password left blank at the prompt)

```
ERROR 2002 (HY000): Received error packet before completion of TLS handshake. The authenticity of the following error cannot be verified: 1130 - Host '192.168.144.129' is not allowed to connect to this MariaDB server
```

**The direct connection attempt was rejected with the identical host-restriction error observed in every other test throughout this entire activity.** This conclusively confirms that `mysql_login`'s claim of "1 credential was successful" was a **false positive**, most likely an internal module reporting bug or a generic summary line that fires regardless of the actual per-host result, rather than a genuine successful authentication. The root/empty-password credential was never actually valid against this target from this source host; the module's own inconsistent output (claiming both "skipped" and "successful" in the same run) should itself have been treated as an immediate red flag, and was confirmed as such through direct manual verification.

## Outcome

Confirmed that the MariaDB service on port 3306 enforces host-based access control that rejects the current attacker source IP (`192.168.144.129`) before any authentication attempt can be made, consistently and reproducibly across six independent methods: raw netcat, the standard `mysql` client, nmap's built-in `-sV` version probe, two NSE scripts, and two of three Metasploit auxiliary modules. This is the expected, correctly-functioning behaviour of MySQL/MariaDB's `Host` column access control feature, and represents a genuinely closed avenue from the current attacker position, rather than an incomplete or failed enumeration effort. No version-specific vulnerability testing (such as the CVE-2012-2122 check) could be meaningfully performed as a result, since those checks require reaching the authentication stage, which this restriction prevents entirely.

Separately, Metasploit's `mysql_login` module produced an internally contradictory result (simultaneously reporting the target was "skipped" due to an unsupported version, and that a credential "was successful"), which was confirmed via direct manual connection to be a false positive: the claimed root/empty-password credential does not actually work against this target from this source host, and the module's success claim does not reflect a genuine finding. This is recorded as a significant lesson about verifying automated tool output rather than a genuine vulnerability.

## Remediation

Not applicable to the target in the traditional sense: this activity found the service to be correctly configured with restrictive host-based access control, which is itself good practice and requires no remediation. If this restriction were intentionally scoped only to specific internal/trusted hosts (which would need separate confirmation, not tested in this activity), that would represent an appropriately defence-in-depth configuration.

## Teaching Notes

This activity is valuable specifically because it is a clean, well-understood negative finding with an identical root cause confirmed independently across every method tried. Students should learn to distinguish this from the earlier FTP NSE detection gaps documented in `r-04- ftp-banner-grab-and-anonymous-access.md`, where scripts silently failed for unclear or unconfirmed reasons despite the underlying condition being true. Here, by contrast, every tool and script either surfaced the exact same explicit error message or fell silent for a clearly explainable reason (their required precondition, reaching authentication, was never met). This is the difference between an unreliable or malfunctioning check and a check that correctly reports "not applicable" given the actual network conditions.

This is also a good opportunity to explain MySQL/MariaDB's `Host` column access control model specifically: unlike many services where access control is entirely handled by authentication (username/password) after a connection is accepted, MySQL/MariaDB's own grant tables can restrict which client source addresses or hostnames are permitted to connect *per user account*, independent of whether the correct password is known. A student who only tests authentication (trying passwords) without first checking whether a connection is even accepted from their vantage point could otherwise misinterpret a host-restriction rejection as a password failure, or waste time on brute-force attempts (such as `mysql-brute`) that could never succeed regardless of password correctness, since the connection is rejected before passwords are even considered.

Finally, the `mysql_login` false positive is arguably the single most important lesson in this entire activity, and deserves emphasis independent of the MySQL-specific content. A tool claiming success does not make it so, and an internally inconsistent result (a module claiming both "skipped" and "successful" for the same target in the same run) is itself a strong signal to verify independently before trusting or acting on the claim. This is the mirror image of the FTP detection-gap lesson in `r-04- ftp-banner-grab-and-anonymous-access.md`, where automated tools under-reported a true finding; here, a tool over-reported a false one. Students should take away that automated tool output requires critical evaluation in both directions: false negatives (missing real findings) and false positives (reporting findings that aren't real) are both genuine risks, and the discipline of independently verifying a tool's claim, whether that claim is negative or positive, is the core professional skill this entire reconnaissance phase has been building toward.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** None; the service was found to reject all connections from the current attacker position at the host-access-control level, before authentication
**Provides access for:** No further activity currently depends on this finding; MariaDB remains an unexploited, access-restricted service on this target as of this activity
**Suggested teaching level:** Level 5–6 (understanding host-based access control as distinct from authentication, and correctly interpreting consistent negative results across multiple tools as a genuine finding rather than incomplete enumeration)

## What is MySQL/MariaDB?

MySQL and MariaDB (a compatible, community-developed fork of MySQL) are widely used relational database servers that store and manage structured data for applications, from small internal tools to large-scale production systems. Almost any organisation running custom software, web applications, or business systems has a database server like this somewhere on its network, making it a near-universal and high-value target: successful access can expose everything from customer records to internal credentials stored by other applications.
