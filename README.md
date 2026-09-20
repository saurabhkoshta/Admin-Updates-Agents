# Admin Updates Agent

<img src="icon.png" alt="Admin Updates Agent icon" width="220">

Admin Updates Agent is a Copilot Studio reference agent for Microsoft 365 and Azure administrators. It correlates tenant communications, public release information, and Microsoft Learn documentation, then turns the evidence into concise operational guidance.

This is an independent community reference implementation. It is not developed, endorsed, or supported by Microsoft.

## Capabilities

- Search tenant-specific Message Center posts and Service Health incidents or advisories.
- Search public Microsoft 365 Roadmap items and Azure Updates.
- Enrich findings with official Microsoft Learn documentation.
- Investigate the relationship between a public change, tenant impact, known issues, and administrator actions.
- Manage per-user weekly digest preferences in Dataverse.
- Deliver filtered weekly digests through Microsoft Teams and email.

## Installation

Download the Admin Updates Agent solution ZIP from the applicable GitHub release, then import it through **Power Apps > Solutions > Import solution**. During import, bind the required connections and review all environment-specific settings before publishing the agent.

A source-code checkout is not an importable Power Platform solution package. This repository does not currently publish a release ZIP, so maintainers must add the exported solution as a release asset before directing end users to install it.

See [SETUP.md](SETUP.md) for the import and configuration steps.

## Evidence model

```mermaid
flowchart LR
    User[Administrator] --> Agent[Admin Updates Agent]
    Agent --> Enterprise[MCP Server for Enterprise]
    Agent --> Release[Release Communication Server]
    Agent --> Learn[Microsoft Learn Docs MCP Server]
    Agent --> Dataverse[Dataverse subscriptions]
    Agent --> Teams[Microsoft Teams]
    Agent --> Email[Exchange Online email]

    Enterprise --> Tenant[Tenant communications and service health]
    Release --> Public[Roadmap and Azure updates]
    Learn --> Docs[Official documentation and remediation]
```

Each source has a distinct authority:

| Source | Used for |
| --- | --- |
| MCP Server for Enterprise | Tenant Message Center posts and Service Health records |
| Release Communication Server | Public Microsoft 365 Roadmap items and Azure Updates |
| Microsoft Learn Docs MCP Server | Product behavior, prerequisites, limitations, known issues, and remediation |

The agent preserves source-specific IDs, dates, status, scope, and links. It does not infer tenant impact from public information alone.

## Repository layout

| Path | Contents |
| --- | --- |
| `settings.mcs.yml` | Agent identity, model configuration, authentication mode, and core instructions |
| `behaviors/` | Reusable investigation, subscription management, and weekly digest skills |
| `capabilities/tools/` | Copilot Studio tool bindings |
| `connectors/` | Exported custom connector definitions |
| `infrastructure/connections/` | Exported connection reference mappings |
| `settings/` | Additional Copilot Studio settings |
| `workflows/` | Reserved for workflow definitions; currently empty |
| `scripts/` | Repository publication and validation automation |

## Prerequisites

- A Power Platform environment with Copilot Studio authoring access.
- Access to the MCP Server for Enterprise, Release Communication Server, and Microsoft Learn Docs MCP Server.
- Microsoft Teams or Microsoft 365 Outlook connections for enabled delivery methods.
- Dataverse and a user-owned `Admin Digest Subscriptions` table with appropriate least-privilege security roles.

See [SETUP.md](SETUP.md) for environment preparation and connection rebinding.

## Repository histories

Maintain tenant-bound source in a private repository and publish only a generated, sanitized history. See [HISTORY.md](HISTORY.md) for the migration and ongoing release process.

## Important portability notes

This repository is an exported agent workspace, not a complete Power Platform solution package. Publisher prefixes, schema names, connector IDs, and connection reference names reflect the source environment and must be reviewed when targeting another environment.

The repository does not currently include:

- The Dataverse table definition for `Admin Digest Subscriptions`.
- The scheduled `Daily-MC-Trigger` workflow referenced by the weekly digest behavior.
- Local `.mcs` connection state, authentication tokens, or environment binding files.

The source files are useful for review and contribution, but they are not a substitute for the complete exported solution. The importable release package must include the required Dataverse and workflow assets.

## Security

The agent uses integrated authentication, group-based access control, invoker connections, and Dataverse ownership as part of its authorization model. Review [SECURITY.md](SECURITY.md) before deploying or reporting a vulnerability.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

Licensed under the [MIT License](LICENSE).
