# Microsoft Admin Updates Agent

![Microsoft Admin Updates agent icon](icon.png)

Microsoft Admin Updates is a Copilot Studio reference agent for Microsoft 365 and Azure administrators. It correlates tenant communications, public release information, and Microsoft Learn documentation, then turns the evidence into concise operational guidance.

This is a community reference implementation. It is not an official Microsoft product and is not covered by Microsoft support.

## Capabilities

- Search tenant-specific Message Center posts and Service Health incidents or advisories.
- Search public Microsoft 365 Roadmap items and Azure Updates.
- Enrich findings with official Microsoft Learn documentation.
- Investigate the relationship between a public change, tenant impact, known issues, and administrator actions.
- Manage per-user weekly digest preferences in Dataverse.
- Deliver filtered weekly digests through Microsoft Teams and email.

## Evidence model

```mermaid
flowchart LR
    User[Administrator] --> Agent[Microsoft Admin Updates]
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

## Prerequisites

- A Power Platform environment with Dataverse and Copilot Studio authoring access.
- The Copilot Studio extension for Visual Studio Code.
- Access to the MCP Server for Enterprise, Release Communication Server, and Microsoft Learn Docs MCP Server.
- Microsoft Teams, Microsoft 365 Outlook, and Dataverse connections for digest features.
- A user-owned `Admin Digest Subscriptions` Dataverse table and appropriate least-privilege security roles.

See [SETUP.md](SETUP.md) for environment preparation and connection rebinding.

## Important portability notes

This repository is an exported agent workspace, not a complete Power Platform solution package. Publisher prefixes, schema names, connector IDs, and connection reference names reflect the source environment and must be reviewed when targeting another environment.

The repository does not currently include:

- The Dataverse table definition for `Admin Digest Subscriptions`.
- The scheduled `Daily-MC-Trigger` workflow referenced by the weekly digest behavior.
- Local `.mcs` connection state, authentication tokens, or environment binding files.

Cross-source research can be adapted independently. Subscription management and scheduled digest delivery require the missing Dataverse and workflow assets to be recreated or supplied separately.

## Security

The agent uses integrated authentication, group-based access control, invoker connections, and Dataverse ownership as part of its authorization model. Review [SECURITY.md](SECURITY.md) before deploying or reporting a vulnerability.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

Licensed under the [MIT License](LICENSE).
