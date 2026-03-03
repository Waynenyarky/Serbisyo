# Serbisyo Mobile Backlog

Last updated: 2026-03-03

## Progress Snapshot
- Stories: 12
- Done: 4
- Partial: 3
- Not Started: 5
- Progress: 45.8%

Tracking scale:
- DONE = 1
- PARTIAL = 0.5
- NOT_STARTED = 0

## Developer Notes (code scan 2026-03-03)
- **Secure token storage:** ✅ Migrated auth storage to `flutter_secure_storage`.
- **Auth guard behavior:** ✅ `AuthGuard.requireLogin()` now supports clearing session + pending login message.
- **OAuth callback wiring:** ✅ Native Google sign-in wired using mobile ID token exchange endpoint.
- **.env handling:** `.env` is listed in assets; avoid bundling secrets. Ensure `.env` is in `.gitignore`, keep `.env.example` in repo, and update README setup steps accordingly.
- **401/global error handling:** ✅ API client routes 401 to centralized auth guard login flow.
- **OAuth integration verification:** ✅ Backend/mobile OAuth smoke rerun passed for endpoint behavior (`302` redirect path and expected `400`/`401` validation outcomes on mobile token endpoint).
- **Tests:** ⚠️ Current run covers existing widget test only. Add dedicated unit tests for `auth_storage`, `auth_guard`, and router redirect behavior next.

## Mobile Backlog

### Epic MB-E01: Authentication and Session UX
**Progress:** 2 Done / 0 Partial / 0 Not Started (2 stories) → **100.0%**

- **Feature MB-F01: Email/password and OAuth entry points**
  - **Story MB-S01** `[x] DONE`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S01
  - Update: Native Google sign-in is wired through backend mobile token exchange endpoint, auth contract parsing/storage refresh remains in place, auth context persists in secure storage, and OAuth endpoint integration checks passed on rerun.
  - Tasks:
    - Add OAuth button + loading/error states in auth screens. ✅
    - Extend auth provider/repository for OAuth endpoint. ✅
    - Persist token and role in secure storage. ✅

- **Feature MB-F02: Role-aware routing and guarded screens**
  - **Story MB-S02** `[x] DONE`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S02
  - Update: Router now enforces auth-only public routes (`/login`, `/signup`) and provider routes show forbidden state for unauthorized users.
  - Tasks:
    - Add route guards in app router. ✅
    - Update bottom navigation based on `is_customer` / `is_provider` / `is_admin`. ✅
    - Add forbidden-state component. ✅

### Epic MB-E02: Search and Discovery UX
**Progress:** 2 Done / 0 Partial / 0 Not Started (2 stories) → **100.0%**

- **Feature MB-F03: Search results and filters**
  - **Story MB-S03** `[x] DONE`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S03
  - Tasks:
    - Add filter chips and query state. ✅
    - Integrate paged results from services endpoint. ✅
    - Add skeleton loaders and retry action. ✅

- **Feature MB-F04: Nearest provider booking UI**
  - **Story MB-S04** `[x] DONE`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S04
  - Tasks:
    - Integrate location permission and coordinate capture. ✅
    - Build nearest-match CTA + candidate result view. ✅
    - Add unavailable fallback UI. ✅

### Epic MB-E03: Booking Flow UX
**Progress:** 0 Done / 1 Partial / 1 Not Started (2 stories) → **25.0%**

- **Feature MB-F05: Customer booking creation and tracking**
  - **Story MB-S05** `[-] PARTIAL`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S05
  - Tasks:
    - Implement booking form validation and submission.
    - Build booking detail timeline states.
    - Add cancellation and reschedule UX.

- **Feature MB-F06: Provider booking action center**
  - **Story MB-S06** `[ ] NOT_STARTED`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S06
  - Tasks:
    - Add provider booking action buttons and dialogs.
    - Sync booking list with action outcomes.
    - Show status-specific badges and alerts.

### Epic MB-E04: Payments and Policy UX
**Progress:** 0 Done / 0 Partial / 3 Not Started (3 stories) → **0.0%**

- **Feature MB-F07: In-app payment journey**
  - **Story MB-S07** `[ ] NOT_STARTED`
  - Priority: P0 | SP: 8 | Effort: L | Depends on: M-S07
  - Tasks:
    - Build payment summary and pay CTA.
    - Integrate gateway handoff/webview/deeplink callback.
    - Add failure recovery and receipt view.

- **Feature MB-F08: Messaging warning and compliance prompts**
  - **Story MB-S08** `[ ] NOT_STARTED`
  - Priority: P1 | SP: 3 | Effort: S | Depends on: M-S09
  - Tasks:
    - Add warning modal/banner component.
    - Handle backend moderation response codes.
    - Add UX copy variants per severity.

- **Feature MB-F09: Anti-cash policy education**
  - **Story MB-S09** `[ ] NOT_STARTED`
  - Priority: P1 | SP: 2 | Effort: S | Depends on: M-S08
  - Tasks:
    - Add reusable policy notice component.
    - Display notice in chat and checkout entry points.

### Epic MB-E05: Messaging and Ratings UX
**Progress:** 0 Done / 1 Partial / 1 Not Started (2 stories) → **25.0%**

- **Feature MB-F10: Booking-linked message threads**
  - **Story MB-S10** `[-] PARTIAL`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S09
  - Tasks:
    - Add optimistic message bubble states with `flagged` message rendering.
    - Add retry flow for failed sends.
    - Improve unread/thread sorting behavior.

- **Feature MB-F11: Ratings and reviews UI**
  - **Story MB-S11** `[ ] NOT_STARTED`
  - Priority: P1 | SP: 5 | Effort: M | Depends on: M-S10
  - Tasks:
    - Add post-completion review sheet.
    - Integrate create review API.
    - Refresh provider profile score display.

### Epic MB-E06: Demo Reliability UX
**Progress:** 0 Done / 1 Partial / 0 Not Started (1 story) → **50.0%**

- **Feature MB-F12: Network and cold-start resilience**
  - **Story MB-S12** `[-] PARTIAL`
  - Priority: P0 | SP: 5 | Effort: M | Depends on: M-S13
  - Tasks:
    - Add global retry policy for API client.
    - Add idempotency-safe UI lock states on critical actions.
    - Add offline/no-network fallback messaging.

## Mobile P0 Queue
- `MB-S01` `[x] DONE`
- `MB-S02` `[x] DONE`
- `MB-S03` `[x] DONE`
- `MB-S04` `[x] DONE`
- `MB-S05` `[-] PARTIAL`
- `MB-S06` `[ ] NOT_STARTED`
- `MB-S07` `[ ] NOT_STARTED`
- `MB-S10` `[-] PARTIAL`
- `MB-S12` `[-] PARTIAL`
