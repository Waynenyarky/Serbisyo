# Serbisyo Agile Backlog

Last updated: 2026-03-02  
Source of truth: `PRD.md`, `DB_SCHEMA.md`

## 1) Backlog Model

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
- Messaging is **booking-linked** (`booking_id`, `sender_id`, `receiver_id`) with `flagged` moderation state.

### Definition of Done (global)
- Acceptance criteria met and validated.
- API and app behavior aligned to contract.
- Basic error states handled.
- Logging/monitoring hooks added where applicable.
- Security and role access checks implemented for changed paths.

---

## 2) Master Backlog (Product-Level)

## Initiative M-I01: Trust, Identity, and Access

### Epic M-E01: Authentication & Role Governance

#### Feature M-F01: Multi-method account access (JWT + OAuth)
- **Story M-S01**: As a user, I can sign up/login with email+password and OAuth provider so I can access the app quickly.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Owner: Fullstack
  - Dependencies: BE-S01, MB-S01
  - Acceptance Criteria:
    - Email/password and one OAuth provider work end-to-end.
    - Access token refresh/session persistence works on mobile restart.
    - Role is assigned and visible in `/auth/me` response.
  - Tasks:
    - Define auth contract for password and OAuth paths.
    - Implement OAuth callback/token exchange on backend.
    - Add mobile OAuth flow and token persistence.
    - Add role claim verification in protected routes.

#### Feature M-F02: Role-based experience partitioning
- **Story M-S02**: As customer/provider/superadmin, I only see actions and data for my role.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Owner: Fullstack
  - Dependencies: BE-S02, MB-S02
  - Acceptance Criteria:
    - Unauthorized route attempts return `403`.
    - Mobile hides role-incompatible actions.
    - Superadmin endpoints inaccessible to non-admin users.
    - Multi-role accounts are supported using `is_customer`, `is_provider`, `is_admin`, and optional `admin_role`.
  - Tasks:
    - Create permission matrix mapped to `Users` role booleans + `admin_role`.
    - Enforce RBAC middleware by route group.
    - Implement role-aware navigation guards in app.

## Initiative M-I02: Marketplace Discovery and Matching

### Epic M-E02: Provider Search & Nearest Matching

#### Feature M-F03: Service/provider discovery
- **Story M-S03**: As a customer, I can search services/providers by keyword/category and see relevant results.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Owner: Fullstack
  - Dependencies: BE-S03, MB-S03
  - Acceptance Criteria:
    - Search supports category and text filters.
    - Result cards show price/rating/location summary.
    - Empty and error states are handled.
  - Tasks:
    - Align search query params and response schema.
    - Add mobile result states and pagination/load-more.
    - Instrument search usage metrics.

#### Feature M-F04: Nearest available provider booking option
- **Story M-S04**: As a customer, I can request nearest available provider and get a matched candidate list.
  - Priority: P0
  - SP: 13
  - Effort: L
  - Owner: Fullstack
  - Dependencies: BE-S04, MB-S04
  - Acceptance Criteria:
    - Customer can enable location and request nearest match.
    - Matching considers distance + availability + service capability.
    - Fallback message appears when no provider is available.
  - Tasks:
    - Define geolocation payload and distance calculation approach.
    - Use `Users.address.coordinates` and provider availability checks.
    - Build mobile location permission and nearest-match UX.

## Initiative M-I03: Booking and Fulfillment

### Epic M-E03: Booking Lifecycle

#### Feature M-F05: Specific provider booking flow
- **Story M-S05**: As a customer, I can book a selected provider with date/time and service details.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Owner: Fullstack
  - Dependencies: BE-S05, MB-S05
  - Acceptance Criteria:
    - Booking form validates schedule/service inputs.
    - Booking status lifecycle exists (`pending/accepted/rejected/completed/cancelled`).
    - Customer and provider both see booking details.
  - Tasks:
    - Normalize booking status transitions.
    - Add schedule conflict validation.
    - Persist `payment_method` on booking creation/update.
    - Add booking detail and timeline UI.

