# Web Apps README — CAV-CSF Linux VM

Overview of the web application security training platforms deployed on this VM. Distinct from `services-README.md`, which covers the deliberately vulnerable/misconfigured infrastructure services (CUPS, Samba, SNMP, etc.). These are self-contained OWASP training curricula with their own built-in lessons/guidance; no bespoke `r-`/`e-` reconnaissance or exploitation write-ups exist for them in this project, separate lab materials are used instead.

---

## Summary Table

| Platform | Port | DNS Record |
|---|---|---|
| WebGoat | 8080/tcp | `webgoat.uow-csf.internal` |
| WebWolf | 9090/tcp | `webwolf.uow-csf.internal` |
| DVWA | 8090/tcp | `dvwa.uow-csf.internal` |
| OWASP Security Shepherd | 8543/tcp (HTTPS) | `shepherd.uow-csf.internal` |

## Quick Access Links

| Platform | URL (by hostname) | URL (by static IP) |
|---|---|---|
| WebGoat | `http://webgoat.uow-csf.internal:8080/WebGoat/` | `http://192.168.144.100:8080/WebGoat/` |
| WebWolf | `http://webwolf.uow-csf.internal:9090/login` | `http://192.168.144.100:9090/login` |
| DVWA | `http://dvwa.uow-csf.internal:8090/` | `http://192.168.144.100:8090/` |
| Security Shepherd | `https://shepherd.uow-csf.internal:8543/` | `https://192.168.144.100:8543/` |

## WebGoat / WebWolf

Guided, lesson-based platform covering one vulnerability class at a time (SQLi, XSS, XXE, deserialization, SSRF, JWT issues, path traversal, and more), with explanations and hints built into the UI. WebWolf simulates attacker-side infrastructure (mailbox, file server) for lessons requiring a second party. Best suited to structured, concept-by-concept teaching (Level 5-6).

## DVWA (Damn Vulnerable Web Application)

Single vulnerable application with adjustable difficulty (`low`/`medium`/`high`/`impossible`) per vulnerability class, no guided lessons. Best suited to repeated hands-on practice at graduated difficulty once a concept is already understood from WebGoat.

Default credentials: `admin` / `password`

## OWASP Security Shepherd

Gamified, competitive challenge platform (scoreboard, class/team system), spanning a broader category set than WebGoat/DVWA (OWASP Top 10 plus cryptography, client-side, and mobile challenges). Best suited as a competitive/capstone exercise (Level 7) once foundational knowledge is already established via WebGoat/DVWA.

Runs via Docker Compose (three containers: `secshep_tomcat`, `secshep_mariadb`, `secshep_mongo`), configured to survive a host reboot. Access via HTTPS only, self-signed certificate.

Admin credentials: `admin` / `password` on first login, requires a password change.

Student account: `student` / `student`, assigned to the "2026 uow-class" class.

## Notes

- All four platforms sit outside the deliberately-vulnerable infrastructure services documented in `r-`/`e-` activity files; they are training curricula with their own internal guidance, not targets requiring bespoke reconnaissance/exploitation write-ups in this project.
- DNS records for `webgoat`, `webwolf`, `dvwa`, and `shepherd` are included in `db.uow-csf.internal` alongside the infrastructure service records.
