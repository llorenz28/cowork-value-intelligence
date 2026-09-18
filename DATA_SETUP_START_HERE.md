# Get your data: start here

This guide covers the included Cowork testing templates. It separates
collection from report operation so no single person needs every tenant role.

> **Recommended first step:** load the fabricated sample data. This proves the
> selected PBIT and local Power BI environment work before customer permissions,
> export formats, and identity joins are introduced.

## 1. Choose the template

| Template | Use it when | Parameter screen |
| --- | --- | --- |
| `adoption\Cowork Adoption Intelligence v2 Testing.pbit` | You want focused adoption, champions, and delegation analysis without cost/ROI | One required `DataFolderPath` |
| `value\Cowork Value V1.3 Friendly Skills Testing.pbit` | You want focused value, cost, department, and right-sizing analysis with readable skill/tool labels | One required `DataFolderPath` |
| `value\Cowork Value V1.3 SharePoint Friendly Skills Testing.pbit` | You want the same Value analysis and readable skill/tool labels, the approved CSVs are stored together in SharePoint, and current or legacy Purview exports must load | Required `SharePointSiteUrl` and `SharePointFolderUrl` |
| `value\backups\2026-09-18-pre-v1.3-friendly-skills\Cowork Value V1 Testing.pbit` | You need the backed-up local Value baseline for rollback or comparison | One required `DataFolderPath` |
| `value\backups\2026-09-18-pre-v1.3-friendly-skills\Cowork Value V1.2 SharePoint Testing.pbit` | You need the backed-up SharePoint baseline for rollback or comparison | Required `SharePointSiteUrl` and `SharePointFolderUrl` |
| `value\Cowork Value V1 SharePoint Testing.pbit` | You need the previous SharePoint revision for reproducibility | Required `SharePointSiteUrl` and `SharePointFolderUrl`; legacy Purview outer columns only |

Every template searches one folder and all its subfolders.

## 2. Know which sources light up the report

| Source | Adoption | Value | Minimum access |
| --- | --- | --- | --- |
| Purview Audit Search CSVs | **Required** | Required for core activity and value analysis; optional for a V1.2 SharePoint usage-only partial load | Purview `Audit Reader` role group |
| Cowork usage details CSV | Recommended | Recommended where usage metrics appear | `Reports Reader` |
| Cost Management Consumption > Users CSV | Not required for the core adoption experience | Required for credit, cost, utilization, and ROI | `AI Reader` |
| Organization CSV | Optional enrichment | Optional; enables department views | Existing approved HR/Identity access |
| `cowork_users.csv` | Optional | Optional | Existing approved Identity access |

Purview is the hard dependency for core activity, task, skill, and value
analysis. The V1.3 SharePoint template inherits V1.2's ability to load reported
usage users and metrics without Purview, but marks that state as a partial load.
Missing optional files load as unavailable; the model never invents customer
data.

Read [Security roles and access](docs/SECURITY_ROLES.md) before requesting access.
This CSV-fed release does not need an app registration, client secret, Microsoft
Graph application permission, Defender permission, or routine Global
Administrator assignment.

---

## Path A: test with fabricated sample data

Allow about 10 minutes. All sample identities use `@example.com`; no customer or
tenant data is included.

### Adoption template

1. Extract
   `adoption\release\Cowork-Adoption-Intelligence-Sample-Data.zip` to a dedicated
   folder.
2. Open `adoption\Cowork Adoption Intelligence v2 Testing.pbit`.
3. Set `DataFolderPath` to the extraction folder itself. The ZIP places the CSVs
   and `purview_audit` directly in that folder.
4. Select **Load**, approve the appropriate privacy level, and refresh.

### Value template

1. Extract `release\Cowork-Value-Intelligence-Sample-Data.zip`.
2. Open `value\Cowork Value V1.3 Friendly Skills Testing.pbit`.
3. Set `DataFolderPath` to the nested `sample_data` folder created by the ZIP,
   not to its parent folder.