#### Feature M-F06: Provider booking operations
- **Story M-S06**: As a provider, I can accept/reject/manage bookings and schedule availability.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Owner: Fullstack
  - Dependencies: BE-S06, MB-S06
  - Acceptance Criteria:
    - Provider can accept/reject with reason.
    - Calendar conflicts are prevented.
    - Customer receives booking state updates.
  - Tasks:
    - Add provider booking action endpoints.
    - Expose provider schedule management on mobile.
    - Push in-app notifications for booking updates.

## Initiative M-I04: Payments and Transaction Integrity

### Epic M-E04: In-app Payments

#### Feature M-F07: Payment gateway integration
- **Story M-S07**: As a customer, I can pay inside the app and receive payment confirmation.
  - Priority: P0
  - SP: 13
  - Effort: L
  - Owner: Fullstack
  - Dependencies: BE-S07, MB-S07
  - Acceptance Criteria:
    - Sandbox payment flow succeeds for at least one gateway.
    - Payment record (`Payments`) is created with `booking_id`, `method`, `status`, and `transaction_reference`.
    - Booking `payment_id` is linked and booking marked as paid only after verified callback/webhook.
    - Failed and cancelled payments are recoverable.
  - Tasks:
    - Implement payment create endpoint producing persisted `Payments` record.
    - Validate webhook signatures and idempotency.
    - Build mobile payment handoff + result handling.

#### Feature M-F08: Anti-cash policy enforcement
- **Story M-S08**: As a platform owner, I can enforce in-app-only transactions and flag policy violations.
  - Priority: P1
  - SP: 5
  - Effort: M
  - Owner: Fullstack
  - Dependencies: BE-S10, MB-S09
  - Acceptance Criteria:
    - Policy warning appears when prohibited terms are used.
    - Violations are logged and visible to superadmin.
    - Repeat violations can trigger temporary communication restriction.
  - Tasks:
    - Define violation severity rules.
    - Add user-facing warning flow.
    - Add admin review queue for flagged events.

## Initiative M-I05: Communication, Safety, and Quality

### Epic M-E05: Messaging + Reviews

#### Feature M-F09: Moderated in-app messaging
- **Story M-S09**: As a user, I can message inside booking threads while prohibited-topic filters protect platform policy.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Owner: Fullstack
  - Dependencies: BE-S09, MB-S08
  - Acceptance Criteria:
    - Booking-linked messaging works for booking participants only.
    - Rule-based prohibited-topic detection is applied in real time.
    - `Messages.flagged` is set for prohibited content and policy action is applied.
  - Tasks:
    - Finalize prohibited term dictionary and normalization.
    - Persist `booking_id`, `sender_id`, `receiver_id`, and `flagged` on messages.
    - Surface warning UI in message composer.

#### Feature M-F10: Ratings and reviews
- **Story M-S10**: As a customer, I can rate/review providers after completed bookings.
  - Priority: P1
  - SP: 5
  - Effort: M
  - Owner: Fullstack
  - Dependencies: BE-S11, MB-S10
  - Acceptance Criteria:
    - One review per completed booking enforced.
    - Provider aggregate rating updates correctly.
    - Abuse/report workflow available to superadmin.
  - Tasks:
    - Add `Reviews` schema (`booking_id`, `customer_id`, `provider_id`, `rating`, `comment`) and booking linkage validation.
    - Build post-completion review prompt UI.
    - Update `Users.ratings` aggregate for provider accounts.

## Initiative M-I06: Admin Visibility and Control

### Epic M-E06: Superadmin Dashboard and Analytics

#### Feature M-F11: Operations management
- **Story M-S11**: As a superadmin, I can manage users, providers, services, and policy violations.
  - Priority: P1
  - SP: 8
  - Effort: L
  - Owner: Backend
  - Dependencies: BE-S12
  - Acceptance Criteria:
    - Superadmin can search/filter users and providers.
    - Account status actions (active/suspended) are audited.
    - Flagged messages and payment violations are actionable.
  - Tasks:
    - Build admin endpoints for user/provider moderation.
    - Add `Admin Logs` model and API responses.
    - Provide management-ready export/report data.

