# Serbisyo Master Backlog

Last updated: 2026-03-02

## Progress Snapshot
- Stories: 13
- Done: 0
- Partial: 8
- Not Started: 5
- Progress: 30.8%

Tracking scale:
- DONE = 1
- PARTIAL = 0.5
- NOT_STARTED = 0

## Master Backlog (Cross-Track Summary)

> Master view is intentionally summary-only for readability. Implementation detail lives in `BACKEND_BACKLOG.md` and `MOBILE_BACKLOG.md`.

### Initiative M-I01: Trust, Identity, and Access
**Progress:** 0 Done / 2 Partial / 0 Not Started (2 stories) → **50.0%**

- **Epic M-E01: Authentication & Role Governance**
  - **Feature M-F01**
    - `M-S01` `[-] PARTIAL` (depends on `BE-S01`, `MB-S01`) — Backend OAuth + normalized auth contract completed; cross-track closure still pending mobile OAuth parity/refresh decisions.
  - **Feature M-F02**
    - `M-S02` `[-] PARTIAL` (depends on `BE-S02`, `MB-S02`) — Backend permission matrix + forbidden access audit completed; cross-track role governance validation remains.

### Initiative M-I02: Marketplace Discovery and Matching
**Progress:** 0 Done / 2 Partial / 0 Not Started (2 stories) → **50.0%**

- **Epic M-E02: Provider Search & Nearest Matching**
  - **Feature M-F03**
    - `M-S03` `[-] PARTIAL` (depends on `BE-S03`, `MB-S03`) — search/filter works, advanced behaviors pending.
  - **Feature M-F04**
    - `M-S04` `[-] PARTIAL` (depends on `BE-S04`, `MB-S04`) — nearest entry exists in UI but full matching pipeline is missing.

### Initiative M-I03: Booking and Fulfillment
**Progress:** 0 Done / 1 Partial / 1 Not Started (2 stories) → **25.0%**

- **Epic M-E03: Booking Lifecycle**
  - **Feature M-F05**
    - `M-S05` `[-] PARTIAL` (depends on `BE-S05`, `MB-S05`) — booking creation exists; lifecycle hardening pending.
  - **Feature M-F06**
    - `M-S06` `[ ] NOT_STARTED` (depends on `BE-S06`, `MB-S06`) — provider booking action center not complete.

### Initiative M-I04: Payments and Transaction Integrity
**Progress:** 0 Done / 1 Partial / 1 Not Started (2 stories) → **25.0%**

- **Epic M-E04: In-app Payments**
  - **Feature M-F07**
    - `M-S07` `[-] PARTIAL` (depends on `BE-S07`, `MB-S07`) — payment step exists in UX, real transaction flow missing.
  - **Feature M-F08**
    - `M-S08` `[ ] NOT_STARTED` (depends on `BE-S10`, `MB-S09`) — anti-cash enforcement not implemented.

### Initiative M-I05: Communication, Safety, and Quality
**Progress:** 0 Done / 1 Partial / 1 Not Started (2 stories) → **25.0%**

- **Epic M-E05: Messaging + Reviews**
  - **Feature M-F09**
    - `M-S09` `[-] PARTIAL` (depends on `BE-S09`, `MB-S10`) — messaging works; moderation policy path incomplete.
  - **Feature M-F10**
    - `M-S10` `[ ] NOT_STARTED` (depends on `BE-S11`, `MB-S11`) — reviews flow not implemented.

### Initiative M-I06: Admin Visibility and Control
**Progress:** 0 Done / 0 Partial / 2 Not Started (2 stories) → **0.0%**

- **Epic M-E06: Superadmin Dashboard and Analytics**
  - **Feature M-F11**
    - `M-S11` `[ ] NOT_STARTED` (depends on `BE-S12`) — admin management not implemented.
  - **Feature M-F12**
    - `M-S12` `[ ] NOT_STARTED` (depends on `BE-S13`) — KPI analytics not implemented.

### Initiative M-I07: Demo Readiness, Reliability, and Scale
**Progress:** 0 Done / 1 Partial / 0 Not Started (1 story) → **50.0%**

- **Epic M-E07: Investor-demo hardening**
  - **Feature M-F13**
    - `M-S13` `[-] PARTIAL` (depends on `BE-S14`, `MB-S12`) — basic health/retry exists, full hardening pending.