4. Select **Load**, approve the appropriate privacy level, and refresh.

### Value SharePoint template

1. Extract `release\Cowork-Value-Intelligence-Sample-Data.zip`.
2. Upload the nested `sample_data` folder to a protected SharePoint site.
3. Open `value\Cowork Value V1.3 SharePoint Friendly Skills Testing.pbit`.
4. Set `SharePointSiteUrl` to the site root, such as
   `https://contoso.sharepoint.com/sites/CoworkAnalytics`.
5. Set `SharePointFolderUrl` to the uploaded `sample_data` folder link.
6. Select **Load**, sign in with an account that can read the folder, approve
   the appropriate privacy level, and refresh.

### Confirm the sample worked

1. A summary page shows users and tasks.
2. Activity, skill, and category visuals contain data.
3. The Value template shows consumption/value content after a
   labor rate, billing model, and rate per credit are selected.
4. No visual shows an error banner.
5. Synthetic model labels or an explicit model-unavailable state appear; no real
   model attribution is implied.

If these checks fail, fix the local PBIT, path, or Power BI environment before
introducing customer exports.

---

## Path B: connect customer exports

### Step 1: assign data owners

| Owner | Deliverable | Recommended minimum |
| --- | --- | --- |
| Compliance/Purview owner | Raw Audit Search CSV files | Purview `Audit Reader` |
| Microsoft 365 reports owner | Cowork usage details CSV | `Reports Reader` |
| Copilot cost owner | Cost Management Consumption > Users CSV | `AI Reader` |
| HR/Identity owner | Optional organization and identity files | Existing approved access |
| Finance owner | Approved currency, labor rate, billing model, and rate per credit | No tenant admin role |
| Power BI owner | Loads working copies, validates, labels, and publishes | No tenant role for Desktop |

Prefer exports from existing authorized owners over assigning every role to the
Power BI operator.

### Step 2: create a protected working folder

Create a protected local folder outside this Git repository, or use one
protected SharePoint folder for the SharePoint Value template:

```text
C:\CoworkValueData\
  purview_audit\
    Purview-Cowork-2026-08-01-to-2026-08-31.csv
  CoworkUserDetails.csv
  CoworkConsumptionDetails.csv
  CoworkUserOrgDetails.csv
  identity\
    cowork_users.csv
```

The local-path templates can use `C:\CoworkValueData` as `DataFolderPath`
because their search is recursive. For the SharePoint Value template, upload
the same folder structure and enter its site root and folder link.

Keep immutable raw exports in a separately protected location. Normalize only
working copies. Record the source owner, reporting window, export time, and any
header or value transformations.

### Step 3: export Purview audit records for core analysis

**Access:** assign the collector to the **Audit Reader** role group in Microsoft
Purview. It grants the `View-Only Audit Logs` role needed to search and export
without permission to manage auditing.

