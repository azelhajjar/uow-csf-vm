# Activity: Redis Unauthenticated Data Exposure

## Summary

Exploitation of the unauthenticated Redis instance confirmed in `r-16- redis-enumeration.md`: retrieving the three identified keys, interpreting what each one is actually worth to an attacker, and demonstrating write capability. Unlike a CVE-based exploit, the entire "attack" here is standard Redis commands used exactly as designed, against a server that never required a password in the first place.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | Redis 7.0.15, port 6379/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | redis-cli |

## Vulnerability

`redis.conf` was changed from its safer defaults (`bind 127.0.0.1 -::1`, `protected-mode yes`) to `bind 0.0.0.0` with `protected-mode no`, and no `requirepass` value was ever set. This is CWE-306 (Missing Authentication for Critical Function): the server has no concept of a login at all in this configuration, any client that can reach port 6379 has full read/write access to every key in the database and to Redis's own administrative commands.

## Exploitation and Impact

**On Kali**, retrieving and interpreting each key:

```bash
redis-cli -h 192.168.144.200 get session:admin:token
```
```
"a8f3e2b1c9d04f5e8a7b6c3d2e1f0a9b"
```
**What this is worth:** a session token is the credential a web application uses to recognise an already-logged-in user without asking for a password again. If this token belongs to a real, currently active admin session in some application using this Redis instance as its session store, an attacker can present this exact token to that application and be treated as that logged-in administrator, no password needed at all. This is session hijacking via a stolen session store, one of the most direct and damaging things an exposed Redis instance can hand an attacker, since it can bypass authentication entirely rather than merely disclosing information.

```bash
redis-cli -h 192.168.144.200 get app:config:db_password
```
```
"R3d1s_C4che_2026!"
```
**What this is worth:** applications very commonly cache their own configuration values, including database credentials, in Redis for fast access rather than re-reading a config file on every request. A value named exactly `db_password` is an extremely strong signal this is a real credential for some other service, most plausibly the MariaDB instance already identified on this VM (`r-08- mysql-mariadb-enumeration.md`). This is a credential-reuse discovery: a student should immediately try this password against MariaDB (and any other authenticated service on the host) as the direct next step, exactly the kind of lateral, cross-service thinking this whole VM has been built to encourage.

```bash
redis-cli -h 192.168.144.200 lrange queue:print_jobs 0 -1
```
```
1) "HR-LaserJet-2F:Q3_Budget_Review.pdf"
```
**What this is worth:** this confirms Redis is being used as a job queue by some part of the print-service workflow, corroborating and connecting to the CUPS print queue already identified in `r-13- cups-discovery-ip-change.md`. On its own this entry is lower-value than the token or password, but it demonstrates that services on this host are integrated with each other, not isolated, reinforcing that a full assessment benefits from mapping how findings across different services relate rather than treating each one in isolation.

**Demonstrating write access:**

```bash
redis-cli -h 192.168.144.200 set attacker:test "unauthenticated write confirmed"
redis-cli -h 192.168.144.200 get attacker:test
redis-cli -h 192.168.144.200 del attacker:test
```

A successful write, read-back, and cleanup confirms the exposure is not read-only; an attacker could just as easily corrupt or delete existing application data (including the session token and config values relied upon by whatever real application uses this Redis instance), not merely read it.

## Outcome

Confirmed full unauthenticated read and write access to Redis, yielding a live session token (usable for session hijacking against whatever application owns it) and an application database password (a strong credential-reuse candidate against MariaDB, per `r-08`). No exploit code, no CVE, and no credentials of any kind were required, standard Redis client commands against a server that was never configured to ask for any.

## Remediation

- Set `requirepass` to a strong, unique value, or migrate to Redis 6+'s full ACL system for per-user permissions.
- Restore `bind 127.0.0.1 -::1` unless remote access is a genuine, deliberate requirement, and if it is, restrict it to specific trusted hosts via firewall rules rather than `0.0.0.0`.
- Restore `protected-mode yes`, which specifically exists to prevent exactly this misconfiguration from being immediately exploitable even if `bind` is accidentally widened.
- Never store plaintext credentials (such as `db_password`) in Redis, or any cache, without additional application-level protection; a cache should not become the weakest link for credentials that are otherwise properly secured elsewhere.

## Teaching Notes

This activity is designed to make a specific point beyond "this data was readable": raw access to a data store is only as valuable as an attacker's ability to interpret and act on what's inside it. Simply running `KEYS *` and stopping there under-realises the actual impact; the real exercise is recognising that `session:admin:token` is a session-hijacking primitive and `app:config:db_password` is a credential-reuse lead into `r-08`/MariaDB, then actually following through on that lead. Students should be encouraged to treat every piece of disclosed data as a question ("what does this let me do next?") rather than a checklist item to note and move past.

## Lab Dependencies

**Prerequisite exploit(s):** `r-16- redis-enumeration.md`
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** Full read/write access to Redis data; a recovered session token (usable for session hijacking against whatever application consumes it) and a candidate credential for lateral movement into MariaDB (`r-08- mysql-mariadb-enumeration.md`, not yet confirmed to succeed against it in this activity)
**Provides access for:** Provides a credential lead into `r-08- mysql-mariadb-enumeration.md`; corroborates the CUPS print queue from `r-13- cups-discovery-ip-change.md`
**Suggested teaching level:** Level 5-6 (data exposure and interpretation), extending toward Level 6-7 if the credential lead is actually followed through against MariaDB
