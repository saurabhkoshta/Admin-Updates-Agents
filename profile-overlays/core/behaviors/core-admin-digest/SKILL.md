---
name: core-admin-digest
description: Creates and delivers a Microsoft admin digest using products, schedule, reporting window, and destinations configured by an administrator in the invoking flow.
---
<!-- bic:source=blank -->
# Core Admin Digest

Create and deliver the core administrator-configured digest without Dataverse or per-user subscription management. This behavior complements the core research capabilities; it does not replace or reduce them.

## Configuration contract

The invoking scheduled flow or agent instruction must provide these values:

- Selected products or services. An empty selection means all products returned by the tenant source.
- Reporting-window start and end timestamps, including the time zone.
- Teams enabled and the configured Team and channel when Teams delivery is enabled.
- Email enabled and the configured recipients when email delivery is enabled.
- An optional digest label used in the heading and subject.

Require at least one enabled delivery method. Never ask an end user to change this fixed configuration during a digest run. Do not read or write Dataverse, and do not call any subscription-management tool.

## Sources and filters

- Tenant source: `MCP-Server-for-Enterprise`.
- Documentation source: `Microsoft Learn Docs MCP Server`.
- Required categories: `planForChange` or `preventOrFixIssue`, compared case-insensitively.
- Required tag: `Admin impact`, compared case-insensitively.
- Teams delivery tool: `Post weekly admin digest card`.
- Email delivery tool: `Send an email (V2)`.

## Procedure

1. Validate the supplied configuration and exact reporting window.
2. Query `MCP-Server-for-Enterprise` for Message Center posts in that window. Request the category, tags, major-change flag, product or service, status, relevant dates, administrator impact, recommended action, and source link.
3. If selected products were supplied, keep only posts whose returned product or service matches a configured value case-insensitively. Do not infer a match from title text when the product or service field is missing.
4. Keep a post only when its category is `planForChange` or `preventOrFixIssue` and at least one tag is `Admin impact`. Missing fields do not match.
5. Deduplicate by Message Center post ID. When records differ, retain the newest tool-returned version and preserve its latest status and dates.
6. Group by category in this order: `planForChange`, then `preventOrFixIssue`. Within each category, show `Major: Yes` before `Major: No`.
7. Sort by the nearest administrator action or rollout date when available, then by publication or last-updated date, newest first.
8. Use `Microsoft Learn Docs MCP Server` only when a qualifying post needs implementation detail or explicitly identifies a known issue, configuration requirement, migration, deprecation, or remediation. Search with exact terms from the tenant result.
9. Keep Message Center facts, Microsoft Learn guidance, and suggested administrator considerations distinct. Do not use Learn content as evidence that a change affects the tenant.
10. Render one canonical digest, then adapt it to each enabled delivery method without changing facts.
11. Send only to the Team, channel, and recipients supplied by the administrator-controlled flow configuration.
12. Report each attempted delivery separately. Never report success unless the corresponding action succeeds.

## Teams format

Use Adaptive Card schema version `1.4`. Include:

- A `Weekly Microsoft 365 Admin Digest` heading, prefixed by the optional digest label when supplied.
- The exact reporting period, time zone, configured product scope, filters, and qualifying count.
- Category and major-change group headings.
- For each item, the Message Center ID, title, product, category, major status, current status, timing, administrator impact, Microsoft-stated action, and source link when available.
- Clearly matching Microsoft Learn guidance and its canonical link when enrichment was required.

Keep the connector payload below 28 KB. Split oversized output into numbered cards without splitting an individual Message Center item.

## Email format

Use the subject `Weekly Microsoft 365 Admin Digest | {end date} | {count} admin-impact post(s)`, prefixed by the optional digest label when supplied. Include the same facts and grouping as the Teams version, with source links.

## No-result behavior

When no posts satisfy the configured product scope and required filters, send a short no-result digest through every enabled method. State the exact reporting period, time zone, product scope, and filters. Do not claim that no Message Center posts existed in the period.

## Failure behavior

- If configuration is missing or invalid, do not query or deliver. Identify the missing administrator-controlled value.
- If the enterprise query fails, do not send a normal or no-result digest.
- If one delivery method fails, report partial delivery and identify the failed method.
- Do not expose credentials, connection details, raw tool payloads, or internal identifiers.