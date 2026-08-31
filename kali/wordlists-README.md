# CAV-CSF Lab Wordlist

## Purpose

A compact, scenario-themed wordlist for password guessing/cracking activities across CAV-CSF, used in place of `rockyou.txt` where a targeted, explainable wordlist is the more appropriate teaching tool than a large generic breach corpus. 153 entries, plain text, one candidate per line, no comments (comment lines would otherwise be read as literal candidate passwords by John/Hashcat).

**Recommended location on Kali:** `/usr/share/wordlists/cav-csf-wordlist.txt` (alongside `rockyou.txt`, for a consistent `-w` path across write-ups), or a working-directory equivalent such as `~/wordlists/cav-csf-wordlist.txt` if system-wide placement isn't wanted. Either is fine; whichever is used should be stated once and then kept consistent across `r-`/`e-` files, per the project's existing preference for reproducible, unchanging paths.

## Design rationale

The list is built from roots drawn directly from CAV-CSF's own established naming, not generic placeholders, so the exercise is explainable as "recon-informed targeted guessing" rather than arbitrary mutation:

| Category | Roots used | Source in project |
|---|---|---|
| Organisation/scenario identity | `cavcsf`, `cav-csf`, `cavlab`, `uowcsf`, `uow`, `westminster`, `universityofwestminster`, `cwscenario` | VM/domain naming (`cav-csf-linux`, `cav-csf-windows`, NetBIOS `UOWCSF`), the registered teaching domain `cwscenario.uk`, and the University of Westminster context |
| Service/role names | `web`, `webservice`, `svcweb`, `backup`, `backupsvc`, `helpdesk`, `ithelpdesk`, `analyst`, `staff`, `staffadmin`, `admin`, `administrator`, `printsrv`, `labstudents` | Existing AD accounts/groups (`svc-web`, `backup.operator`, `helpdesk01`, `analyst`, `Staff-Admin`, `IT-Helpdesk`, `Lab-Students`) and the SNMP-disclosed `PRINT-SRV-01` hostname (`r-15`) |
| Lab-style convention | `csflab` | Generic lab-branding root, distinct from the specific VM/domain names above |

Each root is expanded with a small, fixed transformation rule rather than a full combinatorial mutation, so the list stays compact and the pattern is easy to state to students in one sentence: **bare root, capitalised root, root+`1`, capitalised root+`123`, root+`2026`, capitalised root+`2026!`.** That is deliberately the same shape as the project's own real Phase 1 baseline convention (`CavLab2026!`), a targeted wordlist built from organisational recon would very plausibly reconstruct a real credential built on the same convention, which is the point being taught.

**Correction (153 entries):** the mechanical rule capitalises only the first letter (`"cavlab".capitalize()` → `Cavlab`), which does not reproduce the real convention's internal capitalisation (`CavLab`, compound-word style). `CavLab2026!` was added as an explicit exact-case entry alongside the mechanically generated `Cavlab2026!`, otherwise a password-spray/crack attempt against the project's actual Phase 1 baseline password would silently miss it, passwords are case-sensitive and a wordlist that "looks right" is not the same as one that matches. Worth keeping as a standing lesson: verify a targeted wordlist's assumptions against the real target convention rather than trusting the generation rule blindly.

A small set of hand-picked composites (`Cav-Csf2026!`, `Cwscenario@2026`, `Web#1`, etc.) round out the list with alternative separators (`@`, `#`, `!`) and mixed-case-plus-symbol patterns likely to satisfy AD-style complexity, without expanding those combinations across every root.

**Not included by design:** full cross-product of every root against every suffix and separator (`cavcsf!`, `cavcsf@`, `cavcsf#`, `cavcsf1!`, …). That would produce several thousand lines and shift the exercise from *targeted wordlist design* to *small-scale brute force*, which is explicitly not the teaching point here.

## When to use this list instead of `rockyou.txt`

- Any activity whose teaching point is wordlist tailoring itself: OSINT/recon-informed guessing against an account or service where the organisation's naming convention is knowable in advance.
- Live/online guessing against a network service (SSH, FTP, SMB, a web login) where a 14-million-line list would take too long for a classroom session, or risks account lockout/rate-limiting before a match is found.
- Any case where the write-up wants a controlled, fast, reproducible cracking time so the lesson is about the *method*, not about waiting.

## When `rockyou.txt` is still the right choice

