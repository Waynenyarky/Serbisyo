# Serbisyo Backend Backlog

Last updated: 2026-03-03

## Progress Snapshot
- Stories: 15
- Done: 4
- Partial: 3
- Not Started: 8
- Progress: 36.7%

Tracking scale:
- DONE = 1
- PARTIAL = 0.5
- NOT_STARTED = 0

## Backend Backlog

### Epic BE-E01: Auth, Roles, and Access Control
**Progress:** 2 Done / 0 Partial / 0 Not Started (2 stories) → **100.0%**

- **Feature BE-F01: OAuth + JWT auth contracts**
  - **Story BE-S01** `[x] DONE`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S01
  - Acceptance: OAuth provider strategy + callback implemented; auth payload normalized to `{ user, token }` and user provider linkage added.
  - Tasks:
    - Add OAuth provider strategy and callback endpoint. ✅
    - Normalize auth response payload. ✅
    - Add provider account linkage in `Users` model using role booleans + optional `admin_role`. ✅

- **Feature BE-F02: Permission matrix enforcement**
  - **Story BE-S02** `[x] DONE`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S02
  - Acceptance: Explicit permission matrix added, route guards audited/updated, and forbidden access audit events persisted.
  - Tasks:
    - Expand RBAC middleware with role scopes. ✅
    - Audit route files for missing role guards. ✅
    - Add forbidden access audit event. ✅

### Epic BE-E02: Search and Matching Engine
**Progress:** 2 Done / 0 Partial / 0 Not Started (2 stories) → **100.0%**

- **Feature BE-F03: Search query relevance**
  - **Story BE-S03** `[x] DONE`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S03
  - Update: `/services` now supports validated query defaults + pagination (`page`, `limit`), provider/category filters, and relevance-aware sorting for search terms.
  - Tasks:
    - Extend `/services` and provider lookup query params. ✅
    - Add query validation and defaults. ✅
    - Add indexes for service/category search fields. ✅

- **Feature BE-F04: Nearest provider selection service**
  - **Story BE-S04** `[x] DONE`
  - Priority: P0 | SP: 13 | Effort: L | Depends on: M-S04
  - Update: Added nearest-provider geo query endpoint with distance-first ranking and rating tie-break plus explicit fallback contract.
  - Tasks:
    - Use `Users.address.coordinates` for provider/customer geolocation queries. ✅
    - Implement geo query + ranking function. ✅
    - Add no-candidate fallback response contract. ✅

### Epic BE-E03: Booking Domain and Orchestration
**Progress:** 0 Done / 0 Partial / 2 Not Started (2 stories) → **0.0%**

- **Feature BE-F05: Booking state machine hardening**
  - **Story BE-S05** `[ ] NOT_STARTED`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S05
  - Tasks:
    - Add transition rules for `pending`, `accepted`, `rejected`, `completed`, `cancelled`.
    - Add schedule overlap checks.
    - Emit booking state change events/logs.

- **Feature BE-F06: Provider booking actions API**
  - **Story BE-S06** `[ ] NOT_STARTED`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S06
  - Tasks:
    - Add provider action routes.
    - Persist action metadata.
    - Return timeline-friendly payload for mobile.

### Epic BE-E04: Payments and Policy Compliance
**Progress:** 0 Done / 0 Partial / 2 Not Started (2 stories) → **0.0%**

- **Feature BE-F07: Payment gateway backend integration**
  - **Story BE-S07** `[ ] NOT_STARTED`
  - Priority: P0 | SP: 13 | Effort: L | Depends on: M-S07
  - Tasks:
    - Add payment create endpoint persisting `Payments`.
    - Add webhook handler with signature check.
    - Add idempotency key handling and retries.

- **Feature BE-F08: Payment ledger and reconciliation**
  - **Story BE-S08** `[ ] NOT_STARTED`
  - Priority: P1 | SP: 8 | Effort: L | Depends on: M-S07
  - Tasks:
    - Add/extend `Payments` indexes and reconciliation fields.
    - Implement reconciliation endpoint/job.
    - Add admin-facing transaction filters.

