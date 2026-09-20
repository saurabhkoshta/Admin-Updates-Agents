---
name: weekly-admin-digest
description: Creates and delivers the weekly Microsoft 365 administrator digest from Plan for change or Prevent or fix issue posts tagged Admin impact.
---
<!-- bic:source=blank -->
# Weekly Admin Digest

Create and automatically deliver a concise weekly digest of tenant-specific Microsoft 365 Message Center posts for administrators.

## Fixed configuration

- Schedule: Monday at 8:00 AM Central Time.
- Reporting window: the rolling seven days immediately before the scheduled run time.
- Tenant source: `MCP-Server-for-Enterprise`.
- Required filters: category equals `planForChange` or `preventOrFixIssue` AND tag equals `Admin impact`, with text comparisons case-insensitive.
- Teams delivery tool: `Post weekly admin digest card`.
- Email delivery tool: `Send an email (V2)`.
- Teams destination: the General channel in Team `dd7052d0-2079-4bb3-a778-d2f996559aef`.
- Email recipient: `admin@example.com`.
- Delivery mode: automatic, without approval.

## Procedure

1. Determine the run timestamp in Central Time and calculate the exact rolling seven-day start and end timestamps. Include both timestamps in the digest.
2. Query `MCP-Server-for-Enterprise` for Message Center posts in that window. Request `category`, `tags`, and `isMajorChange` explicitly for every returned post.
3. Keep a post only when both conditions are explicitly satisfied:
   - Category is `planForChange` or `preventOrFixIssue`, compared case-insensitively.
   - At least one message tag is `Admin impact`, compared case-insensitively.
4. Do not treat a missing category or tag as a match. Do not substitute similar values such as severity, relevance, recommended, important, user impact, or admin action required.
5. Deduplicate results by Message Center post ID. When duplicate records differ, retain the newest tool-returned version and preserve its latest status and dates.
6. Group included posts by category in this order: `planForChange`, then `preventOrFixIssue`. Within each category, group posts by `isMajorChange`, showing `Major: Yes` before `Major: No`. Treat only boolean `true` as `Major: Yes`; false or missing values are `Major: No`.
7. Within each major-change group, sort posts by the nearest administrator action or rollout date when available, then by publication or last-updated date, newest first.
8. For each post, preserve the Message Center ID, title, affected product or service, category, major-change status, status, published or updated date, rollout or action date, administrator impact, recommended action, and source link when returned by the tool.
9. Summarize only facts supported by the tool result. Label any practical recommendation not stated by Microsoft as `Suggested admin consideration`.
10. Render one canonical digest, then adapt it into the Teams Adaptive Card and email formats below without changing facts.
11. Call `Post weekly admin digest card`. Post as `Flow bot`, post in `Channel`, and target the configured Team and General channel. Pass valid Adaptive Card JSON as the card body, not Markdown and not an `AdaptiveCardPrompt`.
12. Call `Send an email (V2)` with the configured recipient, generated subject, and email version.
13. Confirm each delivery separately. Never report successful delivery unless its action succeeds.
14. Do not call `Daily-MC-Trigger` while executing this skill. The workflow initiates digest generation and must not be invoked recursively as a delivery step.

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

If no posts satisfy both filters, still deliver:

- A Teams Adaptive Card using schema version `1.4`, the normal header and reporting-period summary, and one wrapped `TextBlock` stating: `No Message Center posts matched category "Plan for change" or "Prevent or fix issue" AND tag "Admin impact" for {start timestamp} to {end timestamp} Central Time.`
- A short email containing the same statement.

Do not claim there were no Message Center posts in the period.

## Failure behavior

- If the Enterprise MCP query fails, do not send a normal or no-result digest. Return a failure summary with the failed step and error details safe to disclose.
- If Teams card delivery fails but email succeeds, report partial delivery and identify Teams as failed.
- If email delivery fails but Teams succeeds, report partial delivery and identify email as failed.
- Do not expose credentials, tokens, connection details, or raw tool payloads.