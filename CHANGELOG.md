# Changelog

## Cowork Value media and interpretation refresh - 2026-09-21

- Replaced the obsolete 13-page media captures with the current 11
  viewer-facing pages plus the hidden Action Assumptions page.
- Added a version-neutral 24-slide interpretation guide aligned to the current
  value, cost, allocation, right-sizing, skill, model, and glossary contract.
- Retained the established Value carousel as the repository preview.
- Rebuilt the narrated walkthrough with synchronized subtitles, transcript,
  and timeline.

## Cowork Value V1.3 repository promotion - 2026-09-18

- Promoted the validated V1.3 local-folder and SharePoint-folder templates as
  the current Cowork Value downloads.
- Moved the previously published V1 local and V1.2 SharePoint PBITs to
  `value/backups/2026-09-18-pre-v1.3-friendly-skills/` with their original
  SHA-256 hashes preserved.

## Cowork Value V1.3 Friendly Skills - 2026-09-17

- Added separately named local-folder and SharePoint-folder Value templates with
  readable fallback labels for previously unseen technical skill/tool IDs.
- Preserved curated friendly names as the first choice and converted raw MCP,
  snake_case, kebab-case, and camelCase fallback identifiers without changing
  their mapping status.
- Preserved all 12 pages, 426 visuals, 31 target-only bookmarks, categories,
  task counts, time estimates, billing logic, and value calculations.
- Preserved the original V1 local and V1.2 SharePoint PBIT files in the dated
  rollback folder and added a deterministic friendly-name derivative builder.

## Cowork Value V1 SharePoint edition - 2026-09-16

- Added `Cowork Value V1 SharePoint Testing.pbit` as a separate template; the
  existing local-folder template remains unchanged.
- Added recursive SharePoint-folder discovery through one static
  `SharePoint.Files` site connector.
- Added support for direct folder URLs, path-bearing SharePoint `/:f:/r/`
  links, and `AllItems.aspx?id=...` folder links, with a clear error for opaque
  token-only sharing links.
- Preserved the Value report pages, measures, relationships, bookmarks,
  Public sensitivity metadata, and data-free package.

## Cowork Value V1 1.1.0 - 2026-09-15

- Added synchronized Billing Mode, Rate per Credit, Prepaid Credits, Prepaid
  Rate per Credit, and Monthly Committed Credits inputs to Value Calculator and
  Value vs Cost.
- Added Credit-Priced, License-Included, Prepaid, Hybrid, and Monthly Committed
  billing modes with explicit overage and allocation behavior.
- Added missing-input guidance for prepaid and commitment scenarios and
  expanded the Cost & ROI glossary.
- Re-exported the data-free Value PBIT with the Public sensitivity label and no
  machine-bound `SecurityBindings`.
- Reopened the exact distributable PBIT and passed all 41 synchronized-control
  interaction checks plus the complete billing-mode DAX matrix.

## Cowork Adoption Intelligence 2.0.1 - 2026-09-14

- Rebalanced the Cowork Champions page into a single seven-category row.
- Aligned the candidate table and department coverage panels and removed unused
  lower-left whitespace with a filter-aware selection-basis callout.
- Increased candidate-table row space so all default Top-10% candidates display
  without clipping.
- Added concise Champions category labels so every tile remains readable.
- Preserved the Public sensitivity label, one-folder setup, and all champion
  calculations and interactions.
- Renamed the active PBIT to `Cowork Adoption Intelligence v2 Testing.pbit`.
- Renamed the Value PBIT to `Cowork Value V1 Testing.pbit`, removed the legacy
  combined PBIT from the active tree, and prepared the repository for public
  testing access.

## Cowork Adoption Intelligence 2.0.0 - 2026-09-14

- Added a ninth visible **Cowork Champions** page after User Maturity.
- Added a category lens that recalculates potential champion evidence and
  department coverage from observed Cowork task threads.
- Added a transparent 0-100 evidence score using category activity (40%),
  active-week consistency (35%), and delegation maturity (25%).
- Added Top 5%, Top 10%, and Top 20% candidate tiers, an exact three-task and
  two-week eligibility floor, deterministic tie-breaking, and small-cohort
  guidance.
- Added a ranked candidate table, department coverage view, enablement guidance,
  and an interpretation boundary that prohibits employee-performance use.
- Added the Champions definitions to the Adoption Metric Guide and a Start Here
  navigation button.
- Preserved the single `DataFolderPath` prompt and removed imported data and
  Desktop-only security bindings from the distributable PBIT.
- Renamed the distributable template to `Cowork Adoption Intelligence v2.pbit`
  and retained the tenant Public sensitivity label on the unprotected,
  data-free package.

## Cowork Value V1 1.0.0 - 2026-09-12

- Added the focused Cowork Value V1 report, editable PBIP source, and portable
  PBIT under `value/`.
- Simplified template setup to one required `DataFolderPath` prompt with
  recursive discovery for supported Purview, usage, organization, identity,
  and consumption CSV exports.
- Added filter drawers to all 12 pages and made every close control visible
  with a Fluent red X, outline, and pale-red surface.
- Limited all 31 bookmarks to their target visuals so filters remain stable
  through all seven report view transitions.
- Removed imported data and the Desktop-only security binding from the
  distributable PBIT.

## Cowork Adoption Intelligence 1.0.0 - 2026-09-11

- Added the focused Cowork Adoption Intelligence report and portable PBIT.
- Corrected 24 filter-button bindings so all 48 canvas bookmark actions resolve
  to internal bookmark IDs.
- Simplified template setup to one required `DataFolderPath` prompt with
  recursive discovery for supported Purview, usage, organization, consumption,
  and identity CSV exports.
- Added the matching deterministic synthetic sample package and setup guidance.
- Removed the Desktop-only security binding from the distributable PBIT.

## 1.0.0-in-testing - 2026-09-07

- Added the 13-page Cowork Value Intelligence Power BI report.
- Added deterministic synthetic sample data with `@example.com` identities.
- Added a complete setup guide, interpretation guide, model blueprint, and
  release checklist.
- Added sample-populated screenshots, interpretation storyboard, transcript,
  and narrated walkthrough.
- Added source-boundary, privacy, and release verification tooling.
- Added a portable PBIT sanitizer that removes machine-bound Desktop security
  bindings while preserving the report and semantic-model schema.
- Added a sample-first customer setup flow, exact Cowork export header mapping,
  least-privilege security role matrix, owner handoffs, validation checkpoints,
  and local-source gateway guidance.
- Rebuilt the walkthrough as a 1080p leadership story centered on adoption,
  delegated work, workflow maturity, champions, enablement, and transparent
  value assumptions; consumption remains supporting context.
- Reframed the walkthrough and top-level repository message around the data-free
  customer template and approved organization exports.
- Preserved model attribution as source-dependent and model cost as an allocated
  estimate rather than a billing claim.
