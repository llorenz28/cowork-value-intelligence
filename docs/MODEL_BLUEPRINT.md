# Cowork Value Intelligence model blueprint

## Analytical flow

```text
Purview audit CSVs
  -> parse CopilotInteraction JSON
  -> keep AppHost = cowork
  -> detect users
  -> group records into task threads
  -> expand skills and resources
  -> map skills to work categories
  -> combine with usage, organization, and consumption exports
  -> calculate observed, derived, modeled, and allocated measures
```

## Source ownership

| Domain | Source of truth |
| --- | --- |
| Event timestamp, thread, skill, resource, model field | Purview audit |
| Reported total tasks and scheduled split | Cowork usage export |
| Department and business unit | Customer Entra/HR export |
| Credits, allowance, sessions, recency | Consumption export |
| Labor rate, contract rate, commitments | Customer-selected report inputs |

The aggregate usage export must never manufacture event-grain activity.

## Principal tables

- `Dim_User` — dynamically detected Cowork users with optional identity enrichment.
- `Dim_UserOrg` — matching organization rows only.
- `Fact_CopilotAuditRaw` — parsed, deduplicated audit records.
- `Fact_CoworkThread` — one row per Cowork thread.
- `Bridge_CoworkPlugin` — one row per observed plugin invocation.
- `Bridge_CoworkResource` — one row per accessed resource.
- `Fact_Tasks` — user/category/date/model task aggregates.
- `Fact_CoworkUsage` — reported or audit-derived user aggregates.
- `Fact_Consumption` — matched consumption rows.
- `Dim_ModelProvider` — observed model labels or an unavailable placeholder.

## Value calculation

```text
Assisted hours
  = SUM(category tasks * typical minutes saved) / 60

Estimated value
  = Assisted hours * selected loaded labor rate

Contracted cost
  = Observed credits * selected effective credit rate

ROI
  = Estimated value / effective platform cost
```

Typical minutes are documented planning assumptions, not measured employee time.

## Model allocation limitation

The current model allocates total credits and cost across model/category cells
using task or value share. That enables scenario comparison but does not establish
actual per-model consumption. A defensible “cheapest model” recommendation needs
a model-specific source containing credits or billed cost at compatible grain.

## Portability

- Parameters live in `definition\expressions.tmdl`.
- `.pbi\localSettings.json` is machine-local and excluded.
- Source paths in the committed PBIP use `C:\CoworkValueIntelligence\...` as
  portable examples and must be replaced locally.
- Optional sources degrade to explicit unavailable states.
