# Security

## Supported release

Security fixes apply to the latest public testing release.

## Data sensitivity

Production Purview, usage, organization, identity, and consumption exports can
contain personal, tenant, financial, resource, and business information. Never
commit those files, paste them into an issue, or store them in an unapproved
location.

## Access model

Use separate authorized data owners where practical. The Power BI operator does
not need every tenant role.

| Source or task | Recommended minimum |
| --- | --- |
| Purview Audit Search export | Purview `Audit Reader` role group |
| Cowork usage details export | `Reports Reader` |
| Cost Management Consumption > Users export | `AI Reader` |
| Organization/identity export | Existing approved HR/Identity access |
| Power BI Desktop refresh | No tenant role |
| Power BI workspace publication | Pro/PPU unless qualifying capacity applies, plus workspace `Contributor` |

Global Administrator is not a routine report role. An existing Global
Administrator is involved only for a tenant-wide decision to reveal concealed
usage-report identities. Billing Administrator or Global Administrator is
needed only to add or change billing methods.

See [Security roles and access](docs/SECURITY_ROLES.md) for the complete matrix,
boundaries, and Microsoft references.

## Required controls

- Keep customer exports outside the Git working tree.
- Restrict raw and normalized files to approved collection and report owners.
- Apply least privilege and time-bound access where available.
- Preserve raw exports; transform only protected working copies.
- Never store credentials, access tokens, or browser session data in scripts or
  parameter defaults.
- Record source owner, reporting window, export time, transformations, and report
  assumptions.
- Apply retention and deletion requirements to raw and transformed files.
- Review screenshots, videos, PDFs, and report exports for identifiers and URLs.
- Apply the organization's required sensitivity label to refreshed customer
  reports before sharing.

## PBIT classification

Repository visibility, sensitivity labels, and encryption are separate controls.
The repository is public. Never place customer exports, credentials, tenant
URLs, or identifiable screenshots in commits, branches, pull requests, or
issues.

The distributable testing PBIT files contain no imported customer data or
machine-bound `SecurityBindings` stream. They carry the tenant **Public**
sensitivity label and are unprotected; their label metadata is retained
separately from the removed machine-bound security stream.

The legacy combined PBIT is not distributed in the public tree. Its backup is
stored locally outside the repository.

Opening a template can cause the generated report to receive the tenant's
default sensitivity label. Before sharing a refreshed customer-data report,
apply or confirm the label and protection required by organizational policy.

## Storage and service refresh

- Store customer exports outside the repository and limit folder permissions.
- Publishing a report does not make local paths cloud-accessible.
- For scheduled refresh from local or UNC paths, use an approved on-premises
  data gateway and grant the semantic model owner access to its connection.

## Reporting a concern

Report suspected credential exposure, customer-data exposure, or unsafe defaults
through a private security-reporting channel. Do not include secrets, customer
identifiers, tenant URLs, or raw export content in a public issue.
