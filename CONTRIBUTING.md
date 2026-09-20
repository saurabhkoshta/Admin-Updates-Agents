# Contributing

## Before opening a change

- Use a development Power Platform environment.
- Pull the latest agent state before editing.
- Keep `.mcs/`, tokens, connection state, and local environment files out of Git.
- Do not commit tenant data, user destinations, credentials, or raw tool output.
- Preserve the evidence roles defined in `settings.mcs.yml` and the behavior skills.

## Making changes

Keep changes focused and use the existing Copilot Studio YAML structure. Generated schema names, connector IDs, and connection references must remain internally consistent. Avoid hand-editing one generated identifier without updating every dependent reference.

Behavior changes should preserve these guarantees:

- Tenant impact comes only from the enterprise source.
- Public roadmap information does not prove tenant availability.
- Microsoft Learn provides documentation, not tenant applicability.
- Conflicting source values remain visible and attributed.
- Subscription actions operate only on the authenticated user's Dataverse rows.
- Delivery success is reported only after the corresponding action succeeds.

## Validation

Before submitting a pull request:

1. Validate the workspace with the Copilot Studio extension.
2. Review the extension's local-to-remote changes.
3. Test the affected behavior in a development agent.
4. Confirm no `.mcs/` files or credentials are staged.
5. Describe any required connection, table, flow, or model changes in the pull request.

Do not publish a test agent that is shared with production users.
