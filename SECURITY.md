# Security Policy

## Supported versions

Security fixes are applied to the latest version on the default branch.

## Reporting a vulnerability

Use GitHub private vulnerability reporting when it is enabled for this repository. Do not include credentials, access tokens, tenant data, personal data, connection exports, or exploit details in a public issue.

If private reporting is unavailable, contact the repository owner privately through the contact method listed on their GitHub profile.

## Deployment responsibility

This repository is a chat-only reference implementation. Deployers are responsible for reviewing connector permissions, authentication settings, conversation retention, sharing scope, and compliance requirements in their own tenant.

Before deployment:

- Regenerate tenant-specific OAuth and federated identity configuration.
- Use least-privilege connector and tenant-data permissions. Review actual MCP operations, not just the agent's research-only instructions.
- Retain integrated authentication and review the group sharing scope.
- Keep `.mcs/` synchronization state and local environment files out of source control.
- Treat the three agent-author (`Maker`) connections as shared identities. Agent users can retrieve the tenant data available to the shared Enterprise connection, regardless of their individual Microsoft 365 permissions.
- Restrict the agent to an explicitly approved administrator security group. Keep owner-only access until that group is configured, and test with both a permitted user and a nonmember in the intended channel.
- Use a dedicated Enterprise service account with only the required Message Center and Service Health access. Service Support Administrator also grants support-ticket permissions; the agent must still expose only read-only MCP operations.
- Keep service-account credentials in an approved vault, retain MFA and Conditional Access, and arrange ownership, revocation, and reconnection procedures. Do not commit user credentials, connection tokens, or tenant-bound authentication configuration.
- Confirm there are no subscription, email, Teams posting, or scheduled-delivery tools in the imported chat-only agent.
- Review logs and diagnostics before sharing them because they may contain tenant or user data.

The chat-only package does not contain a custom subscription table or digest automation. Importing it over an older unmanaged installation does not delete the old components. See [SETUP.md](SETUP.md#existing-digest-enabled-installations) before removing legacy flows or subscription data.