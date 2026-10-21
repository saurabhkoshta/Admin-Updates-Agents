# Setup Guide

This package installs the **chat-only Admin Updates Agent**. Its only functional integrations are the three MCP evidence sources. It does not include personal subscriptions or automated digest delivery.

## 1. Prepare an environment

Use a development Power Platform environment with:

- Copilot Studio access and the required licensing.
- Permission to import the solution and configure custom connectors and connections.
- Access to the MCP Server for Enterprise, Release Communication Server, and Microsoft Learn Docs MCP Server.
- Appropriate Microsoft 365 permissions for tenant Message Center and Service Health data.

The platform's normal environment and Dataverse prerequisites still apply. You do **not** need a custom subscription table, digest security roles, a delivery service account, an Outlook connection, or a Teams delivery connection.

## 2. Download and import

Download [AdminUpdatesAgents_1_2_0_0.zip](https://github.com/saurabhkoshta/Admin-Updates-Agents/releases/latest/download/AdminUpdatesAgents_1_2_0_0.zip) from the [latest release](https://github.com/saurabhkoshta/Admin-Updates-Agents/releases/latest), not GitHub's source ZIP.

Check the archive against [SHA256SUMS.txt](https://github.com/saurabhkoshta/Admin-Updates-Agents/releases/latest/download/SHA256SUMS.txt):

```powershell
Get-FileHash .\AdminUpdatesAgents_1_2_0_0.zip -Algorithm SHA256
```

The filename and solution version are `1.2.0.0`. Earlier releases (v1.0.0 and v1.1.0) are archived and contain the older digest-enabled package. Do not use them.

In [Power Apps](https://make.powerapps.com/):

1. Select the target development environment.
2. Open **Solutions > Import solution** and upload the ZIP.
3. Review the solution details and connection references.
4. Complete the import and inspect any warnings.

There are no digest environment variables to fill in and no scheduled flow to enable.

## 3. Configure the three evidence sources

| Connection | Purpose | Authorization to review |
| --- | --- | --- |
| MCP Server for Enterprise | Tenant Message Center and Service Health | Dedicated service account's access to the configured tenant and the server's actual permissions |
| Release Communication Server | Public Microsoft 365 Roadmap and Azure Updates | Access required by the server |
| Microsoft Learn Docs MCP Server | Official documentation and guidance | Access required by the connector |

Before creating the Enterprise connection, configure its custom connector with the target tenant's values:

| Placeholder | Replace with |
| --- | --- |
| `00000000-0000-0000-0000-000000000000` | Target Microsoft Entra tenant ID |
| `/replace-with-target-tenant-federated-identity-subject` | Federated identity subject configured for the target connector |

Configure the connector's application (client) ID, tenant ID, redirect URI, and federated identity credential for the target environment. The connector's application credential authenticates the OAuth client; it does not make Enterprise MCP access app-only. The current Enterprise MCP integration uses delegated user sign-in. Do not assume that a service-principal client-credential setting removes the need for a user connection.

### Centrally managed shared connections

All three tools use **Agent author authentication** (`Maker`). A maintainer creates and binds each connection once in Copilot Studio. End users need only access to the published agent, not Copilot Studio editing permissions or individual tool connections.

For Enterprise MCP:

1. Create a dedicated user account such as `svc-adminupdates@<your-tenant-domain>`. Use a verified domain belonging to **your target tenant**, not an account or domain from a demonstration environment.
2. Have a tenant administrator grant **Message Center Reader** and **Service Support Administrator**. The latter also grants support-ticket management permissions, so review that wider account privilege even though this agent's tools are read-only.
3. Confirm the connector app has admin consent for delegated `MCP.ServiceMessage.Read.All` and `MCP.ServiceHealth.Read.All` on Microsoft MCP Server for Enterprise. These are MCP scopes, not Microsoft Graph application permissions.
4. Create the Enterprise connection by signing in as the dedicated account through Microsoft's OAuth window. Complete any required password change, MFA registration, and Conditional Access checks. Do not disable tenant security policies to establish the connection.
5. In the Enterprise tool editor, select **Agent author authentication**, choose the dedicated account's connection, and save. Verify the connection account, not just the maker who owns the agent.

Create and bind the Release and Learn connections centrally as well. Use the authentication required by their servers. Public Release data does not require the Enterprise service account's tenant permissions.

The service account is for reading research sources, not delivering digests. Store its credentials only in an approved vault and assign maintainers who can renew or replace its connection. No user password, token, or live connection is included in this repository or import package.

Shared authentication means every authorized agent user can retrieve whatever the shared Enterprise connection can read. Individual users' Microsoft 365 roles do not limit those shared tool calls. Keep Microsoft sign-in required and restrict the agent to an explicitly approved administrator security group. A group is the list of people allowed to chat with the agent, not a grant of agent-editing access. Keep owner-only access until that group is configured.

Review actual server permissions and available MCP operations. Research-only instructions are not a substitute for a least-privilege permission boundary.

## 4. Select a model and test in chat

The checked-in model may not be available in your environment. Select a supported model in Copilot Studio and validate the agent before publishing.

Test:

- A tenant Message Center lookup and a Service Health question.
- A public roadmap or Azure update lookup.
- A product-specific briefing for an explicit date range.
- An all-products briefing without creating or saving preferences.
- A past-dated roadmap item that needs current-state verification.
- A cross-source investigation with conflicting dates or statuses.
- A question about prerequisites or documented remediation.
- No matching results, an unavailable server, and denied tenant access.
- A permitted non-maker administrator can use all three tools through the published channel without creating individual connections. A user outside the approved group cannot use the agent.
- A request to subscribe, schedule a digest, send email, or post a Teams card. The agent must explain that it only responds in chat.

Check that responses preserve source IDs and links, distinguish public from tenant evidence, state the interpreted reporting period, and explain incomplete coverage rather than claiming exhaustive results.

Product scope is conversational, not a persistent preference. A new conversation does not carry a saved subscription.

### Evaluate natural-language routing

The [routing test set](evals/routing-test-set.csv) contains 25 standalone admin prompts that never name an MCP server or tool. The [routing expectations](evals/routing-expectations.csv) map each question to required, conditional and forbidden evidence sources, plus checks on the actual operations and query intent.

| Cases | Primary evidence needed |
| --- | --- |
| R01 to R05 | Enterprise: tenant Message Center or Service Health |
| R06 to R09 | Release: public Microsoft 365 roadmap or Azure Updates |
| R10 to R13 | Learn: official documentation |
| R14 to R16 | Enterprise and Release: ambiguous product updates or tenant rollout |
| R17 to R18 | Enterprise and Learn: tenant evidence with documented guidance |
| R19 to R22 | All three sources: full briefing, investigation or current-state verification |
| R23 to R25 | No evidence-source calls: missing context, unsupported delivery or greeting |

To import and run:

1. Open the development agent's **Evaluate** tab.
2. Select **New evaluation > Single response**, then upload **only** [routing-test-set.csv](evals/routing-test-set.csv). It has the supported `question` and `expectedResponse` columns. Do not import the expectations matrix as an evaluation test set.
3. Keep **General quality** for response relevance, grounding and safe abstention. Add **Capability use** checks using the paired expectations. The CSV import cannot configure graders or expected capabilities.
4. Match cases by their question text if the UI changes their order. Each question runs in a fresh conversation; R23 deliberately has no prior feature context.
5. Select the available tool capabilities for each required source. If the UI exposes only the parent MCP server, also inspect the run trace for the operation and query target. A server badge or a plausible answer alone does not prove correct routing.
6. Click **Evaluate** to run, or **Save** for later. Inspect both the response and tool trace. Do not publish fixes until failures have been investigated and retested.

Source keys in the matrix:

- `Enterprise`: MCP-Server-for-Enterprise. Require query discovery followed by `microsoft_graph_get` against the correct Message Center or Service Health resource, not merely a discovery call.
- `Release`: Release Communication Server, displayed as Release Communication MCP in the repaired development agent. Verify Microsoft 365 roadmap operations versus Azure update operations according to the request.
- `Learn`: Microsoft Learn Docs MCP Server. Verify a relevant documentation search and, when needed, a fetch of a discovered page.
- `None`: no calls to these evidence sources. An internal investigation skill is not an evidence-source call.

`PastDatedRoadmap` is conditional on the **actual relevant roadmap result** having a release or rollout date before the evaluation date. When true, require the matrix's conditional sources as well as its required sources. When false, avoid those extra calls for these focused questions. A prompt mentioning last month is not itself proof of a past-dated roadmap result. If the UI cannot express conditional or forbidden capabilities, inspect those conditions manually in the trace.

Live data changes, so the rubrics do not hardcode record counts, release dates, current incidents or expected feature status. MC000000000 is a synthetic exact-ID lookup target, not an assumed real post. Empty results are acceptable when reported honestly after the correct query. Authentication or service failures must be explicit; record them separately from a wrong-route failure, and do not mark end-to-end data access as passing just because the correct tool was attempted.

Treat a routing case as passing only when all required sources were used, conditional rules were followed, forbidden sources were not used, the query targeted the right resource and the response met its rubric. Review fresh conversations for every case. Greeting, clarification and refusal cases should not initiate unsolicited research.

Validate the files locally before import:

```powershell
.\evals\Test-RoutingEvalSet.ps1
```

This checks import shape, question limits, row parity, source sets and coverage, not the agent's runtime behavior. These test files do not change or train the agent, are not included in the solution ZIP and do not require a package rebuild. Keep tenant-specific evaluation results and raw tool payloads out of this public repository.

## 5. Publish and share

After testing, publish deliberately and share **use access**, not editing access, with the approved administrator security group. Do not enable organization-wide access merely because the connection is shared.

Configure supported chat channels separately if needed. A Teams chat channel does not require this agent to have a Teams connector for scheduled posting.

Recheck group enforcement in the intended channel, monitor shared-connection failures, and retest after account, credential, consent, role, or Conditional Access changes. Do not label tenant access verified solely because tool discovery succeeds; Message Center and Service Health calls must actually return successfully.

## Existing digest-enabled installations

The chat-only ZIP is a simpler installation, **not an automatic cleanup of older unmanaged components**. Reimporting an unmanaged solution does not reliably delete tables, flows, roles, environment variables, or connection references that are absent from a newer package.

For the cleanest trial, use a new development environment. If simplifying an existing deployment:

1. Turn off the old `Daily-MC-Trigger` flow before making changes.
2. Back up any subscription data you need to retain.
3. Have an administrator review solution layers and dependencies before removing the old subscription table, digest flows, digest security roles, and digest environment variables.
4. Remove obsolete agent subscription and delivery tools, and verify the remaining agent has only the three MCP tools.
5. Remove unused connections only after checking that no other solution uses them.

Do not uninstall the previous unmanaged solution or delete its data blindly. Nothing in this repository change deletes data or changes a deployed environment automatically.
