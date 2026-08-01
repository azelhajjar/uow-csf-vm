# AP-01 Student Lab: Exposed Handover Credentials

## Scenario

You are conducting an authorised penetration test of a Brightleaf Retail Ltd Linux server in the isolated university lab. Brightleaf has asked you to determine whether exposed network services could allow an unauthorised user to obtain host access and escalate privileges.

The public `cwscenario.uk` website is contextual material only. It is not an exploitation target.

## Scope

- Target: the CAV-CSF Linux VM address supplied by the instructor.
- Permitted: host discovery, TCP scanning, service enumeration, anonymous access testing, use of credentials discovered inside the lab, local enumeration and controlled privilege escalation.
- Prohibited: attacking the Windows host, university infrastructure, `cwscenario.uk` or any system outside the isolated lab.
- Stop after demonstrating the required access and collecting evidence. Do not alter administrator files, persistence settings or unrelated services.

## Learning Outcomes

After completing this exercise, you should be able to:

- identify exposed services and their purpose;
- test an FTP service for anonymous access;
- review exposed organisational material;
- recognise credential exposure and reuse;
- obtain and document a low-privilege Linux shell;
- enumerate delegated sudo privileges;
- demonstrate the security impact of an unsafe sudo rule;
- recommend proportionate remediation.

## Task

Starting with only the target VM address:

1. Identify the relevant exposed TCP services.
2. Investigate whether the file-transfer service permits unauthenticated access.
3. Review accessible material for information that should not be publicly exposed.
4. Determine whether any discovered information enables low-privilege remote access.
5. Record the identity, groups and privilege level of the initial shell.
6. Enumerate commands that the compromised account is permitted to run with elevated privileges.
7. Demonstrate effective UID 0 through the intended delegated command without modifying unrelated system state.
8. Exit any elevated shell and preserve the evidence required for your report.

## Evidence Requirements

Capture evidence showing:

- the target address and scan scope;
- discovered ports and service identification;
- successful anonymous access without including the active password in the submitted report;
- the exposed document and affected username;
- successful low-privilege SSH access;
- output of `whoami`, `id` and relevant sudo enumeration;
- controlled proof of effective UID 0;
- timestamps and a concise command log.

Redact the discovered password from screenshots and reports. Do not include administrative credentials or SSH private keys.

## Report Questions

1. Which control failure made the initial information disclosure possible?
2. Why did credential reuse increase the impact of the disclosure?
3. Why is the affected account considered low privilege before escalation?
4. What property of the delegated command made the sudo rule unsafe?
5. Which preventive and detective controls would break the attack path at each stage?
6. How would you rate the combined risk, and why?

## Completion Condition

The exercise is complete when you have demonstrated the chain from network discovery to a low-privilege shell and then to effective UID 0, recorded suitable evidence, exited the session and answered the report questions.

Notify the instructor if the expected services are unavailable. Do not attempt to repair or reconfigure the target yourself.
