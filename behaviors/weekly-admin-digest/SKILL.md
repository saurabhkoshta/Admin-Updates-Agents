---
name: weekly-admin-digest
description: Retrieves Message Center posts for the scheduled weekly admin digest flow, or previews the digest in chat. Never delivers email or Teams messages.
---
<!-- bic:source=blank -->
# Weekly Admin Digest

The weekly digest has two parts:

- The `Daily-MC-Trigger` flow owns scheduling, subscription selection, filtering, ordering, Adaptive Card and email rendering, recipient-domain allowlisting, delivery, and last-delivery status. Its logic is deterministic. It sends a digest for each active personal subscription and, when an administrator has configured it, one shared all-products digest.
- This skill only retrieves and summarizes Message Center posts for that flow, or previews a digest in chat.

You have no email or Teams tool. Never claim that a digest was sent or posted.

## Scheduled data mode

Use this mode when the message starts with `Scheduled weekly-admin-digest data run`. The flow supplies the reporting window, an exact Microsoft Graph request, and a structured output schema.

1. Use `MCP-Server-for-Enterprise` to run the supplied Microsoft Graph GET request exactly as written. Do not change its filter, select, or paging parameters.
2. Follow `@odata.nextLink` until every page is retrieved.
3. Return every post the request returns. Do not filter, merge, reorder, deduplicate, or omit posts. The flow applies the category, tag, and product filters.
4. Copy `id`, `title`, `services`, `category`, `tags`, `isMajorChange`, `lastModifiedDateTime`, and `actionRequiredByDateTime` exactly as returned. Use an empty string when a timestamp is missing. Never infer or normalize these values.
5. For each post, write:
   - `adminImpact`: at most 300 characters stating what changes and who is affected, using only the post body.
   - `action`: at most 300 characters with the Microsoft-stated administrator action from the post body, or an empty string when the post states none. Never invent an action.
6. Add `learnTitle` and `learnUrl` only when the post has category `planForChange` or `preventOrFixIssue`, lacks actionable implementation detail, and a `Microsoft Learn Docs MCP Server` result clearly matches the exact product, feature, Message Center ID, or error code. Use only canonical `https://learn.microsoft.com/` links. Otherwise leave both empty. Learn content never changes Message Center dates, status, impact, or actions.
7. Set `status` to `ok` only when every page was retrieved. If the Enterprise request fails, is denied, or is incomplete, set `status` to `error`, return an empty `posts` array, and put a short, safe summary in `error`.
8. Do not send email, post to Teams, create or update Dataverse rows, or call `Daily-MC-Trigger`.

## Interactive preview mode

Use this mode when a signed-in administrator asks to preview or test their digest, usually from `manage-admin-digest-subscription`, or asks what this week's admin digest contains.

1. If the user has a subscription, use the row returned by `Get admin digest subscriptions` for the signed-in user. Never preview another user's subscription. If the user has no subscription, or asks for everything, preview all products; state the time zone you used (the user's stated time zone, otherwise UTC).
2. Use the rolling seven days ending now. State the exact start and end timestamps and the subscription's time zone.
3. Retrieve Message Center posts from `MCP-Server-for-Enterprise` for that window.
4. Apply the same rules the flow applies:
   - Category is `planForChange` or `preventOrFixIssue` (case-insensitive).
   - At least one tag is `Admin impact` (case-insensitive).
   - When the subscription has selected products, at least one returned service matches a selected product (case-insensitive). An empty selection means all products. Never infer a product from the title.
   - A missing category, tag, or service never matches.
5. Group by `Plan for change` then `Prevent or fix issue`, and within each by `Major: Yes` then `Major: No`. Within a group, list posts with an action-required date first (soonest first), then the others by last-modified date (newest first).
6. For each post, show the Message Center ID, title, services, timing, admin impact, Microsoft-stated action or `No explicit admin action provided`, and the Message Center link. Label any recommendation that Microsoft did not state as `Suggested admin consideration`.
7. If nothing matches, say that no posts matched the selected products (or all products) and both filters for the stated window. Do not claim that no Message Center posts exist.
8. End by explaining that this is a preview, and that delivery happens only through the scheduled `Daily-MC-Trigger` flow, which sends email only to recipients in the organization's allowed domains.

## Accuracy and safety

- Treat tool results as the source of truth. Never invent posts, IDs, dates, services, tags, or actions.
- Never use Microsoft Learn as evidence that a change affects the tenant.
- Do not expose credentials, tokens, connection details, internal identifiers, or raw tool payloads.
