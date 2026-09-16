# Cowork Value V1 Testing

Cowork Value V1 focuses on modeled value, cost, right-sizing, department views,
skill allocation, and model-attribution readiness. The local template uses one
required `DataFolderPath` parameter. The separate SharePoint template uses
`SharePointSiteUrl` and `SharePointFolderUrl`.

This testing release is version `1.1.0-testing`. Its Value Calculator and Value
vs Cost pages keep five cost inputs synchronized across Credit-Priced,
License-Included, Prepaid, Hybrid, and Monthly Committed billing modes.

Per-user allowance and overage chargeback follows Microsoft's
[`CreditUsage`](https://github.com/microsoft/CreditUsage) Cowork chargeback
reference: unused allowance for one user never offsets another user's overage,
and overage is priced at the selected per-credit rate. The five-mode planning
model and Cowork value/ROI measures are extensions in this template.

## Microsoft chargeback reference preview

[![Microsoft CreditUsage chargeback dashboard preview](https://raw.githubusercontent.com/microsoft/CreditUsage/main/images/dashboard-preview.gif)](https://github.com/microsoft/CreditUsage/blob/main/images/dashboard-preview.gif)

*Official Microsoft `CreditUsage` reference dashboard preview, shown for
provenance. It is not a screenshot of the extended Cowork Value report in this
repository. Source: [Microsoft `CreditUsage`](https://github.com/microsoft/CreditUsage)
(MIT).*

## Release kit

| Resource | Open or download |
| --- | --- |
| Power BI template | [`Cowork Value V1 Testing.pbit`](Cowork%20Value%20V1%20Testing.pbit) |
| SharePoint-folder template | [`Cowork Value V1 SharePoint Testing.pbit`](Cowork%20Value%20V1%20SharePoint%20Testing.pbit) |
| Editable source | [`src/Cowork Value Intelligence - Value LL.pbip`](src/Cowork%20Value%20Intelligence%20-%20Value%20LL.pbip) |
| SharePoint template builder | [`tools/New-CoworkValueSharePointTemplate.ps1`](tools/New-CoworkValueSharePointTemplate.ps1) |
| Synthetic sample package | [`../release/Cowork-Value-Intelligence-Sample-Data.zip`](../release/Cowork-Value-Intelligence-Sample-Data.zip) |
| Shared production guide | [`../DATA_SETUP_START_HERE.md`](../DATA_SETUP_START_HERE.md) |
| Interpretation guide | [`../INTERPRETATION_GUIDE.md#value-template-page-guide`](../INTERPRETATION_GUIDE.md#value-template-page-guide) |
| Least-privilege roles | [`../docs/SECURITY_ROLES.md`](../docs/SECURITY_ROLES.md) |
| Security requirements | [`../SECURITY.md`](../SECURITY.md) |

## Test with fabricated data

1. Extract `..\release\Cowork-Value-Intelligence-Sample-Data.zip`.
2. Open `Cowork Value V1 Testing.pbit`.
3. Set `DataFolderPath` to the nested `sample_data` folder created by the ZIP,
   not its parent.
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

| Source | Value requirement |
| --- | --- |
| Purview Audit Search CSVs | **Required**; folder and valid Cowork records must exist |
| Cost Management Consumption > Users | Required for credit, utilization, cost, and ROI |
| Cowork usage details | Recommended where usage and reconciliation metrics appear |
| Organization | Optional; enables matched department views |
| Identity | Optional display-name enrichment |

The **Reports > Usage > Microsoft Copilot > Credits** CSV is not a compatible
substitute for Cost Management **Consumption > Users**.

Follow the [production export instructions](../DATA_SETUP_START_HERE.md#path-b-connect-customer-exports)
for exact filenames, headers, roles, identity handling, and verification. Keep
only one current schema-valid working file for each optional source.

## Connect a SharePoint folder

Use `Cowork Value V1 SharePoint Testing.pbit` when the approved CSV exports are
stored together in SharePoint.

1. Put the Purview Audit Search CSVs and optional consumption, usage,
   organization, and identity CSVs anywhere below one protected SharePoint
   folder. Discovery is recursive.
2. Set `SharePointSiteUrl` to the site root, not a library, folder, or file:
   `https://contoso.sharepoint.com/sites/CoworkAnalytics`.
3. Set `SharePointFolderUrl` to the folder link. Direct folder URLs,
   path-bearing SharePoint **Copy link** URLs containing `/:f:/r/`, and library
   `AllItems.aspx?id=...` URLs are accepted. Opaque `/:f:/s/` or `/:f:/g/`
   sharing links are not folder paths; open the folder and copy its address
   instead.
4. Select **Load**, choose **Microsoft account** or **Organizational account**
   when Power BI requests SharePoint credentials, and sign in with an account
   that can read the folder.
5. Use the privacy level approved by your organization. After publishing,
   configure credentials for the `SharePointSiteUrl` data source before
   scheduling refresh.

The site root remains a separate parameter intentionally. `SharePoint.Files`
uses that static root so Power BI Service can identify the data source; the
folder link is used only to filter the returned files.

## Viewer-facing pages

1. Start Here
2. Executive Summary
3. Task Categories & Methodology
4. Methodology & Value Calculator
5. Value vs Cost
6. Value by Department
7. Value by User Tier
8. Right-Sizing & Reclaim
9. Skills & Allocated Consumption
10. Model & LLM Breakdown
11. Glossary

The Action Assumptions page is an internal navigation page hidden from standard
page tabs.

## Verify the load

- Users, tasks, dates, skills, and categories populate from Purview.
- Credits and utilization populate from the compatible Cost Management export.
- Department visuals populate only when organization UPNs match detected Cowork
  users.
- Cost and ROI populate only after Finance-approved report inputs are selected.
- Billing Mode, Rate per Credit, Prepaid Credits, Prepaid Rate per Credit, and
  Monthly Committed Credits stay synchronized between both cost-analysis pages.
- `(Model data not available)` is an expected source limitation when Cowork audit
  records do not emit model-specific names; do not infer model usage.
- No page shows an error banner.

For blank or ignored sources, use the shared
[Quick help](../DATA_SETUP_START_HERE.md#quick-help).

## Filter behavior

Every report page has a filter drawer. All 31 bookmark actions are limited to
their target visuals, so opening, closing, or switching views does not reactivate
unrelated content.

## Security and classification

The PBITs contain no imported customer data or machine-bound security binding,
carry the **Public** sensitivity label in Power BI Desktop, and are
unprotected. Apply or confirm the label required by organizational policy
before sharing a refreshed customer-data copy.

The exact distributable PBIT has SHA-256
`c7b1a722c672cbf65d9fb4a66bea4dfa7c17ca0e70c3df4ba04a8e49a35176b6`,
contains 12 pages and 31 target-only bookmarks, and passed all 41
synchronized-control interaction checks.

The exact SharePoint-folder PBIT has SHA-256
`dd360633f9197db6149d43bec739ec6a7f902581448f260d8c46c043b0d8032b`,
contains the same report and model, and changes only the data-source queries and
two setup text entries.