#### Feature M-F12: Revenue and usage analytics
- **Story M-S12**: As a stakeholder, I can view core KPIs for bookings, GMV, conversion, and provider activity.
  - Priority: P1
  - SP: 5
  - Effort: M
  - Owner: Backend
  - Dependencies: BE-S13
  - Acceptance Criteria:
    - KPI endpoint returns daily and weekly aggregates.
    - Filters exist by date range and service category.
    - Metrics definitions are documented and consistent.
  - Tasks:
    - Implement analytics aggregation pipeline.
    - Add KPI definitions and response contract docs.
    - Add access control + query guardrails.

## Initiative M-I07: Demo Readiness, Reliability, and Scale

### Epic M-E07: Investor-demo hardening

#### Feature M-F13: Demo quality gate
- **Story M-S13**: As product team, we can run a stable investor demo even with free-tier constraints.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Owner: Fullstack
  - Dependencies: BE-S14, MB-S11
  - Acceptance Criteria:
    - Smoke tests cover critical path (register → search → book → pay → message).
    - Fallback UX handles cold starts/network latency.
    - Demo runbook and scripted scenarios are documented.
  - Tasks:
    - Create demo smoke checklist and scripts.
    - Add backend health/status and warmup strategy.
    - Add mobile retry and degraded-state handling.

---

## 3) Mobile Backlog

## Epic MB-E01: Authentication and Session UX

### Feature MB-F01: Email/password and OAuth entry points
- **Story MB-S01**: Implement unified login/register with OAuth option.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S01
  - Acceptance Criteria:
    - Login and registration forms validate before submit.
    - OAuth flow returns token and profile payload.
    - Session persists after app restart.
  - Tasks:
    - Add OAuth button + loading/error states in auth screens.
    - Extend auth provider/repository for OAuth endpoint.
    - Persist token and role in secure storage.

### Feature MB-F02: Role-aware routing and guarded screens
- **Story MB-S02**: Enforce role-specific navigation and action availability.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S02
  - Acceptance Criteria:
    - Non-provider cannot access provider management screens.
    - Role mismatch shows graceful denial UI.
    - Multi-role users can switch experiences without re-authentication.
  - Tasks:
    - Add route guards in app router.
    - Update bottom navigation based on `is_customer` / `is_provider` / `is_admin`.
    - Add forbidden-state component.

## Epic MB-E02: Search and Discovery UX

### Feature MB-F03: Search results and filters
- **Story MB-S03**: Deliver search with category and keyword filters.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S03
  - Acceptance Criteria:
    - Search requests debounce and cancel stale queries.
    - Empty/error states are user friendly.
  - Tasks:
    - Add filter chips and query state.
    - Integrate paged results from services endpoint.
    - Add skeleton loaders and retry action.

### Feature MB-F04: Nearest provider booking UI
- **Story MB-S04**: Add nearest-provider flow from service detail.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S04
  - Acceptance Criteria:
    - Location permission request and rationale are clear.
    - User can choose from nearest candidates list.
  - Tasks:
    - Integrate location permission and coordinate capture.
    - Build nearest-match CTA + candidate result view.
    - Add unavailable fallback UI.

## Epic MB-E03: Booking Flow UX

### Feature MB-F05: Customer booking creation and tracking
- **Story MB-S05**: Build customer booking form and booking timeline view.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S05
  - Acceptance Criteria:
    - Required fields and schedule constraints validated.
    - Booking timeline updates without full app reload.
  - Tasks:
    - Implement booking form validation and submission.
    - Build booking detail timeline states.
    - Add cancellation and reschedule UX.

### Feature MB-F06: Provider booking action center
- **Story MB-S06**: Enable provider accept/reject and schedule actions.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S06
  - Acceptance Criteria:
    - Provider can perform accept/reject with reason.
    - Status changes reflect instantly in list/detail.
  - Tasks:
    - Add provider booking action buttons and dialogs.
    - Sync booking list with action outcomes.
    - Show status-specific badges and alerts.

## Epic MB-E04: Payments and Policy UX

### Feature MB-F07: In-app payment journey
- **Story MB-S07**: Implement payment initiation, completion, and failure handling UI.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S07
  - Acceptance Criteria:
    - Payment success updates booking state to paid.
    - Failure shows retry and alternative options.
  - Tasks:
    - Build payment summary and pay CTA.
    - Integrate gateway handoff/webview/deeplink callback.
    - Add failure recovery and receipt view.

