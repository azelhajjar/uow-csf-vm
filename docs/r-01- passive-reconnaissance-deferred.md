# Activity: Passive Reconnaissance — Deferred Pending Domain Configuration

## Summary

Passive reconnaissance (OSINT) is the first phase of a standard penetration testing methodology, gathering information about a target without directly interacting with it. Earlier in this project, this phase was treated as not applicable, since the target VM was addressed purely by internal IP on an isolated lab segment with no domain or public footprint. This is no longer accurate: a real domain, `cwscenario.uk` ("coursework scenario"), has been registered specifically to support this reconnaissance step and to eventually tie together the Linux VM and the planned Windows/AD VM into a single coherent fictional organisation for teaching purposes.

At the time of writing, `cwscenario.uk` has not yet had its subdomains, DNS records, or other supporting configuration built out, so passive reconnaissance against it is deferred until that setup work is complete. This activity is recorded as a placeholder to keep the reconnaissance phase properly represented in sequence, and will be completed once the domain is ready.

## Environment

| Item | Value |
|---|---|
| Domain | cwscenario.uk |
| Purpose | Dedicated teaching domain, purpose-registered to support passive reconnaissance exercises and to connect the Linux VM (192.168.144.131/.130) and the future Windows/AD VM into a single fictional organisation |
| Status | Registered; subdomains and supporting DNS/service configuration not yet built out |

## Background

The disposable and master Linux VMs (192.168.144.131 and 192.168.144.130) are addressed purely by internal IP on an isolated lab segment. On their own, they have no domain, no public DNS presence, and nothing for passive OSINT techniques to act on, which is why passive reconnaissance was originally scoped as not applicable.

`cwscenario.uk` changes this. It is a real, currently-registered domain intended specifically to give students a genuine, safe, legally-controlled target for passive reconnaissance techniques (WHOIS lookups, DNS enumeration, certificate transparency log searching, and eventually mail/employee-harvesting style exercises), and to serve as the organisational identity tying the Linux VM and the planned Windows/AD domain controller VM together into one coherent fictional company scenario, rather than two unrelated standalone machines.

## Planned Configuration

The following is planned but not yet implemented, and is recorded here so the eventual passive reconnaissance activity has clear scope once revisited:

- Subdomains connecting to both the Linux VM and the future Windows/AD VM, likely following a pattern such as a subdomain per VM or per service
- DNS records appropriate for the scenario (A/AAAA records pointing at the relevant VMs where meaningful, MX records if the planned email service is tied to this domain, TXT records if relevant to the exercise design)
- Enough structure that genuine passive techniques (WHOIS, `dig` record enumeration, certificate transparency log searching via `crt.sh` or similar) return real, meaningful findings rather than an empty or trivial registration record

## Outcome

No reconnaissance was performed against `cwscenario.uk` in this activity; this is intentional. The domain exists and is confirmed suitable for this purpose, but is not yet configured with the subdomains and records needed to make the exercise meaningful. This activity will be revisited and rewritten with genuine findings once that configuration work is complete.

## Teaching Notes

This is a good moment to explain to students why a purpose-built teaching domain is valuable: real passive reconnaissance techniques (WHOIS, DNS enumeration, certificate transparency logs) require a real domain to practise against, and using an organisation's actual production domain for teaching would be both unnecessary and potentially inappropriate. A dedicated, deliberately-configured domain under the teaching team's own control avoids that problem entirely while still giving students an authentic experience with real-world tools and real DNS infrastructure, rather than a simulated or fabricated one.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** None
**Starting account:** None
**Resulting access:** N/A (placeholder activity; no findings yet)
**Provides access for:** Will precede genuine passive reconnaissance findings once `cwscenario.uk` is configured with subdomains and DNS records connecting it to the Linux and Windows/AD VMs
**Suggested teaching level:** Level 5 (to be confirmed once genuine content is added; likely Level 5 for basic WHOIS/DNS techniques, possibly extending to Level 6 if certificate transparency or subdomain enumeration techniques are emphasised)
