# Exploit 8: Privilege Escalation via SUID Nano (Privileged File Write, Not Shell Spawn)

## Summary

`/usr/bin/nano` is installed setuid-root. The standard GTFOBins technique (spawn a shell from nano's `Ctrl+R`/`Ctrl+X` "Execute Command" prompt) does **not** work on this build, nano 7.2 drops back to the real UID before handing control to a spawned child process. However, nano's own file read/write operations still run with full root privilege, so a low-privilege user can open and directly edit a root-owned, root-only file (`/etc/sudoers`) through the editor itself, and save the change as root. This was used to append a full NOPASSWD sudo rule for the invoking account, giving unrestricted root access.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Misconfiguration | `/usr/bin/nano` installed with the setuid bit (`-rwsr-xr-x root root`) |
| Attacker | Kali, 192.168.144.129 |
| Starting account | `analyst` (uid 1003), reached via SSH using credentials cracked in `e-07- readable-shadow-credential-cracking.md` |
| Resulting account | `root` (uid 0) |

## Vulnerability

`file /usr/bin/nano` confirms the setuid bit is present in the binary's own ELF header, and `ls -la` confirms it on disk:

```
-rwsr-xr-x 1 root root 287480 May  6  2024 /usr/bin/nano
```

Nano's build here compiled with `--disable-libmagic --enable-utf8` and no special hardening flags, but nano 5.x and later deliberately drops the effective UID back to the real UID before executing an external command (the `Ctrl+X`/"Execute Command" feature), specifically to close the well-known SUID-shell-spawn technique. This was confirmed empirically below. What is **not** dropped is nano's own file-handling privilege: opening, reading and writing files from within the editor continues to use the process's (root) effective UID for as long as the process is alive, so any file the real root user could read or write, the invoking low-privilege user can also read or write via nano (CWE-269, Improper Privilege Management, combined with CWE-732 style unsafe SUID assignment on an editor with no restriction on which files it may touch).

## Investigation: confirming the shell-spawn path is blocked

Initial attempt followed the standard GTFOBins nano technique:

```
nano
```
`Ctrl+R`, `Ctrl+X` (switches the "Insert File" prompt to "Execute Command"), then:
```
reset; sh 1>&0 2>&0
```

This produced a shell, but:

```
id
uid=1003(analyst) gid=1003(analyst) groups=1003(analyst)
```

No privilege gained. Confirmed this was not an environment issue (`NoNewPrivs: 0`, `/` not mounted `nosuid`) before concluding it was nano's own behaviour. Direct proof was obtained by inspecting nano's live process status while it held the "Executing..." state:

```
pgrep -a nano
cat /proc/<pid>/status | grep -i uid
```

```
Uid:    1003    0       0       0
```

Real UID 1003, effective UID 0: nano itself genuinely holds root while running, confirming the SUID bit is active. The spawned child process nonetheless ran as uid 1003, proving nano explicitly steps down before `exec`ing the external command, rather than the setuid bit being ineffective.

## Exploitation: privileged file write via nano's own file I/O

Tested whether nano's file-open (not command-execute) still carries root privilege, using a file unreadable to `analyst` directly:

```
ls -la /etc/sudoers
nano /etc/sudoers
```

The file opened (with nano's usual "read-only, unless you use... " warning banner for a file the invoking user doesn't normally own), confirming privileged read access. The same access permits write: a new line was appended,

```
analyst ALL=(ALL) NOPASSWD:ALL
```

and saved with `Ctrl+O`, Enter, `Ctrl+X`. The write succeeded as root despite `analyst` having no write permission on `/etc/sudoers` outside of the editor.

## Evidence

```
sudo -l
```

```
User analyst may run the following commands on cav-csf-linux:
    (root) NOPASSWD: /usr/bin/sudo -l
    (ALL) NOPASSWD: ALL
```

```
sudo su
whoami
root
id
uid=0(root) gid=0(root) groups=0(root)
```

## Outcome

Full root compromise from the `analyst` foothold, via a privileged file write rather than the more commonly taught shell-spawn SUID technique. Good teaching value specifically because the "obvious" GTFOBins approach fails and needs to be diagnosed (checking `NoNewPrivs`, mount flags, and finally the live process's real/effective UID split) before the actual bypass is found, this mirrors real-world hardened systems where common exploitation guides don't work out of the box.


## Remediation

- Remove the setuid bit from `/usr/bin/nano` (`chmod u-s /usr/bin/nano`); there is no legitimate reason for a general-purpose text editor to run as root for standard users.
- If privileged editing is genuinely required, use `sudo -e` / `sudoedit` with a controlled, audited set of files, rather than a blanket setuid binary.
- Treat SUID hardening in one code path (blocking shell spawn) as incomplete if the same binary retains unrestricted privileged file access; a security control that closes one exploitation primitive while leaving an equally serious one open provides false assurance.

## Lab Dependencies

**Prerequisite exploit(s):** Exploit 07 - World-readable `/etc/shadow` and offline credential cracking  
**Required starting access:** Authenticated shell as `analyst`  
**Starting account:** `analyst`  
**Resulting access:** Root access through privileged modification of `/etc/sudoers`  
**Provides access for:** No further student exploit is currently dependent on this path; it completes the Exploit 06 → 07 → 08 chain