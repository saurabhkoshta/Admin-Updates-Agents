---
name: weekly-admin-digest
description: Creates and delivers the weekly Microsoft 365 administrator digest from Plan for change or Prevent or fix issue posts tagged Admin impact.
---
<!-- bic:source=blank -->
# Weekly Admin Digest

Create and automatically deliver a concise weekly digest of tenant-specific Microsoft 365 Message Center posts for administrators.

## Subscription configuration

- Load active subscription rows from the `Admin Digest Subscriptions` Dataverse table in the current Power Platform environment.
- Each subscription supplies its selected products, enabled delivery methods, Teams destination, email recipients, schedule, and time zone.
- Reporting window: the rolling seven days immediately before that subscription's scheduled run time.
- Tenant source: `MCP-Server-for-Enterprise`.
- Required filters: category equals `planForChange` or `preventOrFixIssue` AND tag equals `Admin impact`, with text comparisons case-insensitive.
- Teams delivery tool: `Post weekly admin digest card`.
- Email delivery tool: `Send an email (V2)`.
- Delivery mode: automatic, without approval.

Never embed tenant, environment, connection, owner, Team, channel, recipient, schedule, or time-zone identifiers in this behavior. Resolve them from the imported solution and the current subscription row.

## Procedure

1. Load the active subscription rows due for the current scheduled run. Process each row independently. A failure for one subscription must not change another subscription's content or delivery status.
2. Determine the run timestamp in the subscription's configured time zone and calculate the exact rolling seven-day start and end timestamps. Include both timestamps and the time-zone name in the digest.
3. Query `MCP-Server-for-Enterprise` for Message Center posts in that window. Request `category`, `tags`, `isMajorChange`, and product or service explicitly for every returned post.
4. Keep only posts whose returned product or service matches one of the subscription's selected product choices. Compare against the stored choice labels case-insensitively. Do not infer a product match from title text when the product or service field is missing.
5. Keep a post only when both conditions are explicitly satisfied:
   - Category is `planForChange` or `preventOrFixIssue`, compared case-insensitively.
   - At least one message tag is `Admin impact`, compared case-insensitively.
6. Do not treat a missing category or tag as a match. Do not substitute similar values such as severity, relevance, recommended, important, user impact, or admin action required.
7. Deduplicate results by Message Center post ID. When duplicate records differ, retain the newest tool-returned version and preserve its latest status and dates.
8. Group included posts by category in this order: `planForChange`, then `preventOrFixIssue`. Within each category, group posts by `isMajorChange`, showing `Major: Yes` before `Major: No`. Treat only boolean `true` as `Major: Yes`; false or missing values are `Major: No`.
9. Within each major-change group, sort posts by the nearest administrator action or rollout date when available, then by publication or last-updated date, newest first.
10. For each post, preserve the Message Center ID, title, affected product or service, category, major-change status, status, published or updated date, rollout or action date, administrator impact, recommended action, and source link when returned by the tool.
11. Summarize only facts supported by the tool result. Label any practical recommendation not stated by Microsoft as `Suggested admin consideration`.
12. Render one canonical digest, then adapt it into the enabled Teams Adaptive Card and email formats below without changing facts.
13. When Teams delivery is enabled, call `Post weekly admin digest card`. Post as `Flow bot`, post in `Channel`, and use the Team and channel stored on the current subscription row. Pass valid Adaptive Card JSON as the card body, not Markdown and not an `AdaptiveCardPrompt`.
14. When email delivery is enabled, call `Send an email (V2)` with the recipients stored on the current subscription row, the generated subject, and the email version.
15. Skip disabled delivery methods. Require at least one enabled method before processing a subscription.
16. Confirm each attempted delivery separately and update that subscription's last-delivery fields. Never report successful delivery unless its action succeeds.
17. Do not call `Daily-MC-Trigger` while executing this skill. The workflow initiates digest generation and must not be invoked recursively as a delivery step.

## Teams Adaptive Card format

Use Adaptive Card schema version `1.4` with this structure:

- Root fields: `$schema` set to `http://adaptivecards.io/schemas/adaptive-card.json`, `type` set to `AdaptiveCard`, `version` set to `1.4`, and `msteams.width` set to `Full`.
- Header: a `Container` with style `emphasis` containing a large, bold `TextBlock` titled `Weekly Microsoft 365 Admin Digest`.
- Summary: wrapped `TextBlock` elements for the exact reporting period, the filter `Plan for change or Prevent or fix issue AND Admin impact`, and the qualifying post count.
- Category heading: a medium, bold, accent-colored `TextBlock`. Use `Plan for change` first and `Prevent or fix issue` second.
- Major heading: a bold `TextBlock`. Use `Major: Yes` before `Major: No`.
- Item: a `Container` with `separator: true` and `spacing: Medium` containing:
  - A wrapped, bold `TextBlock` with `{Message Center ID}: {title}`.
  - A `FactSet` for Product, Category, Major, Status, and Timing.
  - A wrapped `TextBlock` beginning `Admin impact:` followed by the concise impact.
  - A wrapped `TextBlock` beginning `Action:` followed by the Microsoft-stated action or `No explicit admin action provided`.
  - A wrapped `TextBlock` containing `[Open Message Center source]({source link})` when a source link is available.

Omit empty category and major-change groups. Do not create empty headings. Keep all `TextBlock` elements wrapped. Do not use tables, input controls, submit actions, images, or decorative content.

The complete connector payload must remain below 28 KB. If necessary, split the digest into numbered cards. Add `Part {n} of {total}` to each card header. Never split an individual Message Center item, and repeat its category and major-change headings when it starts a new card.

## Email format

- Subject: `Weekly Microsoft 365 Admin Digest | {end date} | {count} admin-impact post(s)`.
- Begin with the reporting period, exact filters, and qualifying count.
- Use the same category and major-change grouping order as Teams. Use a compact table within each group when it remains readable. Otherwise use the same item structure as Teams.
- Include source links when available.

## No-result behavior

If no posts satisfy the selected products and both required filters, still deliver through each enabled method:

- A Teams Adaptive Card using schema version `1.4`, the normal header and reporting-period summary, and one wrapped `TextBlock` stating: `No Message Center posts matched the selected products, category "Plan for change" or "Prevent or fix issue", and tag "Admin impact" for {start timestamp} to {end timestamp} {subscription time zone}.`
- A short email containing the same statement.

Do not claim there were no Message Center posts in the period.

## Failure behavior

- If the Enterprise MCP query fails, do not send a normal or no-result digest. Return a failure summary with the failed step and error details safe to disclose.
- If Teams card delivery fails but email succeeds, report partial delivery and identify Teams as failed.
- If email delivery fails but Teams succeeds, report partial delivery and identify email as failed.
- Do not expose credentials, tokens, connection details, or raw tool payloads.