# Agent Profiles

The repository supports two generated deployment profiles. The root workspace is the private source and should not be copied selectively by hand.

The root Copilot Studio agent remains the working personalized source. Building a profile does not modify or publish that agent. Core-only behavior is stored under `profile-overlays/core/` and appears only in the generated core workspace.

Build either profile with:

```powershell
.\scripts\Build-AgentProfile.ps1 -Profile core
.\scripts\Build-AgentProfile.ps1 -Profile personalized
```

Generated workspaces are written under `dist/` and are ignored by Git. The legacy `simple` argument remains an alias for `core`.

## Core profile

Use this profile when one administrator controls a shared digest configuration and users do not need personal subscriptions. Core includes both research and digest delivery.

Included capabilities:

- Interactive Message Center and Service Health research.
- Public Microsoft 365 Roadmap and Azure Updates research.
- Microsoft Learn documentation enrichment.
- Cross-source investigation.
- Scheduled Teams and email digest delivery using fixed flow inputs.

Required connections:

- MCP Server for Enterprise.
- Release Communication Server.
- Microsoft Learn Docs MCP Server.
- Microsoft Teams when Teams delivery is enabled.
- Microsoft 365 Outlook when email delivery is enabled.

The core profile excludes all Dataverse tools, the personalized subscription behavior, and the personalized weekly digest behavior. Its scheduler must provide the product scope, reporting window, time zone, enabled delivery methods, destinations, and optional digest label described in the generated `behaviors/core-admin-digest/SKILL.md`.

An empty product selection means all products returned by the tenant source, still limited to `Plan for change` or `Prevent or fix issue` posts tagged `Admin impact`.

## Personalized profile

Use this profile when each administrator should control products, destinations, schedule, and delivery preferences.

It includes everything in the research experience plus:

- User-owned Dataverse subscription rows.
- Interactive create, review, update, test, disable, and re-enable operations.
- Per-user product selection and time zone.
- Teams, email, or dual-channel delivery.
- Independent processing and delivery status for each subscription.

This profile requires Dataverse, the `Admin Digest Subscriptions` table, appropriate owner-scoped security roles, Teams and Outlook connections, and scheduled orchestration.

The current `Daily-MC-Trigger` in the source solution is already personalized. It runs weekly on Monday at 8:00 AM Central Time and invokes `weekly-admin-digest`, which loads due Dataverse subscriptions.

The solution also contains an older `Daily High Relevance Message Center Impact` flow. It targets a different agent and an older Admin Preferences protocol, so it is not a drop-in core flow for this agent.

## Source ownership

Shared research behavior belongs in `behaviors/cross-source-investigation/`. The fixed shared-digest overlay belongs in `profile-overlays/core/`. Per-user behavior belongs in `behaviors/manage-admin-digest-subscription/` and `behaviors/weekly-admin-digest/`.

Edit source files at the repository root, update the relevant profile manifest under `profiles/`, and rebuild. Never edit generated files under `dist/`.
