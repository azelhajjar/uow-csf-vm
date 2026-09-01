# Activity 9: Sudo AWK Privilege Escalation — Not Provisioned (Negative Finding)

## Summary

The SecGen build was expected to include a sudo rule permitting privilege escalation via `awk` (a well-known GTFOBins technique where a NOPASSWD sudo grant on `/usr/bin/awk`, or a wrapper invoking it, allows arbitrary command execution as root). Direct inspection of the sudoers configuration on the disposable exploitation VM, performed with root access obtained via `08-suid-nano-privileged-file-write.md`, confirms this rule does not exist anywhere on the system. This is recorded as a negative finding rather than left as an open question.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.200 |
| Attacker | Kali VM on the same host-only lab network |
| Access used | root, via `analyst` → `sudo su` (exploit 08 artefact) |
| Attacker | Kali, 192.168.144.129 |

## Background

Six scenario accounts were previously checked individually via `sudo -l` and showed no AWK-related rule:

```text
backupsvc
webops
analyst
aberrant_distance
druid
distccd
```

Each showed only the baseline `(root) NOPASSWD: /usr/bin/sudo -l` entry, plus any exploit-specific rule already documented elsewhere (e.g. `aberrant_distance`'s `/usr/sbin/service *`). Rather than continuing to check accounts one at a time, root access already available on the disposable instance was used to inspect the sudoers configuration directly.

## Investigation

```bash
grep -rn "awk" /etc/sudoers /etc/sudoers.d/ 2>/dev/null
cat /etc/sudoers
ls -la /etc/sudoers.d/
for f in /etc/sudoers.d/*; do echo "== $f =="; cat "$f"; done
```

## Evidence

The `grep` for `awk` returned no matches. Full sudoers content:

```text
root    ALL=(ALL:ALL) ALL
uow-admin ALL=(ALL) NOPASSWD: ALL
%sudo   ALL=(ALL:ALL) ALL
analyst ALL=(ALL) NOPASSWD:ALL
```

`/etc/sudoers.d/10_users_sudo_list` (Puppet-managed):

```text
ALL  ALL=(root) NOPASSWD: /usr/bin/sudo -l
```

`/etc/sudoers.d/10_users_sudo_service` (Puppet-managed):

```text
aberrant_distance ALL=(root) NOPASSWD: /usr/sbin/service *
```

No other sudoers drop-in files are present.

## Analysis

Every sudo rule on the system is accounted for:

- `root`, `%sudo` group: standard Debian baseline.
- `uow-admin`: administrative access reserved for VM management, not a scenario/student account, and out of scope for exploitation or documentation.
- `analyst ALL=(ALL) NOPASSWD:ALL`: exploitation artefact from `08-suid-nano-privileged-file-write.md`, not part of the original provisioned scenario.
- `10_users_sudo_list`: harmless baseline `sudo -l` grant applied broadly.
- `10_users_sudo_service`: the already-documented exploit 04 rule for `aberrant_distance`.

No rule grants any account (individually or via group) the ability to run `/usr/bin/awk`, or any wrapper script invoking it, with elevated privilege. The intended SecGen sudo-AWK privilege-escalation module was therefore not provisioned on this build.

## Outcome

Confirmed absence of the sudo AWK privilege-escalation vector. This is not a tooling failure or a missed account. No further investigation of this vector is warranted on the current build.

## Remediation

Not applicable; no vulnerability exists to remediate. Recorded for completeness and to prevent re-investigation.

## Teaching Notes

Demonstrates that a scenario expected from a provisioning framework (SecGen) cannot be assumed present, and that a definitive negative result, once verified directly against the authoritative configuration (`/etc/sudoers` and `/etc/sudoers.d/`), is more useful than an unresolved gap. If an equivalent GTFOBins-style sudo `awk` exercise is wanted for teaching purposes, it would need to be added manually (e.g. `<account> ALL=(root) NOPASSWD: /usr/bin/awk`) as a deliberate scenario addition rather than assumed to already exist.

## Lab Dependencies

**Prerequisite exploit(s):** Exploit 08 - SUID Nano privilege escalation (used to obtain root for direct sudoers inspection)
**Required starting access:** Root access on the disposable exploitation VM
**Starting account:** `root` (via `analyst`)
**Resulting access:** N/A (negative finding, no privilege change)
**Provides access for:** N/A
**Suggested teaching level:** Level 6–7 (illustrates provisioning validation and the discipline of confirming absence rather than assuming it)
