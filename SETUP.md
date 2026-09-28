# Setup Guide

This guide is for administrators installing Admin Updates Agent from an exported Power Platform solution. Copilot Studio and connector behavior can vary by environment, licensing, and feature availability.

## 1. Download the solution

Download [AdminUpdatesAgents_1_1_0_0.zip](solution/AdminUpdatesAgents_1_1_0_0.zip) from the `solution/` folder or the [latest release](https://github.com/saurabhkoshta/Admin-Updates-Agents/releases/latest). Do not download the repository source ZIP from GitHub's **Code** menu. A source archive is not an importable Power Platform solution.

The package is an unmanaged solution so administrators can inspect and adapt the reference implementation.

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
5. When the wizard shows the **Allowed Recipient Domains** environment variable, enter your tenant's email domains. See [Set your tenant's allowed email domains](#set-your-tenants-allowed-email-domains) below.
6. If you want the shared all-updates digest, set the **Shared Digest** environment variables. Otherwise leave them as `none`. See [Choose a usage mode](#choose-a-usage-mode).
7. Wait for the import to complete, then review all warnings before enabling flows or publishing the agent.

### Set your tenant's allowed email domains

> [!IMPORTANT]
> The digest flow emails only recipients whose address domain is listed in the `sample_AllowedRecipientDomains` (**Allowed Recipient Domains**) environment variable. The package ships without a value. Set it to **your own tenant's domains** before you turn on the flow.

- Use a semicolon-separated list of your tenant's verified domains, for example `contoso.com;contoso.onmicrosoft.com`. You can find them in the Microsoft 365 admin center under **Settings** > **Domains**, or in the Microsoft Entra admin center under **Custom domain names**.
- Matching is exact and case-insensitive. Subdomains aren't included automatically, so list each subdomain you use (for example `eu.contoso.com`).
- Don't add external or consumer domains. The allowlist is what prevents the digest from being emailed outside your organization.
- Power Automate won't turn on the flow until the variable has a value. If a subscription has no allowed recipients, the flow skips email for it and records the reason in **Last Delivery Status**.
- To change the value later, open **Solutions** > **Admin Updates Agent** > **Environment variables** > **Allowed Recipient Domains** and edit **Current value**.

### Choose a usage mode

Any administrator can chat with the agent in either mode. The mode only decides how digests are delivered.

| Mode | Use when | Configure |
| --- | --- | --- |
| **Personalized** | Each administrator should choose their own products and destinations. | Nothing at import. Administrators create subscriptions by chatting with the agent. An empty product selection means all products. Assign the **Admin Digest Subscriber** role. |
| **Shared (all updates)** | Everyone should get all updates, and no one needs to configure anything. | Set the Shared Digest variables below. The flow sends one all-products digest per run. No subscriptions or Subscriber role needed. |
| **Both** | You want a shared channel plus optional personal digests. | Do both. |

Shared digest environment variables (each defaults to `none`, which disables that channel):

| Variable | Value |
| --- | --- |
| **Shared Digest Teams Team ID** (`sample_SharedDigestTeamId`) | Team (Microsoft 365 group) ID of the shared team. Set together with the channel ID. The flow's digest account must be a member of the team. |
| **Shared Digest Teams Channel ID** (`sample_SharedDigestChannelId`) | Channel ID in that team, for example `19:...@thread.tacv2`. |
| **Shared Digest Email Recipients** (`sample_SharedDigestRecipients`) | Semicolon-separated addresses, for example an administrators distribution list. Only addresses in **Allowed Recipient Domains** receive it. |

The shared digest uses the same filters, card template, and allowlist as personal digests. Its reporting period is shown in Central Standard Time, the flow's schedule time zone. Its result appears in the flow run history (action `Shared_digest_status`), because there's no subscription row to update. To find team and channel IDs, open the channel in Teams, select **Get link to channel**, and read `groupId` and the channel ID (the part after `/channel/`, URL-decoded) from the link.

Import into a development environment first. Do not enable scheduled delivery against production users until testing is complete.

## 4. Configure connections

The package contains no source-tenant connection instances or credentials. Bind or create every connection in the target environment.

Before creating the MCP Server for Enterprise connection, replace these sanitized custom-connector placeholders with values for the target tenant:

| Placeholder | Required value |
| --- | --- |
| `00000000-0000-0000-0000-000000000000` | Target Microsoft Entra tenant ID |
| `/replace-with-target-tenant-federated-identity-subject` | Federated identity subject configured for the target connector |

Alternatively, select the connector's service-principal authentication option and provide the target tenant's application details during connection creation. Never store a client secret in the solution or repository.

Create and test these connections in the target environment:

| Connection | Purpose |
| --- | --- |
| MCP Server for Enterprise | Tenant Message Center and Service Health data |
| Release Communication Server | Microsoft 365 Roadmap and Azure Updates |
| Microsoft Learn Docs MCP Server | Official Microsoft documentation |
| Microsoft Dataverse | Digest subscription storage (agent and flow) |
| Microsoft Copilot Studio | Lets the digest flow invoke the agent to retrieve Message Center posts |
| Microsoft Teams | Adaptive Card delivery to a channel (flow only) |
| Microsoft 365 Outlook | Email delivery (flow only) |

The agent uses invoker authentication for its tools. It has no email or Teams tool, so it can't deliver anything itself. Grant only the permissions required by each connector and test with a non-administrator account where practical.

The `Daily-MC-Trigger` flow runs under its owner's connections. Use a dedicated digest account that:

- owns the flow's Dataverse, Copilot Studio, Teams, and Outlook connections;
- can read Message Center posts through MCP Server for Enterprise (for example, a Message Center Reader role);
- belongs to every team that subscribers choose for Teams delivery;
- has the **Admin Digest Processor** security role.

Digest email is sent from this account's mailbox.

## 5. Assign security roles

The solution includes two least-privilege roles for the `Admin Digest Subscriptions` table. Assign them together with the environment's standard **Basic User** role.

| Role | Assign to | Access |
| --- | --- | --- |
| Admin Digest Subscriber | Every administrator who uses personal subscriptions | Create, read, write, append, and append to **their own** rows (user level). No delete. Not needed for a shared-only deployment. |
| Admin Digest Processor | The digest flow's owner account only | Read and write **all** rows (organization level), to select active subscriptions and record delivery status. |

Don't give subscribers organization-level access to the table. The agent's lookup tool has a fixed owner filter, and the Subscriber role is the enforcement boundary that keeps each administrator to their own rows.

## 6. Verify the subscription data model

Digest features use the imported user-owned Dataverse table named `Admin Digest Subscriptions`. Its sanitized logical name is `sample_admindigestsubscription`.

The table must represent at least these values:

| Value | Logical name | Purpose |
| --- | --- | --- |
| Subscription name | `sample_newcolumn` | Human-readable profile name |
| Selected products | `sample_selectedproducts` | One or more supported product labels, separated by `; `. Empty means all products. |
| Teams enabled | `sample_teamsenabled` | Enables Teams delivery |
| Email enabled | `sample_emailenabled` | Enables email delivery |
| Team and channel | `sample_teamsteamid`, `sample_teamschannelid`, `sample_teamschannelname` | Teams destination values accepted by the connector |
| Email recipients | `sample_emailrecipients` | One or more validated recipients |
| Schedule day and time | `sample_scheduleday`, `sample_scheduletime` | Recorded delivery preference. The flow's recurrence controls when digests are sent. |
| Time zone | `sample_timezone` | Calculates the rolling seven-day reporting window |
| Active | `sample_active` | Enables or disables processing without deleting history |
| Last-delivery fields | `sample_lastdeliveryat`, `sample_lastdeliverystatus` | Records delivery result and timing |
| Owner | `ownerid` | Enforces the per-user subscription boundary. The agent's lookup always filters on `owninguser/azureactivedirectoryobjectid` equal to the signed-in user's Entra object ID. |

Keep the table user-owned. If the target table uses different logical names or choice labels, update the Dataverse tools, the flow, and the behavior instructions together.

## 7. Verify scheduled orchestration

`Daily-MC-Trigger` runs the whole digest pipeline. Review its recurrence before turning it on. As shipped, it runs weekly on Monday at 08:00 Central Standard Time. Every active subscription is processed on each run; the stored schedule day and time are recorded preferences only.

On each run, the flow:

1. Calculates the rolling seven-day window ending at the scheduled run time.
2. Invokes the agent **once**, with a fixed Microsoft Graph request and a structured output schema. The agent only retrieves posts and writes short impact and action summaries.
3. Keeps only posts whose category is Plan for change or Prevent or fix issue **and** that are tagged Admin impact. It removes exact duplicates and sorts by group, action date, then last-modified date. This logic is deterministic in the flow, not decided by the model.
4. For each active subscription, keeps posts whose services match the selected products (case-insensitive; an empty selection means all products), then renders Adaptive Cards from a fixed template. Cards hold at most 10 posts, with text fields truncated, and a compact fallback is posted if a card would exceed 27,000 characters, so every card stays under the Teams 28 KB limit.
5. Emails only recipients in the allowed domains, posts cards only to the stored team and channel, and writes the outcome to **Last Delivery Status**.
6. When any Shared Digest variable is set, sends one all-products digest to the shared team channel and/or email recipients, using the same rendering and allowlist.
7. Isolates failures per subscription. If retrieval fails, it sends nothing, personal or shared, and records the failure on every active subscription.

Keep connection identifiers and user destinations in Dataverse or environment-bound connections, not in the behavior files.
## 8. Configure and test the agent

The checked-in model selection may not be available in every environment. Select a supported model in the target environment and revalidate the agent.

Test at least these scenarios before publishing:

- A simple Message Center lookup.
- A roadmap lookup with a future date.
- A past-dated roadmap item that requires current-state verification.
- A cross-source investigation with conflicting dates or status.
- Subscription creation, review, update, preview, and disable operations.
- Teams-only, email-only, and dual-channel digest delivery (run the flow manually in the development environment).
- A subscription with recipients outside the allowed domains. They must be skipped and counted in Last Delivery Status.
- A subscription with no products selected. It must receive all qualifying posts.
- If you use shared mode, a run with the Shared Digest variables set (check `Shared_digest_status` in the run history) and a chat session from an administrator with no subscription.
- A no-result digest.
- Connector denial, missing permissions, and partial delivery failure.
- Attempts to access another user's Dataverse row. The lookup must return only the signed-in user's rows.

Verify that responses preserve source IDs and links, distinguish public from tenant evidence, and never expose raw connector payloads or internal identifiers.

After testing, publish the agent, confirm **Allowed Recipient Domains** contains only your tenant's domains, and then turn on the scheduled flow. Publishing makes the draft available to everyone with access to that agent, so treat it as a separate, deliberate operation.
