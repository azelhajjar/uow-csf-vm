# Kali VM Updates

## Purpose

This document records the Kali VM updates for the CAV-CSF lab refresh from the 2025 Kali image to the 2026 Kali image.

The main change is that the Kali VM no longer needs to host Docker containers for the web application platforms. The web applications now run on the CAV-CSF Linux VM, and Kali is used as the attacker/workstation VM.

## Current Direction

The 2025 Kali VM included Docker-based web application containers. These are no longer required in the 2026 setup because the web application platforms are already deployed on the Linux VM.

The Kali VM now points to the Linux VM for web application access. There is no requirement to point Kali to a Windows VM web page, because the Windows VM is only used in selected modules and is not expected to be running all the time.

## Completed Updates

- Removed the need for Kali-hosted Docker web application containers from the 2026 workflow.
- Updated Kali host entries so the web application hostnames point to the CAV-CSF Linux VM.
- Confirmed that no Windows VM web page needs to be configured as a routine Kali target.
- Saved browser bookmarks for the web application platforms.
- Configured FoxyProxy.
- Set up Burp Suite with the required certificates.
- Changed the keyboard language/layout to GB.
- Changed the default terminal shell to Bash instead of Zsh.
- Tested the `studentid` script.
- Tested the `switchdns` script.

## Web Application Access

The web application platforms are hosted on the CAV-CSF Linux VM:

- WebGoat
- WebWolf
- DVWA
- OWASP Security Shepherd
- OWASP Juice Shop

Kali should access these through the Linux VM hostnames/IP configuration rather than running local Docker copies.

## Remaining Issue

- Alfa wireless adapter drivers failed during setup and need further checking.

## Status

The Kali VM update is mostly complete for the 2026 lab workflow. The only currently recorded outstanding item is the failed Alfa wireless driver setup.
