# Setup Guide

This guide describes the environment work required to adapt the reference agent. Copilot Studio and connector behavior can vary by environment, licensing, and feature availability, so review every generated identifier before pushing changes.

## 1. Choose a profile

Read [PROFILES.md](PROFILES.md), then generate a deployment workspace:

```powershell
.\scripts\Build-AgentProfile.ps1 -Profile core
.\scripts\Build-AgentProfile.ps1 -Profile personalized
```

Use `core` to build the research and shared-digest experience with one administrator-controlled configuration and no Dataverse. Use `personalized` for per-user products, schedules, time zones, and destinations stored in Dataverse.

## 2. Prepare the environment

You need:

- A Power Platform environment.
- Permission to create or update Copilot Studio agents, connections, connection references, and cloud flows.
- The Copilot Studio extension for Visual Studio Code.
- Access to each MCP server used by the agent.

The personalized profile additionally requires Dataverse permissions to create or bind the subscription table and configure its security roles.

Create a development environment first. Do not test imported connection references or scheduled delivery against production users.

## 3. Bind a local agent workspace

Use the Copilot Studio extension to create or clone the target agent into a local workspace. This creates the local `.mcs/` connection metadata used for validation, pull, and push operations.

Keep `.mcs/` local. It can contain environment details and connector synchronization data and is excluded by this repository's `.gitignore`.

Before each push:

1. Pull the latest target agent state.
2. Review the local changes against the target environment.
3. Validate all `.mcs.yml` files with the Copilot Studio extension.
4. Push to a development agent.
5. Test before publishing.

Publishing makes the draft available to everyone with access to that agent. Treat publishing as a separate, deliberate operation.

## 4. Review generated identities

The checked-in files contain source-environment values such as:

- The `sample` publisher prefix.
- The agent schema name in `settings.mcs.yml`.
- Connection reference logical names in `capabilities/tools/`.
- Connector IDs and mappings in `connectors/` and `infrastructure/connections/`.

Allow the target environment or import process to generate and bind its own values where supported. Otherwise, update references consistently across the workspace. Do not edit a single generated identifier in isolation.

The connector definitions also contain tenant and federated identity identifiers from the source environment. These values are identifiers rather than credentials, but they are not portable. Regenerate the OAuth and federated identity configuration for the target tenant instead of relying on the checked-in source values.

## 5. Configure connections

Create and test these connections in the target environment:

| Connection | Purpose |
| --- | --- |
| MCP Server for Enterprise | Tenant Message Center and Service Health data |
| Release Communication Server | Microsoft 365 Roadmap and Azure Updates |
| Microsoft Learn Docs MCP Server | Official Microsoft documentation |
| Microsoft Dataverse | Digest subscription storage |
| Microsoft Teams | Adaptive Card delivery to a channel |
| Microsoft 365 Outlook | Email delivery |

The agent uses invoker authentication for its tools. Grant only the permissions required by each connector and test with a non-administrator account where practical.

The core profile does not require Dataverse. Teams and Outlook are required only for the delivery methods enabled in its fixed configuration.

## 6. Configure core delivery

Skip this section for the personalized profile.

Create a scheduled cloud flow that invokes `core-admin-digest` with administrator-controlled values for:

- Product scope, with an empty selection meaning all returned products.
- Reporting-window start and end timestamps and time zone.
- Teams enabled, Team, and channel.
- Email enabled and recipients.
- Optional digest label.

Store destinations in secured flow configuration or environment variables. Do not place them in agent instructions or commit them to Git. Create the core scheduler as a separate flow. Do not repoint the source `Daily-MC-Trigger`, because that flow invokes the personalized `weekly-admin-digest` behavior.

## 7. Create the personalized subscription data model

Skip this section for the core profile.

Digest features expect a user-owned Dataverse table named `Admin Digest Subscriptions`. The current behaviors refer to the source logical name `sample_admindigestsubscription`.

The table must represent at least these values:

| Value | Purpose |
| --- | --- |
| Subscription name | Human-readable profile name |
| Selected products | One or more supported Microsoft product choices |
| Teams enabled | Enables Teams delivery |
| Email enabled | Enables email delivery |
| Team and channel | Teams destination values accepted by the connector |
| Email recipients | One or more validated recipients |
| Schedule day and time | Weekly delivery schedule |
| Time zone | Calculates the rolling seven-day reporting window |
| Active | Enables or disables processing without deleting history |
| Last-delivery fields | Records delivery result and timing |
| Owner | Enforces the per-user subscription boundary |

Use a user-or-team-owned table. Configure least-privilege Dataverse roles so users can access only the rows appropriate to them. If the target table uses different logical names or choice labels, update the Dataverse actions and behavior instructions together.

## 8. Add personalized scheduled orchestration

The local agent workspace does not include solution flow exports. The source solution's `Daily-MC-Trigger` already invokes `weekly-admin-digest` on Monday at 8:00 AM Central Time. Preserve or recreate that flow when deploying the personalized profile.

The flow should:

1. Run on a schedule appropriate for the supported time zones.
2. Select only active subscriptions due for that run.
3. Invoke digest generation once for each due subscription.
4. Isolate failures so one subscription does not block another.
5. Avoid calling itself from the digest behavior.

Keep connection identifiers and user destinations in Dataverse or environment-bound connections, not in the behavior files.

## 9. Configure and test the agent

The checked-in model selection may not be available in every environment. Select a supported model in the target environment and revalidate the agent.

Test at least these scenarios before publishing:

- A simple Message Center lookup.
- A roadmap lookup with a future date.
- A past-dated roadmap item that requires current-state verification.
- A cross-source investigation with conflicting dates or status.
- Subscription creation, review, update, test, and disable operations.
- Teams-only, email-only, and dual-channel digest delivery.
- A no-result digest.
- Connector denial, missing permissions, and partial delivery failure.
- Attempts to access another user's Dataverse row.

Verify that responses preserve source IDs and links, distinguish public from tenant evidence, and never expose raw connector payloads or internal identifiers.