### Feature MB-F08: Messaging warning and compliance prompts
- **Story MB-S08**: Show prohibited-topic warnings inside chat compose/send flow.
  - Priority: P1
  - SP: 3
  - Effort: S
  - Depends on: M-S09
  - Acceptance Criteria:
    - Warning appears before sending disallowed content.
    - Message send result reflects moderated status.
  - Tasks:
    - Add warning modal/banner component.
    - Handle backend moderation response codes.
    - Add UX copy variants per severity.

### Feature MB-F09: Anti-cash policy education
- **Story MB-S09**: Add in-app policy notices for transaction safety.
  - Priority: P1
  - SP: 2
  - Effort: S
  - Depends on: M-S08
  - Acceptance Criteria:
    - Policy copy appears at payment and chat contexts.
    - Users can acknowledge and continue.
  - Tasks:
    - Add reusable policy notice component.
    - Display notice in chat and checkout entry points.

## Epic MB-E05: Messaging and Ratings UX

### Feature MB-F10: Booking-linked message threads
- **Story MB-S10**: Improve thread/message UX for real-time-like conversations.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S09
  - Acceptance Criteria:
    - Booking-linked conversation list and detail are consistent after send.
    - Pending/send-failed states are visible.
  - Tasks:
    - Add optimistic message bubble states with `flagged` message rendering.
    - Add retry flow for failed sends.
    - Improve unread/thread sorting behavior.

### Feature MB-F11: Ratings and reviews UI
- **Story MB-S11**: Enable review submission after completed booking.
  - Priority: P1
  - SP: 5
  - Effort: M
  - Depends on: M-S10
  - Acceptance Criteria:
    - Review prompt appears only once per completed booking.
    - Provider profile shows updated aggregate rating.
  - Tasks:
    - Add post-completion review sheet.
    - Integrate create review API.
    - Refresh provider profile score display.

## Epic MB-E06: Demo Reliability UX

### Feature MB-F12: Network and cold-start resilience
- **Story MB-S12**: Add resilient loading/retry/degraded states for demo reliability.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S13
  - Acceptance Criteria:
    - Cold-start delays communicate status to user.
    - Retries avoid duplicate booking/payment submissions.
  - Tasks:
    - Add global retry policy for API client.
    - Add idempotency-safe UI lock states on critical actions.
    - Add offline/no-network fallback messaging.

---

## 4) Backend Backlog

## Epic BE-E01: Auth, Roles, and Access Control

### Feature BE-F01: OAuth + JWT auth contracts
- **Story BE-S01**: Add OAuth exchange endpoints and unify token/session behavior.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S01
  - Acceptance Criteria:
    - OAuth callback/exchange endpoint returns same auth contract as login.
    - Existing JWT middleware supports OAuth-created users.
  - Tasks:
    - Add OAuth provider strategy and callback endpoint.
    - Normalize auth response payload.
    - Add provider account linkage in `Users` model using role booleans and optional `admin_role`.

### Feature BE-F02: Permission matrix enforcement
- **Story BE-S02**: Enforce route-level RBAC for customer/provider/superadmin.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S02
  - Acceptance Criteria:
    - All protected endpoints mapped to explicit permissions based on `is_customer` / `is_provider` / `is_admin` + `admin_role`.
    - Unauthorized requests are denied and audited.
  - Tasks:
    - Expand RBAC middleware with role scopes.
    - Audit route files for missing role guards.
    - Add forbidden access audit event.

## Epic BE-E02: Search and Matching Engine

### Feature BE-F03: Search query relevance
- **Story BE-S03**: Improve services/providers search endpoints for filterable discovery.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S03
  - Acceptance Criteria:
    - Supports category + keyword + availability filter.
    - Stable response shape for mobile cards.
  - Tasks:
    - Extend `/services` and provider lookup query params.
    - Add query validation and defaults.
    - Add indexes for service/category search fields.

### Feature BE-F04: Nearest provider selection service
- **Story BE-S04**: Implement nearest available provider matching endpoint.
  - Priority: P0
  - SP: 13
  - Effort: L
  - Depends on: M-S04
  - Acceptance Criteria:
    - Endpoint ranks candidates by distance then availability.
    - Supports service-type filtering and radius cap.
  - Tasks:
    - Use `Users.address.coordinates` for provider/customer geolocation queries.
    - Implement geo query + ranking function.
    - Add no-candidate fallback response contract.

