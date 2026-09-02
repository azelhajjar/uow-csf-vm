# Linux VM Handover Checklist

## Status

Tracking document for `cav-csf-linux` master VM handover to the lab technician. Separate from the Windows AD design document (`w-01-windows-ad-baseline-design.md`), since this covers Linux-side student-facing polish and build-artefact cleanup rather than AD design.

**Handover has taken place.** The Linux VM has been supplied to the lab technician for the lab repository. This changes the status of everything below: remaining items are no longer pre-handover tasks but changes that would require re-supplying the image. They should be batched into a scheduled re-supply rather than actioned individually, and each should be weighed against the disruption of replacing an image already in the lab repository.

Functionally the delivered image is sound. The five web application platforms have been tested and confirmed working with the Windows VM powered off, which is the normal operating state for all but two modules. No outstanding student-facing polish item is currently recorded; any future polish would be a new re-supply decision, not a pre-handover task.

Nothing here should be deleted or edited without confirmation first, per the original scope instruction: produce a checklist/report, then wait for approval before acting on each item.

## Completed

- **Journal history cleared.** `sudo journalctl --rotate` + `sudo journalctl --vacuum-time=1s` run on master. Freed 334.3M, disk usage down from 95.8M to 8.0M. This removed old boot records referencing the original SecGen-inherited hostname (`SecGen-cav-csf-linux-cav-csf-linux`, visible in `journalctl -u sssd` history predating the later hostname change), along with general build-era log noise (credential attempts, package installs, cron activity from testing).
- **Current hostname confirmed clean.** `hostnamectl` and `/etc/hostname` both show `cav-csf-linux`, no SecGen prefix, confirming the fix is permanent going forward, not just log cleanup.
- **Shell history cleared.** `.bash_history` truncated to zero for `uow-admin`, `student`, and root, all in one pass.
- **`erlang-otp-prebuilt` package reviewed, kept as-is.** `dpkg -l | grep -i secgen` surfaced this package (description reads "Prebuilt Erlang/OTP ... for SecGen"). Confirmed load-bearing for the deliberate `e-03` Erlang OTP SSH RCE scenario: `erlang-otp-ssh-rce.service` is running correctly, no SecGen reference anywhere in the systemd unit, process, or service description, and the service is confirmed listening on port 2222 as intended. The only remaining SecGen trace is the `dpkg -l`/`dpkg -s` package description string itself, low-visibility (only surfaces if a student specifically inspects package metadata, not via service enumeration, banners, or the landing page). Editing it directly would mean hand-modifying `/var/lib/dpkg/status`, a non-standard operation that would also be overwritten by any future `apt` operation on the package, so it wouldn't be a durable fix. Decision: leave as-is, consistent with the project's existing stance that SecGen is acknowledged as historical/inspirational origin in project documentation, this is backend package metadata in the same category, not student-visible surface.
- **No filesystem paths/directories named after SecGen.** `find / -iname "*secgen*"` returned nothing beyond the one package name above.

- **`/etc/mailname` and Postfix `mydestination` fixed.** Both carried the old SecGen-prefixed hostname (`SecGen-cav-csf-linux-cav-csf-linux`). `/etc/mailname` reset to `cav-csf-linux`, the same string removed from `main.cf`'s `mydestination` line, Postfix restarted, both confirmed clean via `cat /etc/mailname` and `postconf mydestination`.
- **No `.13x` disposable-range IP references** anywhere under `/etc`, `/var/www`, `/opt`.

## Open (low priority)

- **Git reflog entries reference the old SecGen-prefixed hostname**, found in `/var/www/dvwa/.git/logs/` and `/opt/SecurityShepherd/.git/logs/` (checkout/fetch history for those cloned repos). Not visible via normal use, internal git history rather than student-facing content. Left as-is; can be cleared with `truncate -s 0` on those log files if a fully clean state is wanted.

## 1. Functional AD Integration

Tracked in `w-01-windows-ad-baseline-design.md` and `ad-integration.md`, not duplicated here. Summary: master Linux VM successfully joined `uow-csf.internal` via `realmd`/`sssd` using the dedicated `svc-linux-auth` service account, login confirmed working, home directory auto-creation confirmed.

DNS note, resolved: the Linux BIND9 instance and the DC both hold a zone for `uow-csf.internal`. This is an accepted deliberate split, not a defect. The Linux VM resolves independently and the web application platforms were confirmed working with the Windows VM powered off. The outstanding Linux-to-DC reachability checks in `w-01-windows-ad-baseline-design.md` apply only to the two modules that use both machines and should be validated with both running. See `ad-integration.md`.

## 2. Linux Student-Facing Polish

Student-facing polish has been reviewed and completed for the supplied Linux master image.

The landing page has been updated and verified at `http://192.168.144.100/`. It is served by Apache from `/var/www/html/index.html`, owned by `www-data:www-data`, mode `0644`, with browser title `CAV-CSF Linux Lab Environment`, visible host/IP context for `cav-csf-linux`, service links for the five web applications, appropriate fixed credentials where the application genuinely uses them, no fixed Juice Shop credential hint, and the GitHub issue-reporting link present.

Login banner / MOTD content, visible hostname/IP references, Windows DC/domain references, and visible SecGen-generated wording have also been reviewed as part of the handover polish pass. No outstanding student-facing polish item is currently recorded here.

## 3. Handover Cleanup

Handover cleanup has been completed for the supplied Linux master image.

Journal history, shell history, mailname/Postfix hostname, SecGen filesystem/package residuals, temporary/scratch files, browser/download artefacts, and student-visible credential/screenshot/log/note locations have all been reviewed and addressed as part of the handover pass.

No outstanding handover-cleanup item is currently recorded here. Any future cleanup should be treated as a new re-supply decision, not as unfinished work from the original handover.

## Scope Note

Reconnaissance is explicitly out of scope for this handover checklist. Reconnaissance is part of later student-facing lab design, not build/handover validation.
