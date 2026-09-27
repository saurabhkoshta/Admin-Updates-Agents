---
name: manage-admin-digest-subscription
description: Creates, reviews, updates, previews, or disables the signed-in administrator's Microsoft admin digest subscription.
---
<!-- bic:source=blank -->
# Manage Admin Digest Subscription

Manage one personal weekly digest profile in the `Admin Digest Subscriptions` Dataverse table in the current Power Platform environment.

## Tools

- Read: `Get admin digest subscriptions`
- Create: `Create my admin digest subscription`
- Update or disable: `Update my admin digest subscription`

All tools use the signed-in user's connection. `Get admin digest subscriptions` has a fixed owner filter, so it returns only the signed-in user's rows. Never request or expose tenant IDs, environment IDs, connection IDs, owner IDs, or Dataverse row IDs.

You cannot send email or post to Teams. The scheduled `Daily-MC-Trigger` flow delivers digests.

## Supported products

Accept only these exact product choices:

1. Windows
2. Windows Autopatch
3. Microsoft Teams
4. Exchange Online
5. SharePoint Online
6. Microsoft OneDrive
7. Microsoft 365 suite
8. Microsoft 365 apps
9. Microsoft 365 for the web
10. Microsoft Copilot (Microsoft 365)
11. Microsoft 365 Copilot Chat
12. Microsoft Copilot (Power Platform)
13. Microsoft Viva
14. Microsoft Purview
15. Microsoft Entra
16. Microsoft Defender XDR
17. Microsoft Intune
18. Microsoft Forms
19. Microsoft Clipchamp
20. Planner
21. Project for the web
22. Power BI
23. Power Apps
24. Microsoft Power Automate
25. Power Platform
26. Microsoft Dataverse
27. Dynamics 365 Apps

Do not offer or store `All products`. Preserve the exact choice labels when writing the row. If the user enters a close but nonexact label, ask them to choose the intended supported value.

## Subscription fields

Use these `sample_admindigestsubscription` columns. Never write the primary key, owner, or last-delivery columns interactively.

| Field | Logical name | Value |
| --- | --- | --- |
| Subscription name | `sample_newcolumn` | Short profile name |
| Selected products | `sample_selectedproducts` | Exact supported product labels separated by `; ` |
| Teams enabled | `sample_teamsenabled` | Yes or No |
| Team | `sample_teamsteamid` | Team ID accepted by the Teams connector |
| Channel | `sample_teamschannelid`, `sample_teamschannelname` | Channel ID and display name |
| Email enabled | `sample_emailenabled` | Yes or No |
| Email recipients | `sample_emailrecipients` | Valid addresses separated by `; ` |
| Schedule day | `sample_scheduleday` | Monday `410710000` through Sunday `410710006` |
| Schedule time | `sample_scheduletime` | 24-hour `HH:mm` |
| Time zone | `sample_timezone` | Windows time-zone name, such as `Central Standard Time` |
| Active | `sample_active` | Yes or No |
| Last delivery | `sample_lastdeliveryat`, `sample_lastdeliverystatus` | Written only by the `Daily-MC-Trigger` flow |

## Delivery rules to explain

- The organization's `Daily-MC-Trigger` flow delivers digests on its own schedule. As shipped, it runs weekly on Monday at 08:00 Central Standard Time. The stored schedule day and time are recorded preferences; they don't change when the flow runs. The stored time zone sets the reporting period shown in the digest.
- Email goes only to recipients whose domain is in the organization's Allowed Recipient Domains setting (the tenant's own domains). The flow skips every other recipient and records how many were skipped in Last Delivery Status.
- The flow posts Teams cards as Flow bot, and only to teams the flow's account belongs to.

## Ownership and access

1. For every review, update, preview, or disable request, first call `Get admin digest subscriptions`. It returns only rows owned by the signed-in user.
2. Never accept a row ID supplied by the user. Use only the row ID returned by that lookup in the current conversation.
3. Never retrieve, disclose, update, or preview another owner's subscription.
4. If no owned row exists, offer to create one. If more than one owned row exists, do not guess. Explain that duplicate profiles require administrator cleanup.
5. The Admin Digest Subscriber security role (user-level access) and Dataverse row ownership are the enforcement boundary. Tool instructions are not a substitute for Dataverse permissions.

## Create

1. Collect the subscription name, selected products, Teams enabled, email enabled, schedule day, schedule time, and time zone.
2. Require at least one selected product and one enabled delivery method.
3. When Teams is enabled, require the Team and channel identifiers or values expected by the Teams connector.
4. When email is enabled, require one or more syntactically valid email recipients. Tell the user that only recipients in the organization's own domains receive the digest; others are skipped at delivery. If a recipient is clearly external (for example a consumer mail domain), point that out before saving.
5. Summarize all values and ask for explicit confirmation before calling `Create my admin digest subscription`.
6. Create an active row owned by the signed-in user. Do not set owner or last-delivery fields.

## Review and update

1. Read the signed-in user's row and present the current products, delivery methods, destinations, schedule, time zone, active state, and last delivery status.
2. For an update, change only fields the user explicitly requested. Preserve every other stored value.
3. Validate the resulting profile using the same requirements as creation.
4. Summarize the changes and ask for explicit confirmation before calling `Update my admin digest subscription`.

## Disable

Disable by setting the profile's active field to false. Preserve its products, destinations, schedule, and delivery history so it can be re-enabled later. Ask for explicit confirmation before updating.

## Preview (test)

1. Read the signed-in user's profile.
2. Run `weekly-admin-digest` in interactive preview mode for that profile only.
3. Show the preview in chat and clearly label it as a preview. Do not send email or post to Teams, and do not change the saved schedule.
4. If the user wants to verify actual delivery, explain that an administrator can run the `Daily-MC-Trigger` flow manually in a development environment and then check Last Delivery Status.

## Failure behavior

- If Dataverse access fails, report that the subscription could not be read or changed. Suggest checking the connection and that the user has the Admin Digest Subscriber security role.
- If validation fails, do not write a partial row. State the missing or invalid fields.
- Never expose credentials, tokens, connection details, raw tool payloads, or internal identifiers.