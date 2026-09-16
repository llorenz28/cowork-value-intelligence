# Split-template public release checklist

## Report

- [x] `powerbi-report-author validate` reports zero errors.
- [x] Source-boundary validation passes.
- [x] All 9 Adoption pages and all 12 Value pages render.
- [x] Navigation, bookmarks, filter drawers, and synchronized assumptions work.
- [x] Value passes Credit-Priced, License-Included, Prepaid, Hybrid, and Monthly
  Committed billing-mode checks.
- [x] No clipping, overlap, error visual, or inaccessible control remains.
- [x] Every metric has a plain-language title, alt text, definition, and status.

## Sample data

- [x] Generator is deterministic.
- [x] Every user email address ends in `@example.com`.
- [x] No production domain, user, GUID, URL, or customer name is present.
- [x] `_VERIFY.txt` matches generated CSV hashes.
- [x] Sample package populates both split templates.
- [x] Synthetic model labels are visibly marked synthetic.

## Security and privacy

- [x] No secrets, tokens, certificates, or credentials.
- [x] No `.pbi` local state or DPAPI security binding.
- [x] No absolute user-profile path in committed source.
- [x] No customer CSV, screenshot, or hidden archive.
- [x] PBIT contains no imported customer data.
- [x] Both PBITs retain the Public sensitivity label without encryption.
- [x] Both PBITs contain no machine-bound `SecurityBindings`.

## Documentation and media

- [x] README setup steps reproduce the report on a clean machine.
- [x] Source schemas and permissions are accurate.
- [x] Security-role guidance separates CSV export, tenant policy, billing, and Power BI publication duties.
- [x] Customer setup includes the official Cowork `User ID` to `UserPrincipalName` header mapping.
- [x] The Adoption Metric Guide and Value Interpretation Guide cover the active
  split reports.
- [x] Storyboard PPTX passes structural QA, retains identical visible slide text
  and media after path sanitization, and contains no sensitivity-label metadata.
- [x] Video is 1920x1080, 30 fps, H.264/AAC, narrated, and transcript-aligned.
- [x] Video follows the adoption-to-enablement story and uses cost only as supporting context.
- [x] SRT subtitles are monotonic, complete, and aligned with the transcript.
- [x] Images and media show only synthetic data.
- [x] All relative links resolve.

## GitHub

- [ ] Public repository history and active release tree audited before visibility change.
- [x] Repository name and description approved.
- [x] Exact publication manifest previewed.
- [x] Final outbound publication confirmation received.
- [x] Existing private remote state has a dated rollback reference.
- [ ] Public branch protection, security reporting, and access settings reviewed.
