# Serbisyo Mobile

Flutter mobile app for Serbisyo.

## Implemented mobile integration updates

- Integrated backend BE-S01 auth contract updates.
- Auth parsing is unified for `login`, `register`, and `me` responses using `{ user, token }`.
- Stored user auth context now includes:
	- `role`
	- `is_customer`, `is_provider`, `is_admin`
	- `admin_role`
- Current user provider now refreshes from `GET /api/auth/me` (with storage fallback).
- Provider/customer UI gates now rely on boolean-safe role checks (not role string only).
- Login screen Google button currently shows an informational message because mobile OAuth callback wiring is not yet implemented, even though backend Google OAuth endpoints are ready.

## Prerequisites

- Flutter SDK `3.10.x` (Dart `^3.10.3`)
- Running backend API (see `../backend/README.md`)

## Setup

1. Install dependencies:
	 ```bash
	 flutter pub get
	 ```

2. Create `mobile/.env` with:
	 ```env
	 API_BASE_URL=http://localhost:3000
	 ```

3. Start the app:
	 ```bash
	 flutter run
	 ```

## API base URL notes

- Windows host + local backend: `http://localhost:3000`
- Android emulator to host machine: `http://10.0.2.2:3000`
- Physical device on same network: `http://YOUR_PC_IP:3000`

## Validation commands

- Static analysis:
	```bash
	flutter analyze
	```
- Tests:
	```bash
	flutter test
	```