## Epic BE-E03: Booking Domain and Orchestration

### Feature BE-F05: Booking state machine hardening
- **Story BE-S05**: Enforce valid booking transitions and conflict prevention.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S05
  - Acceptance Criteria:
    - Invalid status transitions are rejected.
    - Provider schedule conflicts are blocked.
  - Tasks:
    - Add transition rules for `pending`, `accepted`, `rejected`, `completed`, `cancelled`.
    - Add schedule overlap checks.
    - Emit booking state change events/logs.

### Feature BE-F06: Provider booking actions API
- **Story BE-S06**: Add provider action endpoints (accept/reject/reschedule).
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S06
  - Acceptance Criteria:
    - Provider-only action routes secured.
    - Action reason and timestamps persisted.
  - Tasks:
    - Add provider action routes.
    - Persist action metadata.
    - Return timeline-friendly payload for mobile.

## Epic BE-E04: Payments and Policy Compliance

### Feature BE-F07: Payment gateway backend integration
- **Story BE-S07**: Integrate sandbox payment provider with webhook verification.
  - Priority: P0
  - SP: 13
  - Effort: L
  - Depends on: M-S07
  - Acceptance Criteria:
    - Payment create/confirm/cancel endpoints work in sandbox.
    - Webhook validation prevents spoofed updates.
    - `Bookings.payment_id` and `Bookings.payment_method` are set consistently and idempotently.
  - Tasks:
    - Add payment create endpoint persisting `Payments` (`booking_id`, `amount`, `currency`, `method`, `status`, `transaction_reference`).
    - Add webhook handler with signature check.
    - Add idempotency key handling and retries.

### Feature BE-F08: Payment ledger and reconciliation
- **Story BE-S08**: Record transactions and reconcile booking/payment states.
  - Priority: P1
  - SP: 8
  - Effort: L
  - Depends on: M-S07
  - Acceptance Criteria:
    - `Payments` records include status history transitions (`pending`, `paid`, `refunded`).
    - Reconciliation job fixes drifted states.
  - Tasks:
    - Add/extend `Payments` indexes and reconciliation fields.
    - Implement reconciliation endpoint/job.
    - Add admin-facing transaction filters.

## Epic BE-E05: Messaging Moderation and Trust Safety

### Feature BE-F09: Booking-thread messaging controls
- **Story BE-S09**: Restrict messaging to booking participants and improve message integrity.
  - Priority: P0
  - SP: 5
  - Effort: M
  - Depends on: M-S09
  - Acceptance Criteria:
    - Non-participants cannot access/send in thread.
    - Message write path stores `booking_id`, `sender_id`, `receiver_id`, and `flagged` status.
  - Tasks:
    - Validate booking-user membership for every booking-linked message.
    - Persist moderation metadata on each `Messages` record.
    - Add send throttling to reduce abuse.

### Feature BE-F10: Prohibited-topic detection and enforcement
- **Story BE-S10**: Add prohibited keyword/rule engine for anti-off-platform behavior.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S08
  - Acceptance Criteria:
    - Message content normalized and scanned against rule set.
    - Rules support warning/block/escalate actions.
    - Flags are queryable by superadmin.
  - Tasks:
    - Build configurable rule list and matcher.
    - Return moderation decision in send response.
    - Add flagged-content review query endpoints.

### Feature BE-F11: Reviews domain and provider rating aggregation
- **Story BE-S11**: Implement review endpoints tied to completed bookings.
  - Priority: P1
  - SP: 5
  - Effort: M
  - Depends on: M-S10
  - Acceptance Criteria:
    - Review creation allowed once per completed booking.
    - Provider rating aggregates update atomically.
  - Tasks:
    - Add `Reviews` model and booking uniqueness constraint.
    - Add create/list review endpoints.
    - Update provider aggregate in `Users.ratings`.

## Epic BE-E06: Superadmin Operations and Analytics

