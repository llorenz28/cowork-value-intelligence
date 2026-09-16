# Security roles and access

This page defines the least-privilege access needed to collect CSV inputs for
both Cowork testing templates. Data-export roles, tenant configuration roles,
Finance approval, and Power BI publication are separate responsibilities.

## What this release does not require

The current release reads approved CSV exports. Do not request these solely for
the templates:

- an app registration, client secret, or certificate
- Microsoft Graph application permissions
- Defender Advanced Hunting permissions
- Global Administrator for routine collection

## Least-privilege matrix

| Task | Recommended minimum | Broader or different role only when needed | Important boundary |
| --- | --- | --- | --- |
| Search and export Purview audit records | Purview **Audit Reader** role group | **Audit Manager** only to manage audit settings | Audit Reader grants `View-Only Audit Logs`; portal assignment is separate from Exchange audit-cmdlet access |
| Export identifiable Cowork usage details | `Reports Reader` | Another supported usage-report role already held by the owner | `Usage Summary Reports Reader` and User Experience Success Manager omit user details; tenant concealment still applies |
| View Cost Management user consumption and use the available report export | `AI Reader` | Global Reader, License Administrator, or another supported reader role | Use **Copilot > Cost Management > Consumption > Users**; Microsoft does not document a separate export permission |
| Manage spending policies, limits, or alerts | `AI Administrator` or `License Administrator` | None for ordinary policy management | Not required for read-only report collection |
| Add or change a billing method | `Billing Administrator` | `Global Administrator` | Billing setup is not routine template operation |
| View/export the Copilot Credits usage report | `Reports Reader` | Another supported usage-report role | This export is **not compatible** with the templates' Cost Management schema |
| Reveal concealed identities in usage reports | Existing `Global Administrator` makes a tenant-wide policy decision | None | Do not grant Global Administrator to the report operator |
| Download Entra users | Microsoft documents both standard and admin users as supported | Existing authorized Identity/HR owner | Tenant policy still governs access; the raw export does not contain every template org field |
| Open and refresh in Power BI Desktop | No tenant role | None | Approved local file access is sufficient |
| Publish to a Power BI workspace | Pro/PPU unless qualifying capacity applies, plus workspace `Contributor` | `Member` or `Admin` | Broader workspace roles are for app/access management |
| Schedule refresh from local or UNC files | Workspace write role plus gateway-connection access | Gateway administrator for gateway setup | Gateway permissions are separate from workspace roles |

## Why these are the recommended roles

### Purview

Microsoft's Purview **Audit Reader** role group is the read-only collection
role. It grants `View-Only Audit Logs`, allowing search and export without
permission to enable, disable, or otherwise manage auditing. Audit Manager is
broader.

### Cowork usage

`Reports Reader` can access usage reports with user-level detail when the
tenant's reporting privacy setting allows it. Read-only summary roles omit the
identity needed for joins. No usage-report role overrides the tenant-wide
concealment setting.

### Cost Management

`AI Reader` is the read-only starting role for consumption dashboards and
reports. AI Administrator and License Administrator can manage spending
policies, limits, and alerts, so do not request them when export is the only
task.

If an `AI Reader` can view the report but the export control is unavailable,
confirm the tenant UI and policy with the existing cost owner before requesting
a broader role.

The separate **Reports > Usage > Microsoft Copilot > Credits** report is visible
to usage-report roles, but its CSV lacks the monthly limit, monthly used,
license, session, and utilization fields required by the model. Access to that
report alone does not light up the templates' cost and ROI pages.

### Organization and identity

Prefer a file from an existing authorized HR or Identity owner. Microsoft states
that both standard and admin users can download Entra user lists, but the
organization's privacy and data-governance policy remains authoritative. An
Entra download must be normalized and supplemented for the ten-column
organization contract.

## Data-owner handoff

| Owner | Responsibility |
| --- | --- |
| Purview owner | Defines the approved UTC window, exports raw audit results, checks export limits, and transfers them securely |
| Microsoft 365 reports owner | Exports Cowork usage details and records **Last updated** |
| Copilot cost owner | Exports Cost Management **Consumption > Users** and records the billing context |
| HR/Identity owner | Supplies only approved organization and identity fields |
| Finance owner | Approves labor rate, currency, billing model, commitment assumptions, and rate per credit |
| Power BI owner | Loads working copies, validates source status, labels the refreshed file, and publishes |

No single operator needs all tenant roles when authorized data owners provide the
exports.

## Copy-ready access request

```text
Subject: Least-privilege exports for Cowork reporting

Please provide these CSV exports for the agreed reporting period:

1. Microsoft Purview Audit
   - Collector: authorized Compliance/Purview owner
   - Role group: Audit Reader
   - Operation: CopilotInteraction
   - Deliverable: complete raw Audit Search CSV export(s), unchanged
   - Record: UTC window, export time, and whether the query exceeded an export limit

2. Microsoft 365 admin center > Copilot > Cowork > Usage
   - Collector: authorized Microsoft 365 reports owner
   - Recommended role: Reports Reader
   - Deliverable: Cowork usage details CSV and Last updated timestamp
   - Identity requirement: user details must be available under approved tenant privacy policy

3. Microsoft 365 admin center > Copilot > Cost Management > Consumption > Users
   - Collector: authorized Copilot cost owner
   - Recommended read-only role: AI Reader
   - Deliverable: user-level consumption CSV
   - Do not substitute Reports > Usage > Microsoft Copilot > Credits

4. Optional organization/identity export
   - Collector: existing authorized HR/Identity owner
   - Deliverable: only the approved fields documented in DATA_SETUP_START_HERE.md

No app registration, secret, Graph application permission, Defender permission,
or Global Administrator assignment is requested for routine report operation.
```

## Assignment and review controls

- Prefer existing data owners over new assignments.
- Use time-bound or just-in-time assignment where available.
- Remove temporary access after delivery.
- Review access for every reporting cycle.
- Do not combine export and report-consumer access by default.
- Record who exported each source, when, for what window, and under which
  approved purpose.

## Microsoft references

- [Purview Audit Reader and Audit Manager](https://learn.microsoft.com/purview/audit-get-started#step-2-assign-permissions-to-search-the-audit-log)
- [Purview search requirements and retention](https://learn.microsoft.com/purview/audit-search#before-you-search-the-audit-log)
- [Purview export limits](https://learn.microsoft.com/purview/audit-log-export-records)
- [Cowork usage access and export](https://learn.microsoft.com/microsoft-365/admin/activity-reports/cowork-usage-report?view=o365-worldwide)
- [Usage-report roles and identity concealment](https://learn.microsoft.com/microsoft-365/admin/activity-reports/activity-reports?view=o365-worldwide#before-you-begin)
- [Cost Management role requirements](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-manage-copilot-credits#role-requirements)
- [Copilot Credits usage-report fields](https://learn.microsoft.com/microsoft-365/admin/activity-reports/microsoft-365-copilot-credits?view=o365-worldwide)
- [Entra user-list download](https://learn.microsoft.com/entra/identity/users/users-bulk-download)
- [Power BI workspace roles](https://learn.microsoft.com/power-bi/collaborate-share/service-roles-new-workspaces#workspace-roles)
- [On-premises data gateway](https://learn.microsoft.com/data-integration/gateway/service-gateway-onprem)

Role names, navigation, licensing, and export schemas can change. Confirm the
linked Microsoft guidance, the actual CSV headers, and tenant policy before each
production collection.
