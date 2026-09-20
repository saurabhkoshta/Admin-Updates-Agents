---
name: cross-source-investigation
description: Investigates Microsoft product changes, including upcoming or past-due roadmap items, tenant impact, known issues, and technical questions across Release Communications, Enterprise, and Microsoft Learn while preserving each source's authority.
---
<!-- bic:source=blank -->
# Cross-Source Investigation

Investigate questions that benefit from related evidence across multiple connected MCP servers. Use this workflow when the user asks to assess impact, investigate an issue or change, find related information, prepare a technical briefing, or explain what administrators should do.

Do not use this workflow for a simple lookup that one authoritative source can answer completely.

## Source roles

- `Release Communication Server`: public Microsoft 365 Roadmap items and Azure Updates. Use it for what is changing, public rollout timing, release status, and roadmap identifiers.
- `MCP-Server-for-Enterprise`: tenant-specific Message Center posts and Service Health Dashboard incidents or advisories. Use it for whether and how the current tenant is affected.
- `Microsoft Learn Docs MCP Server`: official product documentation, prerequisites, configuration, limitations, known issues, troubleshooting, workarounds, and remediation.

Never use one source outside its evidence role. In particular, Microsoft Learn does not establish tenant impact, and a tenant communication does not replace official implementation documentation.

## Procedure

1. Determine the question's primary evidence need and query that source first:
   - Public change or rollout: Release Communication Server.
   - Tenant impact, Message Center communication, or service incident: MCP-Server-for-Enterprise.
   - Product behavior, configuration, known issue, or remediation: Microsoft Learn Docs MCP Server.
2. Extract strong search anchors from the user request and primary result. Prefer exact product and feature names, Message Center IDs, roadmap IDs, error codes, versions, dates, configuration terms, and source links.
3. Query a supporting source only when it can add a distinct evidence role that helps answer the question. Do not call every server by default.
   - Exception: when a returned roadmap date is earlier than the current date, always search both MCP-Server-for-Enterprise and Microsoft Learn Docs MCP Server for that feature. The old date makes current status uncertain and requires verification.
4. Use the primary anchors in supporting searches. Do not broaden a search until the exact identifier or terminology has been tried.
5. Correlate records using this confidence scale:
   - `Confirmed`: sources share an exact identifier, canonical link, error code, or unambiguous product and feature identity.
   - `Likely related`: product, feature, timing, and described behavior align, but no shared exact identifier exists.
   - `Possible supporting information`: some relevant terminology aligns, but the relationship is not strong enough to treat as the same event.
6. Never silently merge records. Preserve each source's title, identifier, dates, status, scope, and link. If values conflict, report both values and their sources.
7. Stop enrichment when the user's question is answered, a supporting source returns no clear match, or another query would add repetition rather than a new evidence role.
8. If no supporting match is found, state which source was searched and that no clearly related result was found. Do not claim that supporting information does not exist.

## Past-due roadmap handling

For each relevant roadmap item whose release or rollout date is earlier than the current date:

1. Preserve the roadmap date and status as historical source values. Do not silently replace them.
2. Search MCP-Server-for-Enterprise using the roadmap ID when available, then the exact feature and product name. Look for a matching Message Center post with tenant rollout timing, availability, delay, cancellation, or administrator action.
3. Search Microsoft Learn Docs MCP Server using the exact feature and product name. Look for an explicit availability state such as public preview, private preview, generally available, deprecated, retired, or unavailable, plus current prerequisites or limitations.
4. Assign one current classification supported by the newest applicable evidence:
   - `Upcoming`: a current source provides a future availability or rollout date.
   - `Rolling out`: a matching Message Center post or current documentation explicitly says rollout is in progress.
   - `Preview`: current Microsoft Learn documentation explicitly identifies the feature as preview.
   - `Generally available`: current Microsoft Learn documentation explicitly identifies the feature as generally available.
   - `Delayed or cancelled`: a current roadmap or Message Center result explicitly reports that state.
   - `Status unresolved`: the supporting searches do not establish a current state.
5. Do not classify a past-dated item as `Upcoming` based only on its original roadmap date. Do not infer general availability merely because the roadmap date has passed.
6. If Learn and Message Center describe different states, report both with their dates and scopes. Prefer Message Center for tenant rollout applicability and Learn for documented product availability. Do not collapse them into one unsupported conclusion.

## Response format

Lead with a concise answer, then use only the applicable sections:

### Primary finding

State the main result and identify its source. Preserve its identifier, status, dates, and link when available.

For upcoming-feature requests, separate results into `Upcoming`, `Rolling out or preview`, `Generally available`, and `Status unresolved`. Omit empty groups. Explain that past-dated roadmap items were reclassified using current supporting evidence.

### Supporting evidence

List related results from other MCP servers. Label each relationship `Confirmed`, `Likely related`, or `Possible supporting information`, and explain the evidence for that label briefly.

### Tenant relevance

State only tenant impact supported by MCP-Server-for-Enterprise. If tenant relevance was not checked or no matching tenant record was found, say so explicitly.

### Microsoft documentation

Summarize clearly matching Microsoft Learn documentation. Preserve page titles and canonical links.

### Known issues

Describe only known issues or limitations explicitly documented by Microsoft Learn or returned as a tenant service incident or advisory. Identify the source.

### Guidance

Keep these categories distinct:

- `Microsoft-stated action`: an action from Message Center, a service incident, roadmap communication, or Microsoft Learn.
- `Suggested admin consideration`: a practical recommendation inferred from the combined evidence.
- `Needs validation`: an action or relationship that requires tenant testing or additional evidence.

## Accuracy and safety

- Treat tool results as the source of truth. Do not invent relationships, affected tenants, dates, rollout states, known issues, or remedies.
- Never infer tenant impact from public roadmap or Microsoft Learn content alone.
- Never treat a past roadmap date as proof that a feature shipped, remains upcoming, or is available in the tenant.
- Do not present a documentation publication date as a product rollout date.
- Do not convert a general troubleshooting article into evidence of an active incident.
- Include source links and retrieval context when available.
- If a server is unavailable or access is denied, identify the missing evidence role and answer only from the sources that succeeded.
- Do not expose credentials, connection details, delegated permissions, or raw tool payloads.