# Web Apps README — CAV-CSF Linux VM

Overview of the web application security training platforms deployed on this VM. Distinct from `services-README.md`, which covers the deliberately vulnerable/misconfigured infrastructure services (CUPS, Samba, SNMP, etc.). These are self-contained training curricula with their own built-in lessons/guidance; no bespoke `r-`/`e-` reconnaissance or exploitation write-ups exist for them in this project, separate lab materials are used instead.

---

## Summary Table

| Platform | Port | DNS Record |
|---|---|---|
| WebGoat | 8080/tcp | `webgoat.uow-csf.internal` |
| WebWolf | 9090/tcp | `webwolf.uow-csf.internal` |
| DVWA | 8090/tcp | `dvwa.uow-csf.internal` |
| OWASP Security Shepherd | 8543/tcp (HTTPS) | `shepherd.uow-csf.internal` |
| OWASP Juice Shop | 3000/tcp | `juiceshop.uow-csf.internal` |

## Quick Access Links

All five platforms have been tested and confirmed working with the Windows VM powered off, which is the normal state for all but two modules. Hostname access is served by the Linux VM's own BIND9 instance and does not depend on the domain controller being reachable; IP access performs no name lookup at all and is therefore unaffected by any DNS or domain-join consideration.

One addressing caveat: `192.168.144.100` is the Linux VM's intended final static address, while the master VM has been tracked at `192.168.144.130` pending the static IP migration noted in `services-README.md`. Confirm which address the image supplied to the lab technician actually uses before circulating these URLs to students.

| Platform | URL (by hostname) | URL (by static IP) |
|---|---|---|
| WebGoat | `http://webgoat.uow-csf.internal:8080/WebGoat/` | `http://192.168.144.100:8080/WebGoat/` |
| WebWolf | `http://webwolf.uow-csf.internal:9090/login` | `http://192.168.144.100:9090/login` |
| DVWA | `http://dvwa.uow-csf.internal:8090/` | `http://192.168.144.100:8090/` |
| Security Shepherd | `https://shepherd.uow-csf.internal:8543/` | `https://192.168.144.100:8543/` |
| Juice Shop | `http://juiceshop.uow-csf.internal:3000/` | `http://192.168.144.100:3000/` |

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

## OWASP Juice Shop

Modern, self-contained vulnerable web application (Node.js/Angular) covering the OWASP Top 10 and beyond, with a built-in scoring system that tracks solved challenges in-app rather than via an external scoreboard. No installation prerequisites for students beyond a browser, well suited as either an open-ended, self-paced practice target or a structured challenge sequence, and complements the more guided WebGoat and freeform DVWA formats already on this VM.

No default admin account; students self-register through the app's own registration flow, which is itself part of the intended challenge set (account enumeration, weak validation, etc.). Runs natively via Node.js (not Docker), managed as a systemd service so it survives a host reboot.

## Notes

- All five platforms sit outside the deliberately-vulnerable infrastructure services documented in `r-`/`e-` activity files; they are training curricula with their own internal guidance, not targets requiring bespoke reconnaissance/exploitation write-ups in this project.
- DNS records for `webgoat`, `webwolf`, `dvwa`, `shepherd`, and `juiceshop` are included in `db.uow-csf.internal` alongside the infrastructure service records. They are served by the Linux VM itself, which is why they continue to resolve when the Windows VM is offline. See `ad-integration.md` for why the zone is deliberately split between the two machines.
