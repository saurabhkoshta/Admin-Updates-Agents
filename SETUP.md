# Setup Guide

This guide is for administrators installing Admin Updates Agent from an exported Power Platform solution. Copilot Studio and connector behavior can vary by environment, licensing, and feature availability.

## 1. Download the solution

Download the solution ZIP attached to the GitHub release you intend to install. Do not download the repository source ZIP from GitHub's **Code** menu. A source archive is not an importable Power Platform solution.

This repository does not currently publish a solution release asset. The repository owner must export and attach the complete solution before this installation path is available to end users.

## 2. Prepare the environment

You need:

- A Power Platform environment.
- Permission to create or update Copilot Studio agents, connections, connection references, and cloud flows.
- Access to each MCP server used by the agent.
- Dataverse permissions to import or bind the subscription table and configure its security roles.

Create a development environment first. Do not test imported connection references or scheduled delivery against production users.

## 3. Import the solution

1. Open [Power Apps](https://make.powerapps.com/) and select the target environment.
2. Open **Solutions**, select **Import solution**, and upload the release ZIP.
3. Review the solution details and proceed through the import wizard.
4. Select or create each required connection when prompted.
5. Supply any environment-variable values included with the release.
6. Wait for the import to complete, then review all warnings before enabling flows or publishing the agent.

Import into a development environment first. Do not enable scheduled delivery against production users until testing is complete.

## 4. Configure connections

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

Teams and Outlook are required only for delivery methods you enable.

## 5. Verify the subscription data model

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

## 6. Verify scheduled orchestration

Confirm that the imported scheduled flow invokes `weekly-admin-digest`. Review its recurrence before enabling it.

The flow should:

1. Run on a schedule appropriate for the supported time zones.
2. Select only active subscriptions due for that run.
3. Invoke digest generation once for each due subscription.
4. Isolate failures so one subscription does not block another.
5. Avoid calling itself from the digest behavior.

Keep connection identifiers and user destinations in Dataverse or environment-bound connections, not in the behavior files.

## 7. Configure and test the agent

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

After testing, publish the agent and enable the scheduled flow. Publishing makes the draft available to everyone with access to that agent, so treat it as a separate, deliberate operation.
