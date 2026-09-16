# Public testing publication

- **Repository:** `llorenz28/cowork-value-intelligence`
- **Repository visibility:** Public
- **Release status:** Testing; not a billing system, financial audit, product
  SLA, or basis for personnel action
- **Active PBITs:**
  - `adoption/Cowork Adoption Intelligence v2 Testing.pbit`
  - `value/Cowork Value V1 Testing.pbit`
- **PBIT classification:** Both contain no imported data or machine-bound
  security binding. Both carry the tenant Public sensitivity label without
  encryption.
- **Versions:** Cowork Adoption Intelligence `2.0.1-testing`; Cowork Value
  `1.1.0-testing`
- **Publication model:** retain the existing repository and all of its history
  as a private archive; publish this audited tree from a new clean history under
  the active repository name. Never make the archive public or push its history
  to the public repository.

The legacy combined `Cowork Value Intelligence V1.0 In Testing.pbit` is not in
the active public tree. An exact copy is retained locally outside the repository.
Its editable PBIP source and historical validation/media remain for reference.

The public repository includes the two testing PBITs, editable PBIP sources,
deterministic fabricated sample data, setup and security guidance, report
captures, interpretation assets, and validation evidence. Customer exports,
credentials, tenant URLs, and identifiable customer screenshots must never be
committed to any branch, pull request, or issue.

The Adoption package exposes one required `DataFolderPath` prompt, includes
Cowork Champions and its Metric Guide definitions, and carries the tenant Public
sensitivity label without encryption. The Value package also exposes one
required `DataFolderPath` prompt, carries the Public label without encryption,
keeps all 31 bookmarks target-only, and supports five synchronized billing modes.

Public availability does not change the data-handling requirements in
`SECURITY.md` or grant rights beyond `LICENSE.md`.
