# Security Policy

## Supported versions

Security fixes are applied to the latest version on the default branch.

## Reporting a vulnerability

Use GitHub private vulnerability reporting when it is enabled for this repository. Do not include credentials, access tokens, tenant data, personal data, connection exports, or exploit details in a public issue.

If private reporting is unavailable, contact the repository owner privately through the contact method listed on their GitHub profile.

## Deployment responsibility

This repository is a reference implementation. Deployers are responsible for reviewing connector permissions, authentication settings, Dataverse security roles, data retention, sharing scope, and compliance requirements in their own tenant.

Before deployment:

- Regenerate tenant-specific OAuth and federated identity configuration.
- Use least-privilege connector and Dataverse permissions.
- Keep `.mcs/` synchronization state and local environment files out of source control.
- Verify that interactive subscription operations cannot access another user's rows.
- Test scheduled delivery with non-production destinations.
- Review logs and diagnostics before sharing them because they may contain tenant or user data.