# Activity: Zookeeper Enumeration

## Summary

Enumeration of the Apache Zookeeper service on port 2181, previously identified only by version banner in `r-02- reconnaissance-and-service-enumeration.md` and otherwise untouched. No dedicated nmap NSE scripts exist for Zookeeper in this installation, so enumeration relied entirely on Zookeeper's own documented "four-letter word" administrative command interface, sent as plain text directly to the client port. This proved highly informative: it confirmed the server is alive and healthy, revealed active client connection details, and most significantly, disclosed that this Zookeeper instance is not a standalone service but is bundled with and run by the Apache Druid installation already identified on ports 8081–8888, directly confirming an operational relationship between two services that had, until this point, only been inferred from proximity on the same host.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.131 |
| Service | Apache Zookeeper 3.4.14, port 2181/tcp |
| Attacker | Kali, 192.168.144.129 |
| Tooling | nc, nmap |

## Reconnaissance

### Step 1: Checking for available NSE tooling

```bash
ls -l /usr/share/nmap/scripts/ | grep -i zookeeper
```

No output was returned. **No Zookeeper-specific NSE scripts exist in this nmap installation at all.** This is itself worth noting: unlike FTP, SSH, NFS, distcc, and MySQL, all of which had at least one dedicated script available, Zookeeper enumeration on this toolset must rely entirely on either generic scripts (`default`/`-sV`) or manual protocol interaction. This is a realistic situation students should expect to encounter with less commonly targeted services, not every service has mature, purpose-built NSE tooling, and the ability to fall back to manual protocol interaction is essential rather than optional.

### Step 2: Version/service detection

```bash
nmap -sV -p 2181 --script default 192.168.144.131
```

```
PORT     STATE SERVICE   VERSION
2181/tcp open  zookeeper Zookeeper 3.4.14-4c25d480e66aadd371de8bd2fd8da255ac140bcf (Built on 03/06/2019)
```

Confirms the specific Zookeeper release (3.4.14) and build date (March 2019), consistent with the version already noted in the original full-range scan. No script-specific output was produced beyond the version banner, again consistent with there being no Zookeeper-aware scripts in the `default` category.

### Step 3: Manual protocol interaction via four-letter word commands

Zookeeper exposes a small set of plain-text administrative diagnostic commands, historically referred to as "four-letter words" due to their short command names, that can be sent directly to the client port without any authentication. Three were tested.

```bash
echo "ruok" | nc -nv -q2 192.168.144.131 2181
```

```
Connection to 192.168.144.131 2181 port [tcp/*] succeeded!
imok
```

`ruok` ("are you ok?") is Zookeeper's simplest health check command. The response `imok` confirms the server considers itself healthy and able to serve requests. This is the lowest-risk, most basic form of interaction available and a reasonable first step before trying anything more detailed.

```bash
echo "stat" | nc -nv -q2 192.168.144.131 2181
```

```
Zookeeper version: 3.4.14-4c25d480e66aadd371de8bd2fd8da255ac140bcf, built on 03/06/2019 16:18 GMT
Clients:
 /192.168.144.129:54974[0](queued=0,recved=1,sent=0)
 /0:0:0:0:0:0:0:1:43802[1](queued=0,recved=984,sent=991)
 /0:0:0:0:0:0:0:1:34074[1](queued=0,recved=935,sent=941)
 /127.0.0.1:46378[1](queued=0,recved=961,sent=965)
 /0:0:0:0:0:0:0:1:43796[1](queued=0,recved=914,sent=919)
 /0:0:0:0:0:0:0:1:58878[1](queued=0,recved=922,sent=926)

Latency min/avg/max: 0/0/28
Received: 4720
Sent: 4745
Connections: 6
Outstanding: 0
Zxid: 0x19b
Mode: standalone
Node count: 54
```

This is a substantially more informative result. Beyond confirming the version again, it lists every currently connected client by source address and port, along with per-connection traffic counters. Five of the six listed clients are connecting from `::1` (IPv6 loopback) or `127.0.0.1` (IPv4 loopback), meaning they originate from processes running locally on the target itself, not from any external host. This strongly indicates other local services on the target are actively using this Zookeeper instance as a dependency, consistent with Zookeeper's typical role as a coordination/configuration-management backend for a larger application, rather than being a standalone service with no other consumers. `Mode: standalone` confirms this is a single-node Zookeeper deployment (not part of a multi-node ensemble/cluster), and `Node count: 54` indicates the internal Zookeeper data tree (`znodes`) currently holds 54 nodes, again consistent with an application actively using Zookeeper to store operational/coordination state rather than an idle or freshly-installed instance.

```bash
echo "envi" | nc -nv -q2 192.168.144.131 2181
```

```
Environment:
zookeeper.version=3.4.14-4c25d480e66aadd371de8bd2fd8da255ac140bcf, built on 03/06/2019 16:18 GMT
host.name=cav-csf-linux
java.version=1.8.0_432
java.vendor=Temurin
java.home=/usr/lib/jvm/java-8-openjdk/jre
java.class.path=/usr/local/apache-druid/bin/../lib/aether-connector-okhttp-0.0.9.jar:/usr/local/apache-druid/bin/../lib/jetty-servlet-9.4.30.v20200611.jar: ... [several hundred further JAR entries, all under /usr/local/apache-druid/bin/../lib/] ... /usr/local/apache-druid/conf/zk
java.library.path=/usr/java/packages/lib/amd64:/usr/lib64:/lib64:/lib:/usr/lib
java.io.tmpdir=/tmp
java.compiler=<NA>
os.name=Linux
os.arch=amd64
os.version=6.1.0-27-amd64
user.name=druid
user.home=/home/druid
user.dir=/usr/local/apache-druid
```

