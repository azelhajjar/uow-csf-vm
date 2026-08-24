# Activity: Apache Druid HTTP Service Enumeration

## Summary

Enumeration of all five HTTP ports associated with the Apache Druid installation (8081, 8082, 8083, 8091, 8888), previously identified only by banner in `r-02- reconnaissance-and-service-enumeration.md`, where only 8081 and 8888 had been confirmed as genuine Druid web consoles and the remaining three (8082, 8083, 8091) were assumed, but never actually confirmed, to be Druid's non-console backend processes (broker, historical, middleManager). This activity confirms that assumption through direct HTTP response comparison across all five ports. It also documents a further nmap NSE detection gap (three HTTP enumeration scripts producing no output at all), and identifies a second, previously untested Druid vulnerability (CVE-2023-25194, JNDI injection RCE) via Metasploit, for which an initial exploitability check proved inconclusive rather than confirming or ruling out the vulnerability.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.131 |
| Service | Apache Druid 0.20.0, ports 8081, 8082, 8083, 8091, 8888 (all tcp) |
| Attacker | Kali, 192.168.144.129 |
| Tooling | curl, nmap NSE (`http-title`, `http-headers`, `http-methods`), Metasploit (`auxiliary/scanner/http/http_version`, `exploit/multi/http/apache_druid_cve_2023_25194`) |

## Reconnaissance

### Step 1: Manual HTTP request comparison across all five ports

```bash
curl -v http://192.168.144.131:8081/ 2>&1 | head -30
curl -v http://192.168.144.131:8082/ 2>&1 | head -30
curl -v http://192.168.144.131:8083/ 2>&1 | head -30
curl -v http://192.168.144.131:8091/ 2>&1 | head -30
curl -v http://192.168.144.131:8888/ 2>&1 | head -30
```

Results summarised:

| Port | Response | Location header |
|---|---|---|
| 8081 | `302 Found` | `http://192.168.144.131:8081/unified-console.html` |
| 8082 | `404 Not Found` | none |
| 8083 | `404 Not Found` | none |
| 8091 | `404 Not Found` | none |
| 8888 | `302 Found` | `http://192.168.144.131:8888/unified-console.html` |

**This is the key finding of this activity, and it directly confirms what had previously only been assumed in `r-02- reconnaissance-and-service-enumeration.md`.** Ports 8081 and 8888 both redirect an unauthenticated root-path request to `unified-console.html`, Druid's web-based management UI, confirming these two are the coordinator/overlord (8081) and router (8888) processes, both of which host the web console (the router simply proxies the coordinator's console, as already noted in `e-05- apache-druid-cve-2021-25646.md`). Ports 8082, 8083, and 8091 all return a plain `404 Not Found` with no redirect and no console, but they **do respond as functioning HTTP servers** rather than refusing the connection or timing out. This is consistent with these three being Druid's broker, historical, and middleManager processes respectively, which expose internal/inter-node HTTP APIs for Druid's own distributed operation but do not serve a web console at the root path, exactly the behaviour a non-console Druid process would be expected to exhibit. This confirms the process identification that had only been inferred by port-number convention in `r-02`, now backed by actual observed HTTP behaviour rather than assumption alone.

### Step 2: NSE HTTP enumeration scripts

```bash
nmap -p 8081,8082,8083,8091,8888 --script http-title,http-headers,http-methods 192.168.144.131
```

```
PORT     STATE SERVICE
8081/tcp open  blackice-icecap
8082/tcp open  blackice-alerts
8083/tcp open  us-srv
8091/tcp open  jamlink
8888/tcp open  sun-answerbook
```

**All three scripts produced no output whatsoever across all five ports.** This is another documented NSE detection gap, consistent with the pattern already established with several FTP scripts in `r-04- ftp-banner-grab-and-anonymous-access.md`. Given that manual `curl` requests against these same ports and paths returned clear, readable HTTP responses (including a title-bearing redirect target and standard headers) only moments earlier in Step 1, there is no obvious reason these scripts should have failed to produce any output at all; this appears to be a script or nmap version-specific issue rather than any protocol oddity on the target's side, consistent with the general pattern observed elsewhere in this project that NSE HTTP/FTP-family scripts can be considerably less reliable than manual protocol interaction or other tools, and should never be relied upon as the sole check for a given service. Nmap's own static service-name guesses (`blackice-icecap`, `blackice-alerts`, `us-srv`, `jamlink`, `sun-answerbook`) remain visible here purely as leftover default port-database labels, already established as unreliable in `r-02- reconnaissance-and-service-enumeration.md`, and should be disregarded entirely in favour of the actual `curl`-confirmed behaviour from Step 1.

### Step 3: Metasploit `http_version` cross-check

```
use auxiliary/scanner/http/http_version
set RHOSTS 192.168.144.131
set RPORT 8082
run
```
```
[+] 192.168.144.131:8082
```

```
set RPORT 8083
run
```
```
[+] 192.168.144.131:8083
```

```
set RPORT 8091
run
```
```
[+] 192.168.144.131:8091
```

```
set RPORT 8888
run
```
```
[+] 192.168.144.131:8888  ( 302-http://192.168.144.131:8888/unified-console.html )
```

Metasploit's `http_version` module confirms the same result pattern as the manual `curl` requests: 8888 reports the same `302` redirect to the unified console already seen manually, while 8082, 8083, and 8091 report bare confirmation of an HTTP service present with no further detail (consistent with the `404`, no-title, no-redirect responses observed manually). This module did not produce the internally contradictory or false-positive behaviour seen with `mysql_login` in `r-08- mysql-mariadb-enumeration.md`, its results here are consistent with, and corroborated by, the manual `curl` findings from Step 1.

