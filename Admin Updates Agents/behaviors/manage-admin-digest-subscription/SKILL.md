---
name: manage-admin-digest-subscription
description: Creates, reviews, updates, tests, or disables the authenticated administrator's Microsoft admin digest subscription.
---
<!-- bic:source=blank -->
# Manage Admin Digest Subscription

Manage one personal weekly digest profile in the `Admin Digest Subscriptions` Dataverse table in the current Power Platform environment.

## Tools

- Read: `Get admin digest subscriptions`
- Create: `Create my admin digest subscription`
- Update or disable: `Update my admin digest subscription`

All tools use the authenticated user's connection. Never request or expose tenant IDs, environment IDs, connection IDs, owner IDs, or Dataverse row IDs.

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

## Ownership and access

1. For every review, update, test, or disable request, first call `Get admin digest subscriptions` for rows owned by the authenticated user.
2. Never accept a row ID supplied by the user. Use only the row ID returned by that owner-scoped lookup in the current turn.
3. Never retrieve, disclose, update, or test another owner's subscription.
4. If no owned row exists, offer to create one. If more than one owned row exists, do not guess. Explain that duplicate profiles require administrator cleanup.
5. Rely on Dataverse user-or-team ownership and least-privilege security roles as the enforcement boundary. Tool instructions are not a substitute for Dataverse permissions.

## Create

1. Collect the subscription name, selected products, Teams enabled, email enabled, schedule day, schedule time, and time zone.
2. Require at least one selected product and one enabled delivery method.
3. When Teams is enabled, require the Team and channel identifiers or values expected by the Teams connector.
4. When email is enabled, require one or more valid email recipients.
5. Summarize all values and ask for explicit confirmation before calling `Create my admin digest subscription`.
6. Create an active row owned by the authenticated user. Do not set last-delivery fields during creation.

## Review and update

1. Read the authenticated user's row and present the current products, delivery methods, destinations, schedule, time zone, and active state.
2. For an update, change only fields the user explicitly requested. Preserve every other stored value.
3. Validate the resulting profile using the same requirements as creation.
4. Summarize the changes and ask for explicit confirmation before calling `Update my admin digest subscription`.

## Disable

Disable by setting the profile's active field to false. Preserve its products, destinations, schedule, and delivery history so it can be re-enabled later. Ask for explicit confirmation before updating.

## Test

1. Read the authenticated user's active profile.
2. Run `weekly-admin-digest` for that profile only, using the rolling seven-day window ending at the current time in the stored time zone.
3. Send only through the profile's enabled delivery methods and destinations.
4. Clearly label the result as a test digest.
5. Report each attempted delivery separately. Do not change the saved schedule.

## Failure behavior

- If Dataverse access fails, report that the subscription could not be read or changed and suggest checking the imported connection reference and table permissions.
- If validation fails, do not write a partial row. State the missing or invalid fields.
- Never expose credentials, tokens, connection details, raw tool payloads, or internal identifiers.