**This is the most significant finding of this activity.** The `envi` command discloses the full Java runtime environment of the process serving Zookeeper, and it conclusively establishes that this is not an independently-run Zookeeper service at all: the `java.class.path` consists entirely of JAR files under `/usr/local/apache-druid/bin/../lib/`, including numerous Druid-specific components (`druid-server-0.20.0.jar`, `druid-processing-0.20.0.jar`, `druid-sql-0.20.0.jar`, and dozens of others matching the exact Druid version already confirmed in `e-05- apache-druid-cve-2021-25646.md`), and critically `zookeeper-3.4.14.jar` itself appears as just one JAR among Druid's own bundled dependencies. The process is running as `user.name=druid`, with `user.home=/home/druid` and `user.dir=/usr/local/apache-druid`, the same account and installation directory already associated with the Druid service exploited separately on ports 8081/8888.

This confirms that **Zookeeper on port 2181 is Druid's own embedded coordination service**, launched by and running under the Druid installation itself, rather than a separately administered, standalone Zookeeper deployment. The `host.name=cav-csf-linux` field also independently confirms the target's real system hostname, corroborating information already established through prior exploitation activities.

The `os.version=6.1.0-27-amd64` and `java.version=1.8.0_432` fields additionally confirm the kernel version and JVM version in use, useful supplementary system fingerprinting obtained entirely through this one plain-text command, without any authentication or prior access to the host.

## Outcome

Confirmed Zookeeper 3.4.14 is running on port 2181 and is healthy and actively in use (six current client connections, mostly local-loopback, and 54 znodes present). No dedicated NSE tooling exists for Zookeeper in this environment, making manual four-letter-word command interaction the primary and most productive enumeration technique for this service. Most significantly, this activity established that this Zookeeper instance is not standalone: it is bundled with, launched by, and running under the same Apache Druid installation already identified and exploited separately on ports 8081/8888 (`e-05- apache-druid-cve-2021-25646.md`), running as the same `druid` user and from the same `/usr/local/apache-druid` installation directory. This is a genuine architectural finding about how services on this target relate to one another, not merely two coincidentally co-located ports.

## Remediation

- Zookeeper's four-letter word commands should be restricted in production deployments, Zookeeper's own configuration supports a `4lw.commands.whitelist` setting to limit which of these commands (particularly the more informative ones like `envi` and `conf`) can be issued without authentication; by default in older Zookeeper releases (including 3.4.x, as seen here) all commands are enabled with no restriction.
- The `envi` command in particular discloses substantial internal detail (full Java classpath, home directories, usernames, OS/kernel version) with zero authentication required; this level of unauthenticated information disclosure should be treated as a genuine, if lower-severity, finding independent of any other vulnerability on the host.
- Since this Zookeeper instance is exclusively a dependency of the co-located Druid installation, it should not be exposed on a network-reachable interface at all if Druid itself does not require external Zookeeper access; binding it to loopback only (`127.0.0.1`) would prevent this exact enumeration from being possible from a remote position such as the one used in this activity, while still allowing Druid's own local processes to reach it via the loopback connections already observed in the `stat` output.

## Teaching Notes

This activity demonstrates that manual protocol interaction is not merely a fallback for when NSE tooling is unavailable, it can, as seen here, be dramatically more informative than any equivalent automated script might have been, since interpreting the `envi` output and recognising the Druid-specific JAR paths and username required contextual knowledge from earlier activities rather than a script simply flagging a known signature. Students should be encouraged to actually read and think about the content returned by manual protocol commands, rather than treating them as pass/fail checks, exactly the kind of judgement a purely automated scan cannot replicate.

This is also an excellent example of connecting enumeration findings across services to build a genuine architectural picture of the target, rather than treating each open port as an isolated, unrelated finding. The relationship between Zookeeper (2181) and Druid (8081-8888) established here should inform how both are discussed together in any broader assessment narrative or report, and is a good prompt for discussing service dependency mapping as a distinct reconnaissance skill from simple service identification.

## Lab Dependencies

**Prerequisite exploit(s):** None (Zookeeper enumeration itself requires no prior access); best understood alongside `r-02- reconnaissance-and-service-enumeration.md` (for the initial version identification) and `e-05- apache-druid-cve-2021-25646.md` (for the Druid installation this Zookeeper instance is confirmed to belong to)
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (enumeration only; no authentication exists to bypass and none was attempted)
**Provides access for:** Establishes the operational relationship between this service and the Apache Druid installation exploited in `e-05- apache-druid-cve-2021-25646.md`; no further activity currently depends on this finding directly
**Suggested teaching level:** Level 5–6 (manual protocol interaction where no NSE tooling exists, and connecting enumeration findings across services to establish architectural relationships)

## What is Zookeeper?

Apache Zookeeper is a coordination service used by distributed applications to manage shared configuration, naming, and synchronisation across multiple servers working together. It is rarely deployed as a standalone, general-purpose service; instead, it is almost always a supporting/backend component bundled with a larger distributed system (in this case, Apache Druid), which is exactly what this activity's enumeration confirms. Recognising Zookeeper as a dependency of another service, rather than a target in its own right, is itself a useful reconnaissance skill.
