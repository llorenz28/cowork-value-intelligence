# Cowork Adoption Intelligence v2 Testing

Cowork Adoption Intelligence tracks activation, sustained usage, potential
enablement champions, action patterns, and delegation maturity without mixing
those questions with cost and ROI. It uses one required `DataFolderPath`
parameter.

## Release kit

| Resource | Open or download |
| --- | --- |
| Power BI template | [`Cowork Adoption Intelligence v2 Testing.pbit`](Cowork%20Adoption%20Intelligence%20v2%20Testing.pbit) |
| Synthetic sample package | [`release/Cowork-Adoption-Intelligence-Sample-Data.zip`](release/Cowork-Adoption-Intelligence-Sample-Data.zip) |
| Editable source | [`src/Cowork Adoption Intelligence.pbip`](src/Cowork%20Adoption%20Intelligence.pbip) |
| Shared production guide | [`../DATA_SETUP_START_HERE.md`](../DATA_SETUP_START_HERE.md) |
| Least-privilege roles | [`../docs/SECURITY_ROLES.md`](../docs/SECURITY_ROLES.md) |
| Security requirements | [`../SECURITY.md`](../SECURITY.md) |

## Test with fabricated data

1. Extract `release\Cowork-Adoption-Intelligence-Sample-Data.zip` to a dedicated
   folder.
2. Open `Cowork Adoption Intelligence v2 Testing.pbit`.
3. Set `DataFolderPath` to the extraction folder itself. The ZIP places the CSVs
   and `purview_audit` directly in that folder.
4. Select the local-file privacy level approved by your organization.
5. Refresh.

The sample is deterministic and fabricated. All identities use `@example.com`;
it must never be represented as customer data.

## Connect production data

Use a narrow protected folder outside the Git repository:

```text
C:\CoworkValueData\
  purview_audit\
    Purview-Cowork-part01.csv
  CoworkUserDetails.csv
  CoworkConsumptionDetails.csv
  CoworkUserOrgDetails.csv
  identity\
    cowork_users.csv
```

Set `DataFolderPath` to `C:\CoworkValueData`. Discovery is recursive.

| Source | Adoption requirement |
| --- | --- |
| Purview Audit Search CSVs | **Required**; folder and valid Cowork records must exist |
| Cowork usage details | Recommended for scheduled/user-initiated metrics and reconciliation |
| Organization and identity | Optional enrichment |
| Consumption | Not required for the core adoption experience |

Follow the [production export instructions](../DATA_SETUP_START_HERE.md#path-b-connect-customer-exports)
for exact filenames, headers, roles, identity handling, and verification. Keep
only one current schema-valid working file for each optional source.

## Pages

1. Start Here
2. Executive Summary
3. Weekly Adoption & Usage
4. User Maturity
5. Cowork Champions
6. Actions by Category
7. Activity & Value
8. Usage Explorer
9. Adoption Metric Guide

## Verify the load

- Users, tasks, dates, skills, and categories populate from Purview.
- Scheduled/user-initiated and reconciliation metrics populate when Cowork usage
  is present.
- Cowork Champions defaults to eight Top-10% candidates in the synthetic
  72-user sample; selecting Analysis & Research returns five candidates.
- Top 5%, Top 10%, and Top 20% tiers return 4, 8, and 15 sample candidates.
- The seven-category lens renders in one row, and the candidate and coverage
  panels align without clipped rows or unused lower-page space.
- Friendly names and organization fields appear only when matching optional
  files are present.
- No page shows an error banner.

Potential champions are engagement signals for enablement planning, not
employee-performance ratings. Confirm role fit, willingness, and manager support
before outreach.

For blank or ignored sources, use the shared
[Quick help](../DATA_SETUP_START_HERE.md#quick-help).

## Security and classification

The PBIT contains no imported customer data or machine-bound security binding.
It carries the tenant **Public** sensitivity label without encryption. Apply or
confirm the label required by organizational policy before sharing a refreshed
customer-data copy.
