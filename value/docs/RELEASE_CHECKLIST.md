# Cowork Value V1 Testing release checklist

## Report

- [x] PBIR validation reports zero errors.
- [x] All 31 canvas bookmark actions resolve to internal bookmark IDs.
- [x] All 31 bookmarks are limited to their target visuals.
- [x] All 12 pages have working filter drawers and visible Fluent red close controls.
- [x] All seven report view transitions preserve an open filter drawer.
- [x] Value Calculator and Action Assumptions remain isolated through repeated round trips.
- [x] Billing mode and all four related cost inputs synchronize between Value
  Calculator and Value vs Cost.
- [x] Credit-Priced, License-Included, Prepaid, Hybrid, and Monthly Committed
  modes pass exact-PBIT DAX validation.
- [x] The template opens with only the required `DataFolderPath` prompt.
- [x] The bundled synthetic sample refreshes the report.

## Security and portability

- [x] PBIT contains no imported customer data.
- [x] PBIT contains no `SecurityBindings` stream or content-type override.
- [x] PBIP source contains no `.pbi` local state or user-profile paths.
- [x] PBIT retains the tenant Public sensitivity label without encryption.
- [x] Public label metadata remains after the machine-bound security stream is
  removed.

## Exact package

- [x] Version is `1.1.0-testing`.
- [x] SHA-256 is `c7b1a722c672cbf65d9fb4a66bea4dfa7c17ca0e70c3df4ba04a8e49a35176b6`.
- [x] Package size is `692,164` bytes.
- [x] Filename is `Cowork Value V1 Testing.pbit`.
- [x] The exact sanitized PBIT passed 41 synchronized-control interaction
  checks and the complete billing-mode DAX matrix.

## Repository

- [x] Existing remote `main` has a dated rollback reference.
- [x] Documentation describes the one-folder setup and classification behavior.
- [x] Unrelated working-tree changes are excluded from the release.
- [x] Final outbound publication approval is received.
