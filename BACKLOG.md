# Serbisyo Agile Backlog Index

Last updated: 2026-03-02  
Source of truth: `PRD.md`, `DB_SCHEMA.md`

## 0) Project Progress Rollup

### Tracking Scale (Simple)
- `DONE = 1`
- `PARTIAL = 0.5`
- `NOT_STARTED = 0`

### Formulas
- **Backend %** = `((BE_done) + (0.5 × BE_partial)) / BE_total × 100`
- **Mobile %** = `((MB_done) + (0.5 × MB_partial)) / MB_total × 100`
- **Master %** = `((M_done) + (0.5 × M_partial)) / M_total × 100`
- **Overall Project %** = `(Backend score + Mobile score + Master score) / (BE_total + MB_total + M_total) × 100`

### Baseline Snapshot (2026-03-02)
- **Backend:** 2 Done / 4 Partial / 9 Not Started (15 total) → **26.7%**
- **Mobile:** 0 Done / 7 Partial / 5 Not Started (12 total) → **29.2%**
- **Master:** 0 Done / 8 Partial / 5 Not Started (13 total) → **30.8%**
- **Whole Project:** 2 Done / 19 Partial / 19 Not Started (40 total) → **28.8%**

### Status Legend
- `[x] DONE` = acceptance criteria implemented end-to-end
- `[-] PARTIAL` = foundation exists, but acceptance criteria still incomplete
- `[ ] NOT_STARTED` = no meaningful implementation yet

---

## 1) Split Backlog Files

- **Master backlog:** [MASTER_BACKLOG.md](MASTER_BACKLOG.md)
- **Backend backlog:** [BACKEND_BACKLOG.md](BACKEND_BACKLOG.md)
- **Mobile backlog:** [MOBILE_BACKLOG.md](MOBILE_BACKLOG.md)

### Sync Checklist

| Backlog File | Last Updated | Updated By | Status Recomputed | Notes |
|---|---|---|---|---|
| [MASTER_BACKLOG.md](MASTER_BACKLOG.md) | 2026-03-02 | _TBD_ | Yes | Initial split created |
| [BACKEND_BACKLOG.md](BACKEND_BACKLOG.md) | 2026-03-02 | GitHub Copilot | Yes | Updated BE-E01 to done, refreshed BE-E08 partial notes |
| [MOBILE_BACKLOG.md](MOBILE_BACKLOG.md) | 2026-03-02 | _TBD_ | Yes | Initial split created |
| [BACKLOG.md](BACKLOG.md) (rollup/index) | 2026-03-02 | GitHub Copilot | Yes | Recomputed backend and overall progress |

### Update Workflow (Quick)
1. Update story statuses in track files (`MASTER_BACKLOG.md`, `BACKEND_BACKLOG.md`, `MOBILE_BACKLOG.md`).
2. Recompute each file's Done/Partial/Not Started totals and %.
3. Update rollup totals and overall % in `BACKLOG.md`.
4. Refresh the **Sync Checklist** row dates/owners/notes.

---

## 2) Shared Backlog Model

### Hierarchy
- **Initiative** → **Epic** → **Feature** → **User Story** → **Task**

### Priority Model
- **P0** = MVP demo-critical (must be complete)
- **P1** = MVP strengthening (should be complete)
- **P2** = Post-MVP / investor follow-up (can defer)

### Estimation Model
- **Story Points (SP)**: 1, 2, 3, 5, 8, 13
- **Effort**: S / M / L

### Schema Alignment Rules (`DB_SCHEMA.md`)
- `Users` is multi-role via booleans (`is_customer`, `is_provider`, `is_admin`) plus optional `admin_role`.
- `Bookings` is the transactional anchor and includes `payment_id` + `payment_method`.
- `Payments`, `Messages`, `Reviews`, and `Admin Logs` are first-class entities.
- Messaging is booking-linked (`booking_id`, `sender_id`, `receiver_id`) with `flagged` moderation state.

### Definition of Done (Global)
- Acceptance criteria met and validated.
- API and app behavior aligned to contract.
- Basic error states handled.
- Logging/monitoring hooks added where applicable.
- Security and role access checks implemented for changed paths.

---

## 3) Key Dependencies and Risks Register

- **External integrations:** OAuth provider setup, payment gateway sandbox credentials, optional maps/geocoding service.
- **Policy quality risk:** message filtering false positives can reduce usability.
- **Infra risk:** cold starts from free tier can affect demo timing.
- **Security risk:** payment/webhook validation and RBAC gaps are high impact.
- **Data quality risk:** rating and booking status integrity must be transaction-safe.

---

## 4) DB Schema ↔ Backlog Traceability Matrix

| DB Entity (`DB_SCHEMA.md`) | Core Fields/Constraints | Master Stories | Mobile Stories | Backend Stories | Notes |
|---|---|---|---|---|---|
| `Users` | Multi-role booleans (`is_customer`, `is_provider`, `is_admin`), `admin_role`, profile/address/coordinates, `ratings` | M-S01, M-S02, M-S04, M-S10, M-S11 | MB-S01, MB-S02, MB-S04, MB-S11 | BE-S01, BE-S02, BE-S04, BE-S11, BE-S12, BE-S15 | Role switching and provider activation must preserve single-account model. |
| `Services` | `name`, `description`, `category`, `base_price` | M-S03, M-S05, M-S11 | MB-S03, MB-S05 | BE-S03, BE-S12, BE-S15 | Search/filter and booking contracts must share stable service identifiers. |
| `Bookings` | `customer_id`, `provider_id`, `service_id`, statuses (`pending/accepted/rejected/completed/cancelled`), schedule/location, payment linkage | M-S04, M-S05, M-S06, M-S07 | MB-S04, MB-S05, MB-S06, MB-S07 | BE-S04, BE-S05, BE-S06, BE-S07, BE-S15 | Booking is transactional anchor for messaging, reviews, and payments. |
| `Payments` | `booking_id`, `amount`, `currency`, `method`, `status`, `transaction_reference` | M-S07, M-S12 | MB-S07, MB-S09 | BE-S07, BE-S08, BE-S13, BE-S15 | Idempotency and reconciliation are required for demo-safe payment behavior. |
| `Messages` | Booking-linked (`booking_id`), sender/receiver refs, `content`, `flagged` | M-S08, M-S09, M-S11 | MB-S08, MB-S10 | BE-S09, BE-S10, BE-S12, BE-S15 | Moderation decisions must map to `flagged` and admin review flows. |
| `Reviews` | One review per booking intent, `rating` 1-5, provider/customer linkage | M-S10, M-S12 | MB-S11 | BE-S11, BE-S13, BE-S15 | Provider aggregate score updates through `Users.ratings`. |
| `Admin Logs` | `action`, `performed_by`, `details`, timestamp | M-S11, M-S12 | (N/A) | BE-S12, BE-S13, BE-S15 | Required for auditable moderation and finance actions. |

### Coverage Check
- All schema entities map to at least one Master and one Backend story.
- Mobile backlog intentionally has no direct CRUD for `Admin Logs`; admin observability remains backend/API scoped for MVP.

---

## 5) Backlog Maintenance Rules

- Update `MASTER_BACKLOG.md`, `BACKEND_BACKLOG.md`, and `MOBILE_BACKLOG.md` first.
- Recalculate rollup percentages in this index after story status changes.
- Every story must link to one feature and one owner section (Master/Mobile/Backend).
- Re-estimate stories if scope changes by >20%.
- Keep P0 queue demo-aligned; avoid adding new epics before core P0 closure.
- Keep this file as the canonical project-level status index.
