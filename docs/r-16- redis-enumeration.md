# Activity: Redis Enumeration

## Summary

Reconnaissance of the Redis service, newly added to this VM, confirming it accepts connections and commands with no authentication whatsoever, and that its in-memory data store contains readable, sensitive-looking key/value content.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.200 |
| Service | Redis 7.0.15, port 6379/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | redis-cli |

## Reconnaissance

### Step 1: Port confirmation

```bash
nmap -sV -p 6379 192.168.144.200
```

Confirms `6379/tcp` open, a new port not present in the original `r-02` baseline, running Redis.

### Step 2: Redis-specific NSE script

```bash
ls -l /usr/share/nmap/scripts/ | grep -i redis
```

```
redis-brute.nse
redis-info.nse
```

```bash
nmap -p 6379 --script redis-info 192.168.144.200
```

```
| redis-info:
|   Version: 7.0.15
|   Operating System: Linux 6.1.0-27-amd64 x86_64
|   Process ID: 6985
|   Connected clients: 1
|   Bind addresses:
|     0.0.0.0
|   Client connections:
|_    192.168.144.129
```

This script worked cleanly and correctly on the first attempt, and usefully confirms `Bind addresses: 0.0.0.0` directly (corroborating the deliberate misconfiguration) along with the live client connection list, showing Kali's own IP as a currently connected client, direct proof the unauthenticated connection succeeded, without needing to separately confirm via `redis-cli ping` first.

### Step 3: Unauthenticated connection test

```bash
redis-cli -h 192.168.144.200 ping
```

```
PONG
```

A successful `PONG` with no credential prompt confirms the server accepts commands from any client without authentication.

### Step 4: Server information disclosure

```bash
redis-cli -h 192.168.144.200 info server
```

```
redis_version:7.0.15
os:Linux 6.1.0-27-amd64 x86_64
process_id:6985
config_file:/etc/redis/redis.conf
...
```

The `INFO` command, one of Redis's most basic commands, discloses the exact software version, host OS/kernel, process ID, and the server's own configuration file path, all without authentication. This alone is useful reconnaissance: exact version numbers support targeted vulnerability research, and the OS/kernel string corroborates fingerprinting from other services.

### Step 5: Enumerating stored data

```bash
redis-cli -h 192.168.144.200 keys '*'
```

```
1) "queue:print_jobs"
2) "app:config:db_password"
3) "session:admin:token"
```

The `KEYS *` command lists every key currently stored in the database. Three keys are present, and their names alone are informative before even reading their values: `session:admin:token` suggests an active authenticated session, `app:config:db_password` suggests an application's own configuration/secret, and `queue:print_jobs` suggests integration with another service on this host.

## Outcome

Confirmed Redis is reachable and fully unauthenticated from the network, both `bind` (previously loopback-only, now `0.0.0.0`) and `protected-mode` (previously enabled, now disabled) were changed from Redis's own safer-by-default settings to recreate the class of misconfiguration most commonly responsible for real-world Redis breaches. Three keys with sensitive-looking names were identified; their content is retrieved and interpreted in `e-15- redis-unauthenticated-data-exposure.md`.

## Remediation

See `e-15- redis-unauthenticated-data-exposure.md` for full remediation guidance.

## Teaching Notes

Redis's security model deserves specific explanation here: unlike MySQL/MariaDB (already correctly access-controlled elsewhere on this VM) or Samba (which at least has a concept of authenticated vs. guest users), Redis by design has historically had no authentication at all unless explicitly configured, its assumption is that the network itself is trusted and nothing untrusted can reach the port. When that assumption breaks, commonly through exactly the kind of `bind 0.0.0.0` change made here, often done for legitimate-seeming reasons like container/cloud deployment convenience, the result is complete unauthenticated access with no additional barrier. This is one of the most consistently reported real-world cloud/container misconfigurations of the last decade, and is a valuable contrast to MariaDB's correctly-configured host restriction documented in `r-08- mysql-mariadb-enumeration.md`: not every data store on a network receives the same level of care, and part of an assessor's job is identifying exactly which ones were overlooked.

## What is Redis?

Redis is an in-memory data store, commonly used by applications as a fast cache, a session store (keeping track of who is currently logged in and their temporary session data), or a message queue between different parts of a system. Because it holds data in memory rather than on disk by default, it's extremely fast, which is why it's so widely used behind web applications to reduce load on slower databases like MySQL. Precisely because it's usually treated as an internal "helper" component rather than a user-facing database, it's frequently deployed with far less security scrutiny than the main database itself, exactly the pattern this activity demonstrates.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Full unauthenticated read access to all Redis data and server information
**Provides access for:** Precedes `e-15- redis-unauthenticated-data-exposure.md`
**Suggested teaching level:** Level 5
