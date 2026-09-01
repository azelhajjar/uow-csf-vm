# DCSync Replication Rights Enumeration

## Summary

`backup.operator` (Backup Operator, `OU=Users,OU=UOW-CSF`, member of `Backup-Operators-Lab`) has been granted the `DS-Replication-Get-Changes` and `DS-Replication-Get-Changes-All` extended rights directly on the domain naming context (`DC=uow-csf,DC=internal`), rights normally reserved for Domain Controllers, Domain Admins, and Enterprise Admins. Using the domain credential recovered in `r-19`, this activity enumerates the domain object's access control entries from Kali and identifies `backup.operator` as holding both rights, with no administrative group membership of its own to justify them.

## Environment

| Item | Value |
|---|---|
| Target | `uow-csf-dc.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` |
| Target account | `backup.operator` (Backup Operator) |
| Attacker | Kali VM on the same host-only lab network |
| Tools | `bloodhound-python`, `python3` (standard library `json`/`glob`) |

## Lab Dependencies

- Prerequisite: `r-19` (Windows/AD enumeration), which recovered a working domain credential, `analyst` / `CavLab2026!`. That credential, not `backup.operator`'s own, authenticates the collection below, keeping the discovery step independent of the account it goes on to implicate.
- Starting access: an authenticated domain credential (`analyst`), no elevated rights required.
- Resulting access: confirmation that `backup.operator` holds `DS-Replication-Get-Changes` and `DS-Replication-Get-Changes-All` on the domain object, an ACL misconfiguration rather than a group-membership one.
- Feeds into: `e-21` (DCSync exploitation via `backup.operator`).
- Suggested teaching level: Level 7.

## Reconnaissance

### BloodHound collection

An extended-rights ACE on a domain object is not practical to identify by manually parsing a raw `nTSecurityDescriptor`, so this activity uses `bloodhound-python`'s LDAP-based collection, scoped to the domain controller only rather than also touching client machines for session/local-admin data:

```bash
bloodhound-python -u analyst -d uow-csf.internal -ns 192.168.144.200 -c DCOnly --zip
```

```text
INFO: BloodHound.py for BloodHound LEGACY (BloodHound 4.2 and 4.3)
Password:
INFO: Found AD domain: uow-csf.internal
INFO: Getting TGT for user
WARNING: Failed to get Kerberos TGT. Falling back to NTLM authentication. Error: [Errno Connection error (uow-csf-dc.uow-csf.internal:88)] [Errno -3] Temporary failure in name resolution
INFO: Connecting to LDAP server: uow-csf-dc.uow-csf.internal
INFO: Found 1 domains
INFO: Found 1 domains in the forest
INFO: Connecting to LDAP server: uow-csf-dc.uow-csf.internal
INFO: Found 12 users
INFO: Found 57 groups
INFO: Found 2 gpos
INFO: Found 6 ous
INFO: Found 19 containers
INFO: Found 2 computers
INFO: Found 0 trusts
INFO: Done in 00M 07S
INFO: Compressing output into 20260901043648_bloodhound.zip
```

The Kerberos TGT attempt fails on name resolution and the collector falls back to NTLM automatically; the collection itself still completes cleanly. No BloodHound GUI (a Neo4j server plus the legacy Electron client, or the newer Community Edition's Docker-based stack) ships with the standard Kali platform, so this activity uses the collector's JSON output directly rather than a graph visualisation.

### Confirming DCSync-capable principals

```bash
unzip -o 20260901043648_bloodhound.zip -d bh_master_out
python3 -c "
import json, glob

sid = None
for f in glob.glob('bh_master_out/*_users.json'):
    for u in json.load(open(f))['data']:
        if 'BACKUP.OPERATOR' in u['Properties'].get('name', '').upper():
            sid = u['ObjectIdentifier']

print('SID:', sid)

for f in glob.glob('bh_master_out/*_domains.json'):
    for d in json.load(open(f))['data']:
        for ace in (d.get('Aces') or []):
            if ace.get('PrincipalSID') == sid:
                print(ace)
"
```

```text
SID: S-1-5-21-2568529206-4255560700-1706989125-1109
{'RightName': 'GetChanges', 'IsInherited': False, 'PrincipalSID': 'S-1-5-21-2568529206-4255560700-1706989125-1109', 'PrincipalType': 'User'}
{'RightName': 'GetChangesAll', 'IsInherited': False, 'PrincipalSID': 'S-1-5-21-2568529206-4255560700-1706989125-1109', 'PrincipalType': 'User'}
```

Both extended rights are non-inherited and attached directly to `backup.operator`'s own SID, not to a group it belongs to, confirming a deliberate, individually-scoped grant rather than an inherited or accidental policy effect.

## Outcome

Using only the domain credential already recovered in `r-19`, this activity identified `backup.operator` as holding `DS-Replication-Get-Changes` and `DS-Replication-Get-Changes-All` directly on `DC=uow-csf,DC=internal`, the two rights that together permit full directory replication (DCSync) via the MS-DRSR protocol. `backup.operator` carries no corresponding administrative group membership; this is an ACL misconfiguration, not a privileged-group placement. Feeds into `e-21`.

## Teaching Notes

- This is a materially different reconnaissance problem from group-membership misconfigurations: an ACE grant on an object's security descriptor is not visible through a simple LDAP attribute query, and needs ACL-aware tooling such as BloodHound's collector rather than a plain `ldapsearch` filter.
- No BloodHound GUI ships by default on Kali; this activity's reconnaissance step is reproducible with only the collector and the Python standard library, without any additional package installation.
- The Kerberos-to-NTLM authentication fallback during collection is a Kali-side DNS resolution detail, not a scenario finding, and does not affect the result.
