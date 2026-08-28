# SecGen Residual Audit Plan

## Purpose

Audit the CAV-CSF Linux VM and repository for leftover SecGen references or artefacts.

The aim is not to erase legitimate provenance. SecGen should be acknowledged in the GitHub README or project documentation where appropriate, but the running VM should not look or behave like a SecGen-generated machine.

## Scope

Perform a read-only audit first.

Do not edit, delete, rename, or clean up anything until the findings have been reviewed and approved.

## Search Targets

Look for references to:

```text
secgen
SecGen
vagrant
Vagrant
puppet
Puppet
librarian-puppet
scenario.xml
Vagrantfile
base64_inputs
secgen_metadata
puppet:///modules
schreuders
cliffe
hacktivity
Debian 12 experiment
```

## Repository Areas To Check

Search the active CAV-CSF repository for:

- Documentation references.
- README text.
- Setup/provisioning scripts.
- Service configuration files.
- Web landing page files.
- Login banner or MOTD templates.
- Comments in scripts.
- Old generated files.
- Old module names or paths.
- Any wording that implies the VM is still SecGen-generated.

## VM Areas To Check

On the Linux VM, inspect only relevant locations such as:

```text
/etc
/etc/motd
/etc/issue
/etc/update-motd.d
/etc/systemd/system
/opt
/srv
/var/www
/home
/usr/local/bin
```

Also check service files, web roots, banners, scripts, and configuration files that are part of the CAV-CSF lab.

## Classification

For each finding, report:

```text
Path:
Matching text:
Context:
Classification:
Recommendation:
```

Use one of these classifications:

```text
keep
remove
rename/reword
investigate
```

## Decision Rules

Classify as `keep` if:

- The reference is legitimate provenance in GitHub documentation.
- The reference is part of a licence or attribution requirement.
- Removing it would make the project history misleading.

Classify as `remove` if:

- It is a leftover generated artefact.
- It exposes irrelevant SecGen implementation details to students.
- It makes the VM appear to be a SecGen VM when it is not.
- It is unused and clearly obsolete.

Classify as `rename/reword` if:

- The content is useful but the wording overstates the SecGen relationship.
- The text says “built on SecGen” when “informed by earlier SecGen-based Debian 12 experiments” would be more accurate.
- The reference belongs in the README but not in the VM landing page or login banner.

Classify as `investigate` if:

- The file may still be required by a service.
- The reference appears in a script whose current role is unclear.
- Removing it could affect provisioning, service startup, or reset behaviour.

## Expected Output

Produce a concise audit report with:

1. Summary of findings.
2. Exact paths and matching lines.
3. Classification for each finding.
4. Recommended action for each item.
5. Items that need manual confirmation.
6. Confirmation that no changes were made.

## Important Constraints

- Do not run attack tools.
- Do not run lab scenarios.
- Do not run VM provisioning.
- Do not delete files.
- Do not clean up packages.
- Do not edit banners, landing pages, scripts, or documentation during the audit.
- Report first, then wait for approval.