### Epic BE-E05: Messaging Moderation and Trust Safety
**Progress:** 0 Done / 1 Partial / 2 Not Started (3 stories) → **16.7%**

- **Feature BE-F09: Booking-thread messaging controls**
  - **Story BE-S09** `[-] PARTIAL`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S09
  - Tasks:
    - Validate booking-user membership for every booking-linked message.
    - Persist moderation metadata on each `Messages` record.
    - Add send throttling to reduce abuse.

- **Feature BE-F10: Prohibited-topic detection and enforcement**
  - **Story BE-S10** `[ ] NOT_STARTED`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S08
  - Tasks:
    - Build configurable rule list and matcher.
    - Return moderation decision in send response.
    - Add flagged-content review query endpoints.

- **Feature BE-F11: Reviews domain and provider rating aggregation**
  - **Story BE-S11** `[ ] NOT_STARTED`
  - Priority: P1 | SP: 5 | Effort: M | Depends on: M-S10
  - Tasks:
    - Add `Reviews` model and booking uniqueness constraint.
    - Add create/list review endpoints.
    - Update provider aggregate in `Users.ratings`.

### Epic BE-E06: Superadmin Operations and Analytics
**Progress:** 0 Done / 0 Partial / 2 Not Started (2 stories) → **0.0%**

- **Feature BE-F12: Admin management APIs**
  - **Story BE-S12** `[ ] NOT_STARTED`
  - Priority: P1 | SP: 8 | Effort: L | Depends on: M-S11
  - Tasks:
    - Add `/admin` route group with superadmin guard.
    - Implement list/filter/update actions.
    - Add `Admin Logs` writes for every admin action.

- **Feature BE-F13: KPI and reporting endpoints**
  - **Story BE-S13** `[ ] NOT_STARTED`
  - Priority: P1 | SP: 5 | Effort: M | Depends on: M-S12
  - Tasks:
    - Implement aggregation pipeline queries.
    - Add parameter validation and bounds.
    - Document KPI formulas in API docs.

### Epic BE-E07: Reliability and Demo Operations
**Progress:** 0 Done / 1 Partial / 0 Not Started (1 story) → **50.0%**

- **Feature BE-F14: Health, observability, and load confidence**
  - **Story BE-S14** `[-] PARTIAL`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S13
  - Tasks:
    - Add `/health` endpoint with dependency checks.
    - Add structured request/response logging for core flows.
    - Create lightweight load test script and report template.

### Epic BE-E08: DB Schema Conformance
**Progress:** 0 Done / 1 Partial / 0 Not Started (1 story) → **50.0%**

- **Feature BE-F15: Model and migration alignment with `DB_SCHEMA.md`**
  - **Story BE-S15** `[-] PARTIAL`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S02, M-S05, M-S07, M-S09, M-S10, M-S11
  - Update: Seeding now backfills DB_SCHEMA mirror fields for Users/Services and ensures required schema collections exist before reseed.
  - Tasks:
    - Build field-mapping matrix old-model-to-new-schema.
    - Add migration scripts/backfill for renamed or split entities. ✅ (seed-time backfill in place)
    - Validate indexes and unique constraints from schema requirements.

## Backend P0 Queue
- `BE-S01` `[x] DONE`
- `BE-S02` `[x] DONE`
- `BE-S03` `[x] DONE`
- `BE-S04` `[x] DONE`
- `BE-S05` `[ ] NOT_STARTED`
- `BE-S06` `[ ] NOT_STARTED`
- `BE-S07` `[ ] NOT_STARTED`
- `BE-S09` `[-] PARTIAL`
- `BE-S10` `[ ] NOT_STARTED`
- `BE-S14` `[-] PARTIAL`
- `BE-S15` `[-] PARTIAL`
