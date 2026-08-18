# Custom Application

## Purpose

The project will include one original vulnerable application owned and maintained as part of CAV-CSF.

The application will support:

1. curriculum-aligned web penetration-testing activities;
2. University-run CTF events;
3. reconnaissance and organisational scenario material;
4. links between web findings, database findings and host/service activity.

## Scenario Role

The custom application should represent a believable fictional organisation. It should provide public pages, user-facing application features, API endpoints and data that help students practise reconnaissance before exploitation.

Possible scenario elements:

- public organisational website;
- staff and department pages;
- support or IT contact references;
- downloadable documents with non-solution-bearing metadata;
- login area;
- user dashboard;
- file upload area;
- search or reporting feature;
- internal API;
- database-backed records.

## Vulnerability Scope

The initial application should aim for approximately 10 to 12 well-tested vulnerabilities selected from:

- SQL injection;
- command injection;
- reflected XSS;
- stored XSS;
- broken authentication;
- insecure session handling;
- broken access control;
- File upload vulnreabilities
- Web sockets
- Information disclosure 
- XXE Injectoin
- DOM BASEd vulnreabilities
- insecure direct object reference;
- API broken object-level authorisation;
- path traversal;
- insecure file upload;
- sensitive information disclosure;
- server-side request forgery;
- business-logic weakness.
- Web LLM attacks
- Web cache poisoning
- HTTP Host header attacks
- HTTP request smuggling
- OAuth authentication
- JWT attacks


The exact list requires approval before implementation.

## Database and Service Interaction

The application should have a supporting database or backend service that contributes to both web and network penetration-testing activities.

The README requires at least one network-visible database service. The custom application database is a candidate for this role if the design supports:

- database enumeration;
- weak or reused credentials;
- direct database access;
- data extraction;
- linking database findings to application findings;
- possible credential reuse for host or AD activity.

## CTF Role

The application may place flags in:

- web responses;
- API output;
- database records;
- user-only areas;
- application configuration;
- upload or file-handling paths.

Flags should be generated and verified through the project flag system rather than hardcoded permanently into source code for event use.

## Reset Requirements

The application needs reset support for:

- database state;
- uploaded files;
- user accounts;
- sessions/tokens;
- flags;
- intentionally vulnerable configuration.

Reset must restore intended vulnerable state, not harden the application.

## Verification Requirements

Application checks should confirm:

- service is reachable;
- landing and login pages respond;
- API responds;
- seed users exist;
- intended vulnerabilities are present;
- unintended administrative access is absent;
- flags are present where expected;
- reset restores expected state.

## Open Decisions

- DECISION REQUIRED: Fictional organisation name and application theme.
- DECISION REQUIRED: Technology stack for the custom application.
- DECISION REQUIRED: Final vulnerability list.
- DECISION REQUIRED: Database choice and whether it is the externally visible database service.
- DECISION REQUIRED: Which application findings chain into host, service or AD activities.
- DECISION REQUIRED: Which flags belong in the application for labs versus CTF events.