- Offline cracking against a credential with no organisational theming reason to expect it follows CAV-CSF's naming convention (this project's existing `e-07` shadow-file cracking is a good example: `webops:administrator`, `analyst:password` are generic weak choices, not CAV-CSF-themed).
- Any activity whose teaching point is precisely that generic, non-targeted attacker behaviour still succeeds against ordinary weak passwords, independent of organisational recon.
- As a deliberate comparison: running both lists against the same hash and contrasting outcome/time is a legitimate, worthwhile activity in its own right (targeted-but-small vs generic-but-huge), consistent with the project's existing habit of treating tooling/method choices as claims to verify rather than defaults to assume.

## Companion file: `candidate-users.txt`

A separate, much smaller file, plausible domain username guesses (`administrator`, `admin`, `analyst`, `helpdesk`, `helpdesk01`, `backup`, `backup.operator`, `support`, `webadmin`, `svc-web`, `service`, `guest`), built the same way as the password list: role/naming-convention-informed guessing rather than a generic list. Used for Kerberos pre-authentication username validation (`nmap --script krb5-enum-users`) as part of Windows/AD reconnaissance, not for password cracking. Recommended location: `~/candidate-users.txt` alongside `cav-csf-wordlist.txt`.

## Documenting wordlist choice in `r-`/`e-` files

Following the existing Markdown conventions (Section 3.1 of the baseline):

- State the wordlist used, its path, and its line count in `Lab Dependencies` or the relevant `Credential Discovery / Cracking` section, not just the tool invocation.
- State *why* that wordlist was chosen for that activity (targeted/CAV-CSF-themed vs generic breach corpus), one sentence is enough.
- If both lists are tried, show both attempts and their outcomes, in the same style already used for tool-output verification elsewhere in the project (a result is a claim until independently confirmed).
- Reference this document (`wordlists-README.md`) rather than re-explaining the list's design in each activity file.

## Full list (153 entries)

```text
cavcsf
Cavcsf
cavcsf1
Cavcsf123
cavcsf2026
Cavcsf2026!
cav-csf
Cav-csf
cav-csf1
Cav-csf123
cav-csf2026
Cav-csf2026!
cavlab
Cavlab
cavlab1
Cavlab123
cavlab2026
Cavlab2026!
CavLab2026!
uowcsf
Uowcsf
uowcsf1
Uowcsf123
uowcsf2026
Uowcsf2026!
uow
Uow
uow1
Uow123
uow2026
Uow2026!
westminster
Westminster
westminster1
Westminster123
westminster2026
Westminster2026!
universityofwestminster
Universityofwestminster
universityofwestminster1
Universityofwestminster123
universityofwestminster2026
Universityofwestminster2026!
cwscenario
Cwscenario
cwscenario1
Cwscenario123
cwscenario2026
Cwscenario2026!
web
Web
web1
Web123
web2026
Web2026!
webservice
Webservice
webservice1
Webservice123
webservice2026
Webservice2026!
svcweb
Svcweb
svcweb1
Svcweb123
svcweb2026
Svcweb2026!
backup
Backup
backup1
Backup123
backup2026
Backup2026!
backupsvc
Backupsvc
backupsvc1
Backupsvc123
backupsvc2026
Backupsvc2026!
helpdesk
Helpdesk
helpdesk1
Helpdesk123
helpdesk2026
Helpdesk2026!
ithelpdesk
Ithelpdesk
ithelpdesk1
Ithelpdesk123
ithelpdesk2026
Ithelpdesk2026!
analyst
Analyst
analyst1
Analyst123
analyst2026
Analyst2026!
staff
Staff
staff1
Staff123
staff2026
Staff2026!
staffadmin
Staffadmin
staffadmin1
Staffadmin123
staffadmin2026
Staffadmin2026!
admin
Admin
admin1
Admin123
admin2026
Admin2026!
administrator
Administrator
administrator1
Administrator123
administrator2026
Administrator2026!
printsrv
Printsrv
printsrv1
Printsrv123
printsrv2026
Printsrv2026!
labstudents
Labstudents
labstudents1
Labstudents123
labstudents2026
Labstudents2026!
csflab
Csflab
csflab1
Csflab123
csflab2026
Csflab2026!
Cav-Csf2026!
Uow-Csf2026!
CavCsf#2026
UowCsf#2026
Cwscenario@2026
Cwscenario#1
Web@2026
Backup@2026
Helpdesk@2026
Analyst@2026
Admin@2026
Staff#1
Backup#1
Web#1
```