1. Sign in to [Microsoft Purview](https://purview.microsoft.com).
2. Select **Audit**. If needed, select **View all solutions** > **Audit**.
3. Create a search with UTC start and end times for the reporting period.
4. In **Activities - operations names**, enter `CopilotInteraction`.
5. Run the search and wait for it to complete.
6. Select **Export** and preserve the downloaded raw CSV unchanged.
7. Copy the file into `C:\CoworkValueData\purview_audit`.
8. For the local templates and the previous V1 SharePoint revision, confirm the
   working CSV has these outer columns:

```csv
RecordId,CreationDate,Operation,UserId,AuditData
```

   The V1.2 SharePoint revision also accepts the current portal shape without
   manual header changes:

```csv
CreationDate,UserIds,Operations,AuditData
```

   For the current shape, `Operations` and `UserIds` may be scalar values or
   JSON-style lists. If the outer `RecordId` is absent, V1.2 uses `Id` or
   `RecordId` from `AuditData`, then source path plus row number.
9. Confirm at least one row has `Operation` or `Operations` equal to
   `CopilotInteraction` and its
   `AuditData` JSON contains `CopilotEventData.AppHost` with `cowork`
   case-insensitively.

Do not expand, reformat, or hand-edit the JSON in `AuditData`. Use the V1.2
SharePoint revision for the current four-column portal export. Normalize a
protected working copy only when using a template that still requires the
legacy shape.

Audit searches accept a maximum 180-day range. A single Audit Standard export
can contain up to 50,000 records; Audit Premium raises the export limit to
1,000,000. For larger volumes, export non-overlapping windows into the same
folder. The model combines valid files and removes duplicate `RecordId` values.
Audit Standard retention is normally 180 days; eligible licensing and retention
policies can provide longer coverage.

Microsoft references:
[Audit permissions](https://learn.microsoft.com/purview/audit-get-started#step-2-assign-permissions-to-search-the-audit-log),
[search instructions](https://learn.microsoft.com/purview/audit-search),
[export limits](https://learn.microsoft.com/purview/audit-log-export-records),
and [Copilot/Cowork audit fields](https://learn.microsoft.com/purview/audit-copilot).

### Step 4: export recommended Cowork usage details

**Access:** `Reports Reader`. `Usage Summary Reports Reader` and User Experience
Success Manager can read usage summaries but do not receive user details needed
for UPN joins.

1. Sign in to the [Microsoft 365 admin center](https://admin.microsoft.com).
2. Select **Copilot** > **Cowork** > **Usage**.
3. Select the intended date range and record **Last updated**.
4. Above **Cowork usage details**, select **Export**.
5. Preserve the raw download, then save a working copy as
   `C:\CoworkValueData\CoworkUserDetails.csv`.
6. Normalize the working-copy headers to:

```csv
UserPrincipalName,DisplayName,TotalTasks,ScheduledTasks,UserInitiatedTasks,ActiveDays,LastActivityDate
```

| Microsoft export | Template header |
| --- | --- |
| `User ID` | `UserPrincipalName` |
| `Display name` | `DisplayName` |
| `Total tasks` | `TotalTasks` |
| `Scheduled tasks` | `ScheduledTasks` |
| `User-initiated tasks` | `UserInitiatedTasks` |
| `Active days` | `ActiveDays` |
| `Last activity date` | `LastActivityDate` |

User identities are concealed by default in Microsoft 365 usage reports. A
`Reports Reader` assignment does not override that tenant setting. If the export
contains anonymized identities, an existing Global Administrator must decide
whether the tenant-wide concealment setting may be changed under organizational
privacy policy. Do not grant Global Administrator to the report operator.

Microsoft reference:
[Cowork usage report](https://learn.microsoft.com/microsoft-365/admin/activity-reports/cowork-usage-report?view=o365-worldwide).

### Step 5: export Cost Management user consumption

This file is optional for Adoption analysis but required for the Value credit,
cost, utilization, forecast, and ROI experience.

**Access:** use `AI Reader` as the read-only starting role. Microsoft also lists
Global Reader, License Administrator, and other supported reader roles for
consumption dashboards. `AI Administrator` or `License Administrator` is needed
only when the person must also manage spending policies, limits, or alerts.
Microsoft documents access to the consumption reports, not a separate export
permission. If the export control is unavailable, verify tenant UI and policy
with the existing cost owner before requesting a broader role.

1. Sign in to the Microsoft 365 admin center.
2. Select **Copilot** > **Cost Management** > **Consumption**.
3. Open the **Users** view.
4. Export the user-level consumption snapshot.
5. Preserve the raw download, then save the compatible working copy as
   `C:\CoworkValueData\CoworkConsumptionDetails.csv`.
6. Confirm these exact columns exist:

```csv
Display Name,User Principal Name,Monthly credit limit,Monthly credits used,User ID,Microsoft 365 Copilot license,Last activity date,Session Count,% Used
```

> **Do not substitute the Copilot Credits usage report.** The CSV under
> **Reports > Usage > Microsoft Copilot > Credits** contains fields such as
> username, seven-day credits, and 30-day credits. It does not contain the
> monthly limit, monthly used, license, session, and utilization fields required
> by this model and cannot be dropped into `DataFolderPath`.

If the Cost Management export no longer contains the nine exact fields above,
stop and treat consumption as unavailable until a controlled transformation or
model update is approved.

Cost data appears only after usage-based billing is configured and supported
services generate consumption. Billing-method changes require Billing
Administrator or Global Administrator; those roles are not needed for routine
read-only export.

Microsoft references:
[Cost Management roles and consumption](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-manage-copilot-credits#role-requirements)
and [Copilot Credits usage-report schema](https://learn.microsoft.com/microsoft-365/admin/activity-reports/microsoft-365-copilot-credits?view=o365-worldwide).

### Step 6: prepare optional organization and identity files

Use the authorized HR or Identity data owner. Microsoft documents that both
standard and admin users can download an Entra user list, but tenant policy and
data-handling approval still govern who should do it.

#### Organization file

Save the normalized working copy as
`C:\CoworkValueData\CoworkUserOrgDetails.csv` with these exact,
case-sensitive headers:

```csv
userPrincipalName,displayName,department,jobTitle,jobFamily,city,country,costCenter,manager,businessUnit
```

An Entra bulk user export includes some, but not all, of these fields. Add any
missing headers to the protected working copy; cells may be blank when an
approved source does not provide a value. HR may be needed for `jobFamily`,
`costCenter`, `manager`, or `businessUnit`. Only rows whose
`userPrincipalName` matches a detected Cowork user appear.

#### Identity-enrichment file

Save `C:\CoworkValueData\identity\cowork_users.csv` with:

```csv
id,displayName,userPrincipalName
```

For an Entra bulk export, rename `objectId` to `id` in the working copy and keep
only approved fields.

#### UPN normalization

The V1.2 SharePoint revision trims UPNs and compares them case-insensitively
across Purview, usage, consumption, organization, and identity sources. Lowercase
UPNs remain the safest convention for portable working copies and are still
required for templates whose optional-source joins are case-sensitive.

Microsoft reference:
[Download Entra users](https://learn.microsoft.com/entra/identity/users/users-bulk-download).

### Step 7: organize files for the selected template

#### Adoption and Value: one folder

Set `DataFolderPath` to `C:\CoworkValueData`. Discovery is recursive and uses
these names:

| Source | Preferred filenames |
| --- | --- |
| Purview | V1.2 SharePoint: any `.csv` with `AuditData` plus current or legacy operation/user fields; other templates: the five legacy audit columns |
| Cowork usage | `CoworkUserDetails.csv` or `Cowork Usage.csv` |
| Consumption | `CoworkConsumptionDetails.csv` or `Consumption - Users.csv` |
| Organization | `CoworkUserOrgDetails.csv` or `Cowork User Organization.csv` |
| Identity | Exact filename `cowork_users.csv` |

Keep only one current schema-valid working file for each optional source. If
several files have the same schema, the model takes the first enumerated match;
it does not choose the newest file.

Select the narrow data folder itself, not a repository root, Downloads folder,
or QA parent containing unrelated exports.

### Step 8: load and verify in Power BI Desktop

1. Open the selected PBIT and enter its parameter values. For the SharePoint
   template, use the site root for `SharePointSiteUrl` and the protected folder
   link for `SharePointFolderUrl`.
2. Select **Load**.
3. When prompted for privacy levels, use the classification approved by your
   organization. Do not bypass a policy prompt.
4. Refresh.
5. Validate sources in this order:

| Check | Expected result |
| --- | --- |
| Start Here readiness | A specific state reports missing inputs, partial usage-only load, an identity mismatch, core activity readiness, or all core inputs ready |
| Purview | Cowork users, tasks, skills, categories, and activity dates populate |
| Usage | Scheduled/user-initiated metrics and audit reconciliation populate where shown |
| Identity | Friendly names appear and UPN joins do not drop users |
| Organization | Department or business-unit visuals populate where shown |
| Consumption | Credits, utilization, cost, and forecast populate in Value |
| Value assumptions | A Finance-approved labor rate, billing model, currency, and rate per credit are selected and documented |
| Model attribution | Source model information appears only when emitted; `(Model data not available)` is a valid source limitation |

Do not interpret cost or ROI until consumption and Finance-approved assumptions
are both present. Do not interpret the Model & LLM page as observed model usage
when it displays the unavailable placeholder.

### Step 9: publish only after Desktop validation

1. Confirm customer files remain outside the Git repository.
2. Apply or confirm the sensitivity label required by organizational policy.
3. Validate every page locally.
4. Publish with Power BI Pro/PPU unless qualifying capacity applies and workspace
   `Contributor` or higher.
5. Use `Member` or `Admin` only for app publication or access management.
6. Configure an
   [on-premises data gateway](https://learn.microsoft.com/data-integration/gateway/service-gateway-onprem)
   for scheduled refresh from local or UNC paths.
7. For the SharePoint Value template, do not configure an on-premises gateway.
   Configure OAuth credentials for `SharePointSiteUrl` in the semantic model
   settings instead.

Publishing does not make `C:\CoworkValueData` cloud-accessible. SharePoint
refresh still requires a service credential that can read the configured site.

## Quick help

| You see | Likely cause | What to do |
| --- | --- | --- |
| Folder error during load | `DataFolderPath` is missing or inaccessible | Select an existing narrow folder and confirm local permission |
| SharePoint site or folder error | The site root is invalid, the folder is outside that site, or the signed-in account lacks access | Enter the site root in `SharePointSiteUrl`, paste the folder link in `SharePointFolderUrl`, and confirm read permission |
| No Cowork users | No valid Cowork `CopilotInteraction` rows | In V1.2, check either supported outer-column shape, JSON integrity, period, and `AppHost`; in earlier templates, check the five legacy headers |
| Optional file ignored | Filename/header contract failed | Use a preferred filename and exact required headers |
| Unexpected optional file selected | Multiple schema-valid files are under `DataFolderPath` | Keep one current working file per optional schema |
| Start Here says partial load | Usage loaded but no recognized Purview Cowork events | Confirm `Operations`/`Operation`, `UserIds`/`UserId`, valid `AuditData`, and a Cowork `AppHost` |
| Usage split or audit coverage blank | Usage export is absent, anonymized, or unmatched | Rename `User ID`, remove surrounding whitespace, and review the tenant concealment setting |
| Department visuals blank | Org file is absent, malformed, or unmatched | Confirm all ten exact headers and UPN overlap |
| Credits, utilization, or cost blank | Wrong report export, missing consumption file, or missing assumptions | Use Cost Management Consumption > Users, then select approved report inputs |
| Estimated value blank | No labor rate is selected | Select and document one labor rate |
| Model page says unavailable | Cowork audit data did not emit usable model names | Treat it as unavailable; do not infer a model |
| Service refresh fails for local files | Power BI Service cannot reach the local folder | Configure and map an on-premises gateway |
| Service refresh fails for SharePoint | The `SharePointSiteUrl` credential is missing or expired | Sign in to the SharePoint data source in semantic model settings |

## Security reminders

- Use temporary or just-in-time role assignments where available.
- Do not request Global Administrator for routine exports.
- Restrict raw and normalized exports to approved owners.
- Preserve raw files; transform only protected working copies.
- Record reporting windows, timestamps, filters, transformations, and assumptions.
- Apply the organization's required sensitivity label before sharing refreshed
  customer-data files.

Read [Security roles and access](docs/SECURITY_ROLES.md) and
[SECURITY.md](SECURITY.md) before connecting customer data.
