# University of Westminster CAV-CSF VM Lab Environment

This repository documents the University of Westminster CAV-CSF virtual machine lab environment for cyber security and forensics teaching.

The environment currently includes:

- `cav-csf-linux`: a deliberately vulnerable Linux VM for service enumeration, web security, network services, and Linux-focused exploitation practice.
- `cav-csf-windows`: a Windows Server 2019 Active Directory VM for domain, DNS, Kerberos, SMB, and Windows/AD-focused activities.

The VMs are designed for use only inside the authorised University of Westminster lab environment.

## Current Status

### Linux VM

The Linux VM is the main general-purpose vulnerable target. It includes intentionally exposed or misconfigured services and web applications for teaching activities, including WebGoat, WebWolf, Security Shepherd, Juice Shop, DVWA, and supporting network services.

Current baseline:

- Hostname: `cav-csf-linux`
- IP address: `192.168.144.100`
- Student login: `student / student`
- Landing page: `http://192.168.144.100/`

### Windows AD VM

The Windows VM is being developed as a separate Active Directory lab machine. It is intended to integrate with the Linux VM rather than replace it.

Current planned baseline:

- VM name: `cav-csf-windows`
- Hostname: `uow-csf-dc`
- IP address: `192.168.144.200`
- Domain: `uow-csf.internal`
- NetBIOS name: `UOWCSF`
- Windows version: Windows Server 2019 Evaluation

## Design Approach

The lab is built around realistic misconfigurations and discoverable attack paths rather than isolated old CVEs. Students should be able to enumerate the environment, identify weaknesses, and follow deterministic teaching paths suitable for weekly lab activities, coursework preparation, and supervised cyber security and forensics work.

## Issue Reporting

Use this repository to report VM issues, missing documentation, broken services, or suggested improvements.

# Acknowledgements

Early exploratory work for the Linux VM used SecGen-generated Debian service ideas as a reference point.

The current CAV-CSF VM environment is a separately designed University of Westminster teaching environment and does not aim to reproduce a SecGen VM.
