# Serbisyo Backend

Node.js + Express + MongoDB backend for the Serbisyo mobile app.

## Implemented updates (BE-E01 + seed/schema work)

- JWT auth contract normalized to `{ user, token }` for `register`, `login`, and `me`.
- Google OAuth (Google-only) wired with:
   - `GET /api/auth/oauth/google`
   - `GET /api/auth/oauth/google/callback`
- User role model aligned to booleans:
   - `is_customer`, `is_provider`, `is_admin`
   - optional `admin_role`
   - legacy role reference flow replaced by boolean role derivation.
- RBAC middleware upgraded to permission-based checks (`requirePermission`) with role derivation and fallback role gates (`requireRole`).
- Forbidden access is persisted to `AdminLog` (`action: forbidden_access`) with method/path/user-agent/context.
- Seed process aligned to `DB_SCHEMA.md` through seed-time backfills and collection checks:
   - ensures required collections exist before reseed (including `payments`, `reviews`, `messages`, `adminlogs`)
   - backfills user mirror fields (e.g., `password_hash`, compatibility name/address/rating fields)
   - backfills service mirror fields (e.g., `name`, `category`, `base_price`)
   - host seed emails are normalized to lowercase.

## Setup

1. Install MongoDB locally or use MongoDB Atlas.
2. Install dependencies:
    ```bash
    npm install
    ```
3. Create/update `.env` and set:
    - `MONGODB_URI` (default local: `mongodb://localhost:27017/serbisyo`)
    - `PORT` (default: `3000`)
    - `JWT_SECRET`
    - `GOOGLE_CLIENT_ID` (required for Google OAuth)
    - `GOOGLE_CLIENT_SECRET` (required for Google OAuth)
    - `GOOGLE_CALLBACK_URL` (default behavior expects `/api/auth/oauth/google/callback`)

## Run

- Start API:
   ```bash
   npm run dev
   ```
- Seed categories/services/hosts + schema-alignment backfills:
   ```bash
   npm run seed
   ```
- Seed hosts only:
   ```bash
   npm run seed:hosts
   ```

Base URL: `http://localhost:3000` (all routes under `/api`).

## Auth response contract

```json
{
   "user": {
      "id": "...",
      "email": "...",
      "fullName": "...",
      "role": "customer|provider|admin",
      "is_customer": true,
      "is_provider": false,
      "is_admin": false,
      "admin_role": null
   },
   "token": "..."
}
```

## Key endpoints

- `POST /api/auth/register` (email, password, fullName, role=`customer|provider`)
- `POST /api/auth/login`
- `GET /api/auth/me` (Bearer token)
- `GET /api/auth/oauth/google?role=customer|provider`
- `GET /api/auth/oauth/google/callback`
- `GET /api/categories`
- `GET /api/services` (`categoryId`, `q` supported)
- `GET /api/services/:id`
- `GET /api/bookings`, `GET /api/bookings/:id`, `POST /api/bookings`
- `GET /api/messages/threads`, `GET /api/messages/threads/:id`, `POST /api/messages/threads/:id/messages`
