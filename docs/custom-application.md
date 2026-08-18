# Custom Application

## Purpose

The project will include one original vulnerable application owned and maintained as part of CAV-CSF.

The application will support:

1. curriculum-aligned web penetration-testing activities;
2. University-run CTF events;
3. reconnaissance and organisational scenario material;
4. links between web findings, database findings and host/service activity.

The canonical runtime and student-delivery rules are defined in `docs/runtime-and-delivery-model.md`.

## One Application, Multiple Uses

Do not create separate Level 5, Level 6, Level 7 or CTF editions of the custom application.

The same deployed application remains available in the same VM. Teaching guides determine which features and vulnerabilities students are asked to investigate and how much guidance they receive.

## Scenario Role

The custom application should represent a believable fictional organisation. It should provide public pages, user-facing features, API endpoints and data that support reconnaissance before exploitation.

Possible scenario elements include:

- public organisational website;
- staff and department pages;
- support or IT contact references;
- downloadable documents with realistic metadata;
- login area;
- user dashboard;
- file upload area;
- search or reporting feature;
- internal API;
- database-backed records.

Runtime names must be realistic. Do not expose `cav-csf`, attack-path IDs, challenge numbers or module labels in student-visible URLs, directories, database names, service names or application branding unless deliberately part of the fictional scenario.

## Vulnerability Scope

The initial application should contain a curated set of well-tested vulnerabilities selected from areas such as:

- SQL injection;
- command injection;
- reflected XSS;
- stored XSS;
- broken authentication;
- insecure session handling;
- broken access control;
- insecure direct object reference;
- API broken object-level authorisation;
- path traversal;
- insecure file upload;
- sensitive information disclosure;
- server-side request forgery;
- XXE;
- DOM-based vulnerabilities;
- WebSocket vulnerabilities;
- business-logic weaknesses;
- web cache poisoning;
- HTTP Host header attacks;
- HTTP request smuggling;
- OAuth weaknesses;
- JWT weaknesses;
- selected Web/LLM interaction weaknesses where they are practical and teachable.

The exact list requires approval before implementation. Do not attempt to reproduce every PortSwigger, Juice Shop or WebGoat topic.

Some vulnerabilities should be independently usable for guided teaching. Others may contribute to advanced chains involving the host, database or AD environment. Do not force every vulnerability into one linear attack path.

## Database and Service Interaction

The application should have a supporting database or backend service that contributes to both web and network penetration-testing activities.

At least one database service in the overall VM must be network-visible. The custom application database is a candidate where this supports:

- database enumeration;
- service/version identification;
- weak or reused credentials;
- direct database access;
- data extraction;
- linking database findings to application findings;
- credential reuse for host or AD activity.

Do not hide the only useful database entirely behind Docker-internal networking.

## CTF Role

The same custom application can support University-run CTF events.

Flags may appear in:

- web responses;
- API output;
- database records;
- user-only areas;
- application configuration;
- upload or file-handling paths.

CTF event documentation and flag values must remain separate from normal student-facing teaching material.

## Student Delivery and Recovery

Students receive only the completed VM image. They do not receive this repository or application source as part of the normal VM exercise.

Do not create student-facing reset buttons, reset endpoints, activity-reset scripts or per-vulnerability restore controls.

Each student starts from a fresh VM. If a student VM becomes unusable, the normal recovery method is to replace it with a fresh copy.

Developer/instructor scripts may rebuild seed data, restore application state or verify the vulnerable condition during development and acceptance testing. Those are maintenance artefacts only and must not be presented as part of the student workflow.

## Verification Requirements

Application checks should confirm:

- service is reachable;
- landing and login pages respond;
- API responds;
- seed users/data exist where required;
- intended vulnerabilities are present;
- unintended administrative access is absent;
- flags are present where expected for CTF builds/events;
- runtime names do not reveal internal teaching metadata;
- any network-visible backend service is reachable as designed.

## Open Decisions

- DECISION REQUIRED: Final application technology stack.
- DECISION REQUIRED: Final vulnerability list.
- DECISION REQUIRED: Database choice and exposure model.
- DECISION REQUIRED: Which application findings chain into host, service or AD activities.
- DECISION REQUIRED: CTF flag locations and event workflow.
