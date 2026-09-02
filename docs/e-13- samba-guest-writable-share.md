# Activity: Samba Guest-Writable Share

## Summary

Exploitation of the guest-writable `HR-Shared` Samba share confirmed in `r-14- samba-share-reconnaissance.md`: retrieving its sensitive content and demonstrating file-planting capability, both achievable with zero credentials.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | Samba 4.17.12-Debian, share `HR-Shared` |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | smbclient |

## Vulnerability

The share is configured with `guest ok = yes`, `guest only = yes`, and `writable = yes` in `smb.conf`, combined with `map to guest = Bad User` at the global level, meaning any connection attempt, authenticated or not, is treated as guest. This is a straightforward access-control misconfiguration (CWE-284, Improper Access Control), not a software vulnerability; the Samba version itself is current and unaffected by any known CVE.

## Exploitation

**Retrieving the exposed content:**

```bash
smbclient //192.168.144.100/HR-Shared -N
```
```
smb: \> get Staff_Directory.csv
smb: \> get Staff_Rota_Sept2026.txt
```

Content retrieved:
```
Name,Employee ID,Department
J. Alcott,EMP1042,HR
R. Baxter,EMP1088,Finance
S. Chen,EMP1103,IT
```
```
Staff Rota - September 2026 - HR Department
```

This is a direct information-disclosure impact: an unauthenticated attacker obtains a staff directory (names, internal employee IDs, department assignments), exactly the kind of internal data that supports further social-engineering or credential-guessing attacks against the organisation.

**Demonstrating file-planting capability:**

```
smb: \> put /etc/hostname CUPS_RCE_PWNED_via_samba.txt
```

A successful upload confirms an attacker could plant arbitrary content on the share, malicious documents, macro-laden files, or (depending on what else consumes this share's contents elsewhere in the environment) a foothold for further compromise.

## Outcome

Confirmed unauthenticated information disclosure (staff directory content) and unauthenticated file-planting capability via the `HR-Shared` guest-writable Samba share. No credentials, no CVE, and no prior access were required at any stage.

## Remediation

- Remove `guest ok = yes` / `guest only = yes` from the share definition; require authenticated Samba users.
- Remove `map to guest = Bad User` from `[global]`, which currently causes any failed or unknown login to silently fall through to guest access rather than being rejected.
- Set `writable = no` (or `read only = yes`) unless guest write access is a genuine, deliberate business requirement, which it very rarely is.
- Restrict share visibility and access via `valid users` / `hosts allow` to only the specific accounts or hosts that require it.
- Review all shares on the server (including the auto-generated `[homes]`-style `nobody` share observed during enumeration) for the same class of misconfiguration.

## Teaching Notes

This activity, paired with `r-14`, is a strong Level 5-6 exercise precisely because it requires no exploit development, CVE research, or payload crafting at all, the entire "attack" is standard tooling used exactly as designed, against a service that is fully patched and correctly functioning. This is valuable for reinforcing that security assessments are as much about configuration review as vulnerability scanning, and that some of the most damaging real-world findings in professional engagements are exactly this class of issue: simple, unauthenticated access to sensitive data via basic misconfiguration.

## Lab Dependencies

**Prerequisite exploit(s):** `r-14- samba-share-reconnaissance.md`
**Required starting access:** Network access to the target from Kali
**Starting account:** None (guest/anonymous)
**Resulting access:** Read/write access to `HR-Shared` content; no shell or further system access
**Suggested teaching level:** Level 5-6
