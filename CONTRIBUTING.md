# Contributing

## Before opening a change

- Use a development Power Platform environment.
- Pull the latest agent state before editing.
- Keep `.mcs/`, tokens, connection state, and local environment files out of Git.
- Keep local editor MCP configuration (`.mcp.json` and `.vscode/`) out of Git. Work IQ is for local VS Code use, not an agent dependency.
- Do not commit tenant data, user destinations, credentials, or raw tool output.
- Preserve the evidence roles defined in `settings.mcs.yml` and the behavior skills.

## Making changes

Keep changes focused and use the existing Copilot Studio YAML structure. Generated schema names, connector IDs, and connection references must remain internally consistent. Avoid hand-editing one generated identifier without updating every dependent reference.

Behavior changes should preserve these guarantees:

- Tenant impact comes only from the enterprise source.
- Public roadmap information does not prove tenant availability.
- Microsoft Learn provides documentation, not tenant applicability.
- Conflicting source values remain visible and attributed.
- The agent responds only in chat. Do not add subscription storage, scheduled flows, email tools, or Teams posting tools to the base package.
- Product scope is conversational. Do not claim to save preferences across conversations.
- Any administrator can request a specific product or all products without subscribing.
- Briefings state the reporting window and source limitations. Do not claim exhaustive coverage without evidence.

## Validation

Before submitting a pull request:

1. Validate the workspace with the Copilot Studio extension.
2. Review the extension's local-to-remote changes.
3. Test the affected behavior in a development agent.
4. Confirm no `.mcs/` files or credentials are staged.
5. Verify the solution archive, source files, and checksum agree. Removing a feature from source alone does not remove it from the ZIP.
6. Describe any required connection or model changes in the pull request.

Run the local package regression check before submitting package changes:

```powershell
.\solution\Test-ChatOnlyPackage.ps1
```

It checks source-to-package consistency, retained components, removed digest dependencies, and the checksum. A local check is not a substitute for an import and chat test in a development environment.

For routing or evaluation changes, also run:

```powershell
.\evals\Test-RoutingEvalSet.ps1
```

Import the natural-language cases and verify actual tool use against the paired routing expectations as described in [SETUP.md](SETUP.md#evaluate-natural-language-routing). Keep prompts independent of server names. Record runtime routing failures separately from connection failures, and never commit tenant-specific responses or raw tool traces.

Do not publish a test agent that is shared with production users.
