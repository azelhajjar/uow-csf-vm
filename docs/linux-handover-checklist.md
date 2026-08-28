# Linux VM Handover Checklist

## Status

Tracking document for `cav-csf-linux` master VM handover to the lab technician. Separate from the Windows AD design document (`w-01-windows-ad-baseline-design.md`), since this covers Linux-side student-facing polish and build-artefact cleanup rather than AD design.

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

Tracked in `w-01-windows-ad-baseline-design.md`, not duplicated here. Summary: master Linux VM successfully joined `uow-csf.internal` via `realmd`/`sssd` using the dedicated `svc-linux-auth` service account, login confirmed working, home directory auto-creation confirmed.

## 2. Linux Student-Facing Polish

Not yet reviewed in this session. Items to check before handover:

- Landing page wording
- Landing page colours
- Login banner / MOTD content
- GitHub issue-reporting link (confirm it points to `https://github.com/azelhajjar/uow-csf-vm.git` as documented, and is reachable/correct)
- Hostname/IP references throughout any visible documentation or on-VM content
- References to the Windows DC hostname/domain (should reflect `uow-csf-dc.uow-csf.internal` / `uow-csf.internal` accurately, if referenced at all)
- Any remaining wording that implies the VM is still SecGen-generated (SecGen acknowledgement belongs in GitHub README/docs only, never on the landing page or login banner)

## 3. Handover Cleanup

Status: substantially complete. Journal history, shell history, mailname/Postfix hostname, and SecGen filesystem/package residuals all reviewed and addressed above. Remaining from the original list:

- Temporary files / scratch files: appears already handled during the build itself (`~/kde-plasma-packages.txt`, `~/error.log`, `~/installnotes` were removed during the KDE purge/cleanup steps visible in shell history before it was cleared). Not independently re-verified in this session, worth a final `ls -la ~` sanity check across accounts if a fully certain state is wanted.
- Browser/download artefacts: not yet checked.
- Confirm no unintended credentials, screenshots, logs, or notes are left in student-visible locations: not yet independently verified beyond what's covered above.

## Scope Note

Reconnaissance is explicitly out of scope for this handover checklist. Reconnaissance is part of later student-facing lab design, not build/handover validation.
