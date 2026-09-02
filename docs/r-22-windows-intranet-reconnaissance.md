# Windows Intranet Reconnaissance

## Summary

Anonymous, unauthenticated reconnaissance value of the UOW-CSF staff intranet, a lightweight static IIS site at `uow-intranet.uow-csf.internal` (`192.168.144.200`), running under the `svc-web` service account, the same account already demonstrated Kerberoastable in `e-18`, giving its SPN (`HTTP/uow-intranet.uow-csf.internal`) a genuine running service behind it. The site is ordinary organisational content, not a deliberate vulnerability, but its staff directory, department pages, and service-desk reference expose real staff names, departments, and internal share paths of direct reconnaissance value.

## Environment

| Item | Value |
|---|---|
| Target | `uow-intranet.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` |
| Service | IIS (Windows Server 2019), static HTML, anonymous access, no database |
| Application pool identity | `UOWCSF\svc-web` |
| Attacker | Kali VM on the same host-only lab network |

## Lab Dependencies

- Prerequisite: DNS resolution of `uow-intranet.uow-csf.internal` to `192.168.144.200`; no credential and no prior access required.
- Starting access: none (unauthenticated, anonymous).
- Resulting access: staff names, departments, job titles, department share paths, and a named service-desk account, organisational reconnaissance value, not a credential or shell.
- Feeds into: corroborates the first-initial-surname naming convention `cav-csf-users.txt`/`cav-csf-wordlist.txt` already assume (`r-19`), and confirms `svc-web`'s SPN (`e-18`) corresponds to a real running service rather than an unused registration.
- Suggested teaching level: Level 4.

## Reconnaissance

### Site availability

```powershell
Invoke-WebRequest "http://uow-intranet.uow-csf.internal/" -UseBasicParsing | Select-Object StatusCode, Content
```

```text
StatusCode Content
---------- -------
       200 <!DOCTYPE html>...
```

Confirmed reachable, anonymous, HTTP 200, from a domain-joined Windows client and opened successfully from the Kali browser.

### Site structure and disclosed content

The homepage links to a staff directory, a service-desk page, and one page per department (Finance, HR, IT Support, Web Services, Registry, Estates, Operations). Browsing the site anonymously discloses:

- **Staff directory** (`staff-directory.html`): full name, department, and job title for all eight staff accounts, Aisha Hassan (Finance), Liam Morgan (HR), Nadia Ali and Rina Patel (IT Support), Emily Brown (Web Services), Tom Evans (Registry), Mei Chen (Estates), and Samuel Okafor (Operations).
- **Department pages**: each names its staff member(s) again and states the department's file-share path, for example `\\uow-csf-dc\Finance`, `\\uow-csf-dc\HR`, and the equivalent for each of the seven departments.
- **Service desk page** (`service-desk.html`): names `helpdesk01@uow-csf.internal` as the ticketing account and identifies the IT Support team.

None of this requires authentication or any tool beyond a browser or `curl`.

## Outcome

An anonymous, unauthenticated visitor to the intranet learns real staff names and departments, the department file-share layout, and a named service-desk account, all without needing a credential. This corroborates the organisational naming convention the project's existing wordlists are already built around, and records that the intranet is intentionally tied to the `svc-web` service identity used by the SPN in `e-18`.

## Teaching Notes

- This is ordinary organisational content, not a deliberate misconfiguration; the reconnaissance value comes from what a normal staff intranet naturally discloses, not from a bug.
- The named service-desk account and department shares are believable next steps for a student to pursue once this page has been found, without the site itself being an exploitation target.
- The application pool identity closes a gap left open by `e-18`: an SPN alone doesn't explain why an account has one, this shows a real service behind it.
