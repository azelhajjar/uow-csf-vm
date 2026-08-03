# AP-02 Student Lab: Vulnerable File-Transfer Service

## Scenario

You are conducting an authorised penetration test of a Brightleaf Retail Ltd Linux server in the isolated university lab. Brightleaf has asked you to determine whether any network service is running a version with a known, publicly documented vulnerability, and if so, what an attacker could actually achieve with it.

The public `cwscenario.uk` website is contextual material only. It is not an exploitation target.

## Scope

- Target: the CAV-CSF Linux VM address supplied by the instructor.
- Permitted: host discovery, TCP scanning, service and version fingerprinting, public vulnerability research for any version you identify, hands-on testing of a discovered issue against the authorised lab target only, evidence collection.
- Prohibited: attacking the Windows host, university infrastructure, `cwscenario.uk`, or any system outside the isolated lab. Do not upload content beyond what is needed to prove impact, and do not disrupt other running services.
- Stop once you have proven impact and collected evidence. Do not leave uploaded files in place longer than necessary to capture evidence.

## Learning Outcomes

After completing this exercise, you should be able to:

- fingerprint a network service and identify its exact software version;
- research known, published vulnerabilities for a specific service version;
- distinguish between a configuration weakness and a genuine software vulnerability;
- use an FTP client's raw-command feature to send a server command your client doesn't have a built-in shortcut for;
- demonstrate real-world impact by retrieving content over a second, unrelated protocol (HTTP);
- explain why the way you authenticate to a service can change what an attacker is able to do with it;
- recommend proportionate remediation for a version-bound vulnerability.

## Command Reference

You will likely need each of these at least once. They are explained here the first time they matter, not in the order you must use them — decide your own order based on what you find.

**Service version scanning:**
```
nmap -sV -p<ports> <target>
```
`-sV` tells nmap to probe open ports and try to identify the exact software and version running behind each one, not just whether the port is open. This is what lets you move from "a port is open" to "which CVEs might apply."

**Basic FTP session:**
```
ftp <target> <port>
```
Connects to an FTP server on a given port (if you omit `<port>`, it defaults to 21). You'll be prompted for a username and password. Many FTP servers accept a special `anonymous` username for public access — worth testing on any FTP service, on any port. Once connected, `ls` lists files, `get <file>` downloads one, and `quit` closes the session.

**Sending a raw FTP command:**
```
quote <RAW-COMMAND> <arguments>
```
Standard FTP clients only have built-in shortcuts for common operations (`get`, `put`, `ls`, ...). `quote` sends whatever text follows it directly to the server as a raw protocol command, unmodified. This is how you interact with server-specific or module-specific commands that aren't in the client's normal vocabulary — the kind of thing a CVE writeup will tell you to send once you've identified the vulnerable version. FTP server banners usually announce the exact software version when you connect; use that together with your own vulnerability research to figure out which raw commands might be relevant here.

**Fetching a URL with a specific virtual host:**
```
curl -s -H "Host: <hostname>" http://<target>/<path>
```
Some web servers host more than one site on the same IP address and use the `Host` HTTP header to decide which one to serve (name-based virtual hosting). If a plain request to an IP returns the wrong site, a 404, or a default page, try discovering the expected hostname (e.g. from earlier reconnaissance, TLS certificates, or DNS) and supply it explicitly with `-H "Host: ..."`.

## Task

Starting with only the target VM address:

1. Identify the relevant exposed TCP services and their exact versions.
2. Research whether any identified version has a publicly known vulnerability, and what that vulnerability allows an attacker to do.
3. Determine what authentication the vulnerable service accepts, and test it.
4. Identify what filesystem location the service can read from and write to under each authentication mode you can access, and why that might differ between modes.
5. Using the vulnerability you researched, demonstrate that you can place a file somewhere it should not be reachable from network access alone.
6. Confirm the impact by retrieving the file through a different, unrelated service (not the one you exploited).
7. Remove anything you uploaded once you have captured your evidence.
8. Preserve the evidence required for your report.

## Evidence Requirements

Capture evidence showing:

- the target address and scan scope;
- discovered ports, services and exact version numbers;
- the specific vulnerability identified (name or CVE reference) and its documented mechanism;
- the authentication mode used and why it was necessary for the vulnerability to have impact;
- the raw command(s) sent and the server's response;
- confirmation of impact via the second protocol;
- timestamps and a concise command log.

## Report Questions

1. What software and version was affected, and how did you confirm it precisely?
2. What made this a genuine software vulnerability rather than a misconfiguration?
3. Why did the authentication mode you used matter to the outcome — would a different login have worked the same way?
4. What real-world impact would an attacker achieve by extending this technique (beyond what you were asked to demonstrate)?
5. Which preventive and detective controls would break this attack path?
6. How would you rate the risk, and how does it compare to a configuration-based weakness affecting the same service category?

## Completion Condition

The exercise is complete when you have identified the vulnerable service and version, researched and correctly identified the vulnerability, demonstrated file placement using the correct authentication mode, confirmed impact via a second protocol, removed your uploaded evidence from the target, and answered the report questions.

Notify the instructor if the expected services are unavailable. Do not attempt to repair or reconfigure the target yourself.
