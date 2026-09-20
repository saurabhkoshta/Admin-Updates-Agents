---
name: weekly-admin-digest
description: Create the scheduled weekly Microsoft 365 administrator digest from tenant Message Center posts. Use this skill for weekly digest generation and requests to preview, regenerate, or deliver the admin digest.
---

# Weekly Admin Digest

Create a concise weekly digest of tenant-specific Microsoft 365 Message Center posts for administrators.

## Fixed configuration

- Schedule: Monday at 8:00 AM Central Time.
- Reporting window: the rolling seven days immediately before the scheduled run time.
- Tenant source: MCP-Server-for-Enterprise.
- Required filters: category equals `planForChange` or `preventOrFixIssue` AND tag equals `Admin impact`, with text comparisons case-insensitive.
- Teams delivery tool: `Post message in a chat or channel`.
- Email delivery tool: `Send an email (V2)`.
- Teams destination: the General channel in Team `dd7052d0-2079-4bb3-a778-d2f996559aef`.
- Email recipient: `admin@example.com`.
- Delivery mode: automatic, without approval.

## Procedure

1. Determine the run timestamp in Central Time and calculate the exact rolling seven-day start and end timestamps. Include both timestamps in the digest.
2. Query MCP-Server-for-Enterprise for Message Center posts in that window. Request `category`, `tags`, and `isMajorChange` explicitly for every returned post.
3. Keep a post only when both conditions are explicitly satisfied:
   - Category is `planForChange` or `preventOrFixIssue`, compared case-insensitively.
   - At least one message tag is `Admin impact`, compared case-insensitively.
4. Do not treat a missing category or tag as a match. Do not substitute similar values such as severity, relevance, recommended, important, user impact, or admin action required.
5. Deduplicate results by Message Center post ID. When duplicate records differ, retain the newest tool-returned version and preserve its latest status and dates.
6. Group included posts by category in this order: `planForChange`, then `preventOrFixIssue`. Within each category, group posts by `isMajorChange`, showing `Major: Yes` before `Major: No`. Treat only the boolean value `true` as `Major: Yes`; false or missing values are `Major: No`.
7. Within each major-change group, sort posts by the nearest administrator action or rollout date when available, then by publication or last-updated date, newest first.
8. For each post, preserve the Message Center ID, title, affected product or service, category, major-change status, status, published or updated date, rollout or action date, administrator impact, recommended action, and source link when returned by the tool.
9. Summarize only facts supported by the tool result. Label any practical recommendation not stated by Microsoft as `Suggested admin consideration`.
10. Render one canonical digest, then adapt it into the Teams and email formats below without changing facts.
11. Call `Post message in a chat or channel` with the Teams version, targeting the configured Team and General channel.
12. Call `Send an email (V2)` with the configured recipient, generated subject, and email version.
13. Confirm each delivery separately. Never report successful delivery unless its action succeeds.
14. Do not call `Daily-MC-Trigger` while executing this skill. The workflow initiates digest generation and must not be invoked recursively as a delivery step.

## Teams format

Use this structure:

```markdown
# Weekly Microsoft 365 Admin Digest
**Reporting period:** {start timestamp} to {end timestamp} Central Time
**Included:** Plan for change or Prevent or fix issue AND Admin impact tag

{count} qualifying Message Center post(s)

## Plan for change
### Major: Yes
## {Message Center ID}: {title}
- **Product:** {product or service}
- **Category:** Plan for change
- **Major:** Yes
- **Status:** {status}
- **Timing:** {rollout, action, published, or updated dates}
- **Admin impact:** {concise impact}
- **Action:** {Microsoft-stated action or "No explicit admin action provided"}
- **Source:** {link when available}

### Major: No
{items using the same item fields}

## Prevent or fix issue
### Major: Yes
{items using the same item fields}

### Major: No
{items using the same item fields}
```

Omit empty category or major-change groups. Keep the Teams post scannable. If the digest exceeds the delivery action's supported message size, split it into numbered parts without splitting an individual Message Center item or separating it from its category and major-change headings.

## Email format

- Subject: `Weekly Microsoft 365 Admin Digest | {end date} | {count} admin-impact post(s)`
- Begin with the reporting period, exact filters, and qualifying count.
- Use the same category and major-change grouping order as Teams. Use a compact table within each group when it remains readable. Otherwise use the same item structure as Teams.
- Include source links when available.

## No-result behavior

If no posts satisfy both filters, still produce and deliver a short digest stating:

`No Message Center posts matched category "Plan for change" or "Prevent or fix issue" AND tag "Admin impact" for {start timestamp} to {end timestamp} Central Time.`

Do not claim there were no Message Center posts in the period.

## Failure behavior

- If the Enterprise MCP query fails, do not send a normal or no-result digest. Return a failure summary with the failed step and error details safe to disclose.
- If Teams delivery fails but email succeeds, report partial delivery and identify Teams as failed.
- If email delivery fails but Teams succeeds, report partial delivery and identify email as failed.
- Do not expose credentials, tokens, connection details, or raw tool payloads.