### Feature BE-F12: Admin management APIs
- **Story BE-S12**: Expose superadmin APIs for users/providers/services/flags moderation.
  - Priority: P1
  - SP: 8
  - Effort: L
  - Depends on: M-S11
  - Acceptance Criteria:
    - Admin can list/filter/update user/provider status.
    - Suspensions and policy actions are audited.
  - Tasks:
    - Add `/admin` route group with superadmin guard.
    - Implement list/filter/update actions.
    - Add `Admin Logs` writes for every admin action.

## Epic BE-E08: DB Schema Conformance

### Feature BE-F15: Model and migration alignment with `DB_SCHEMA.md`
- **Story BE-S15**: Align backend models and persistence layer with approved schema entities and field names.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S02, M-S05, M-S07, M-S09, M-S10, M-S11
  - Acceptance Criteria:
    - `Users`, `Services`, `Bookings`, `Payments`, `Messages`, `Reviews`, `Admin Logs` exist with required fields.
    - Legacy model naming mismatches are mapped/migrated without data loss.
    - Foreign-key/reference integrity is enforced at application level.
  - Tasks:
    - Build field-mapping matrix old-model-to-new-schema.
    - Add migration scripts/backfill for renamed or split entities.
    - Validate indexes and unique constraints from schema requirements.

### Feature BE-F13: KPI and reporting endpoints
- **Story BE-S13**: Implement analytics endpoints for bookings, revenue, and activity.
  - Priority: P1
  - SP: 5
  - Effort: M
  - Depends on: M-S12
  - Acceptance Criteria:
    - Returns KPI aggregates for day/week/month.
    - Supports filtering by category and role.
  - Tasks:
    - Implement aggregation pipeline queries.
    - Add parameter validation and bounds.
    - Document KPI formulas in API docs.

## Epic BE-E07: Reliability and Demo Operations

### Feature BE-F14: Health, observability, and load confidence
- **Story BE-S14**: Improve API observability and resilience for demo constraints.
  - Priority: P0
  - SP: 8
  - Effort: L
  - Depends on: M-S13
  - Acceptance Criteria:
    - Health endpoint reports DB and service dependencies.
    - Request logs include traceable IDs for critical flows.
    - Baseline load test profile documented for 500-demo-user target.
  - Tasks:
    - Add `/health` endpoint with dependency checks.
    - Add structured request/response logging for core flows.
    - Create lightweight load test script and report template.

---

## 5) Priority-Ordered MVP Delivery Queue (No Sprint Mapping)

### P0 (Execute First)
- M-S01, M-S02, M-S03, M-S04, M-S05, M-S06, M-S07, M-S09, M-S13
- Mobile focus: MB-S01, MB-S02, MB-S03, MB-S04, MB-S05, MB-S06, MB-S07, MB-S10, MB-S12
- Backend focus: BE-S01, BE-S02, BE-S03, BE-S04, BE-S05, BE-S06, BE-S07, BE-S09, BE-S10, BE-S14, BE-S15

### P1 (Execute Second)
- M-S08, M-S10, M-S11, M-S12
- Mobile focus: MB-S08, MB-S09, MB-S11
- Backend focus: BE-S08, BE-S11, BE-S12, BE-S13

### P2 (Optional / Investor Follow-up)
- UX polish variants and advanced analytics slices after P0/P1 completion.

---

## 6) Key Dependencies and Risks Register

- **External integrations**: OAuth provider setup, payment gateway sandbox credentials, optional maps/geocoding service.
- **Policy quality risk**: Message filtering false positives can reduce usability.
- **Infra risk**: Cold starts from free tier can affect demo timing.
- **Security risk**: Payment/webhook validation and RBAC gaps are high impact.
- **Data quality risk**: Rating and booking status integrity must be transaction-safe.

## 7) DB Schema ↔ Backlog Traceability Matrix

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
- All schema entities have at least one Master and one Backend story mapping.
- Mobile backlog intentionally has no direct CRUD for `Admin Logs`; admin observability remains backend/API scoped for MVP.
- BE-S15 is the conformance umbrella story for migration, field mapping, and integrity validation.

## 8) Backlog Maintenance Rules

- Every story must link to one feature and one owner section (Master/Mobile/Backend).
- Re-estimate stories if scope changes by >20%.
- Keep P0 queue small and demo-aligned; avoid introducing new epics before P0 closure.
- Promote P2 items only when P0 acceptance criteria are fully met.