### Step 4: Identifying and assessing a second, previously untested Druid vulnerability

During the Metasploit module discovery search already documented in earlier activities, a second Druid-specific exploit module was identified that had not yet been tested against this target: `exploit/multi/http/apache_druid_cve_2023_25194` (Apache Druid JNDI Injection RCE, disclosed 2023-02-07), entirely distinct from the JavaScript-engine RCE (CVE-2021-25646) already exploited in `e-05- apache-druid-cve-2021-25646.md`.

```
use exploit/multi/http/apache_druid_cve_2023_25194
set RHOSTS 192.168.144.131
set RPORT 8081
check
```

```
[-] Exploit failed [unreachable]: OpenSSL::SSL::SSLError SSL_connect returned=1 errno=0 peeraddr=192.168.144.131:8081 state=SSLv3/TLS write client hello: wrong version number
[-] 192.168.144.131:8081 - Check failed: The state could not be determined.
```

The initial check attempt failed due to a module configuration mismatch rather than any target-side condition: the module defaulted to attempting an HTTPS/TLS connection, while Druid's console on this target is served over plain HTTP, confirmed throughout every other activity in this project. This was corrected:

```
set SSL false
check
```

```
[*] 192.168.144.131:8081 - Cannot reliably check exploitability. No LDAP search query was received.
```

**This result is inconclusive, not a confirmed negative.** CVE-2023-25194 is a JNDI (Java Naming and Directory Interface) injection vulnerability, and Metasploit's check mechanism for this class of vulnerability typically works by attempting to trigger the vulnerable target into making an outbound LDAP callback to a listener the module sets up, then checking whether that callback is actually received. The message `No LDAP search query was received` indicates the module did not observe this callback, which could mean the target is genuinely not vulnerable to this specific CVE, or it could mean the callback mechanism itself did not function correctly in this network environment for reasons unrelated to the target's actual vulnerability status (for example, if outbound connectivity, DNS resolution, or listener configuration between the target and the check mechanism did not behave as the module expects). No further investigation of this specific vulnerability was undertaken in this activity; it is recorded here as an identified, plausible, but not yet confirmed or ruled out candidate for future testing, consistent with the project's broader practice of recording unresolved leads rather than asserting a conclusion the available evidence does not support.

## Outcome

Confirmed, through direct HTTP behaviour comparison, that ports 8081 and 8888 are Druid's coordinator/overlord and router processes respectively (both hosting the web console), while 8082, 8083, and 8091 are functioning but non-console Druid backend processes, consistent with the broker/historical/middleManager roles already assumed but not previously confirmed in `r-02- reconnaissance-and-service-enumeration.md`. Separately identified a second, distinct Druid vulnerability (CVE-2023-25194) via Metasploit module discovery; an initial exploitability check for this vulnerability was inconclusive due to the check mechanism's reliance on an outbound callback that was not observed, and this remains an open, untested lead rather than a confirmed finding either way. Three nmap NSE HTTP enumeration scripts (`http-title`, `http-headers`, `http-methods`) produced no output at all across all five ports, a further instance of the NSE reliability pattern already documented elsewhere in this reconnaissance phase.

## Remediation

- See `e-05- apache-druid-cve-2021-25646.md` for remediation of the confirmed JavaScript-engine RCE.
- The non-console Druid processes (broker, historical, middleManager on 8082/8083/8091) should not be reachable from outside the Druid cluster's own internal network segment if not required; their current network-reachability from an external attacker position, even without a web console, still exposes internal API surface unnecessarily.
- CVE-2023-25194 should be investigated further and, if confirmed applicable to this Druid version, remediated according to the vendor's guidance for that CVE specifically (Druid version upgrade and/or configuration hardening of the JNDI-related connection properties), independent of the already-remediated CVE-2021-25646.

## Teaching Notes

This activity is a good demonstration of confirming an assumption rather than simply carrying it forward unexamined: the process identification for ports 8082/8083/8091 had been stated as an inference in `r-02- reconnaissance-and-service-enumeration.md` ("inferred" was used explicitly in that file's service summary table), and this activity's direct HTTP comparison converts that inference into an actual confirmed finding, a meaningful distinction for a professional assessment where inferred and confirmed findings should never be presented with equal confidence.

The inconclusive CVE-2023-25194 check is also valuable specifically because it resists a simple, satisfying answer. Students should be comfortable recording and reporting "this remains unresolved and requires further investigation" as a legitimate, professional outcome, rather than either overclaiming a vulnerability based on an inconclusive tool response, or dismissing it as unlikely simply because the first check attempt did not immediately confirm it. This mirrors the `ftp-bounce` lesson from `r-04- ftp-banner-grab-and-anonymous-access.md`, where a lab's own network characteristics limited what a particular check could actually determine, again reinforcing that environmental and mechanism-specific factors must be understood before a tool's output (or lack thereof) is trusted as a final answer.

## Lab Dependencies

**Prerequisite exploit(s):** None (all HTTP enumeration performed unauthenticated); best read alongside `r-02- reconnaissance-and-service-enumeration.md` (initial port identification) and `e-05- apache-druid-cve-2021-25646.md` (the confirmed Druid RCE this installation is already known vulnerable to)
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (enumeration only; the CVE-2023-25194 check did not result in any access or confirmed exploitability)
**Provides access for:** Confirms the process identity of ports 8082/8083/8091 referenced throughout this project; identifies CVE-2023-25194 as an open lead for potential future exploitation activity, not yet pursued further
**Suggested teaching level:** Level 6 (confirming inferred findings through direct testing, and correctly interpreting inconclusive automated vulnerability checks)
