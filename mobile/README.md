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
- Login screen now supports native Google Sign-In using ID token exchange via backend `POST /api/auth/oauth/google/mobile`.
- OAuth integration smoke checks were validated for backend endpoint behavior (`302` for browser OAuth start and expected `400`/`401` validation responses for token endpoint edge cases).

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
	 GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
	 ```

3. Start the app:
	 ```bash
	 flutter run
	 ```

## OAuth setup (Google Cloud + mobile env)

1. In Google Cloud Console, configure OAuth consent screen and add your account as a test user (if app is in testing mode).
2. Create OAuth Client ID type **Web application** and use that client ID in:
	- `mobile/.env` as `GOOGLE_WEB_CLIENT_ID`
	- `backend/.env` as `GOOGLE_CLIENT_ID`
3. Create OAuth Client ID type **Android** with:
	- package name: `com.serbisyo.serbisyo`
	- SHA1: `4D:F7:B2:17:48:1F:B7:91:6F:49:78:AC:B2:EE:DD:90:9B:C9:55:F3`
4. Verify backend callback URI is allowed in the Web client:
	- `http://localhost:3000/api/auth/oauth/google/callback`
	- optionally `http://localhost:3001/api/auth/oauth/google/callback`
5. Rebuild app after changes:
	```bash
	flutter clean
	flutter pub get
	flutter run
	```

## API base URL notes

- Windows host + local backend: `http://localhost:3000`
- Android emulator to host machine: `http://10.0.2.2:3000`
- Physical device on same network: `http://YOUR_PC_IP:3000`
- If backend auto-falls back to another port (for example `3001` when `3000` is in use), update `API_BASE_URL` accordingly.

## Google Sign-In (Android) troubleshooting

If login fails with `PlatformException(sign_in_failed, ... ApiException: 10 ...)`, Google OAuth Android client settings do not match the running app.

- Android package name (from Gradle): `com.serbisyo.serbisyo`
- Debug SHA1 (from `./gradlew signingReport`): `4D:F7:B2:17:48:1F:B7:91:6F:49:78:AC:B2:EE:DD:90:9B:C9:55:F3`

Required fix in Google Cloud Console:
- Create/update OAuth Client ID type **Android** with:
	- package name: `com.serbisyo.serbisyo`
	- SHA1: `4D:F7:B2:17:48:1F:B7:91:6F:49:78:AC:B2:EE:DD:90:9B:C9:55:F3`
- Keep OAuth Client ID type **Web** for backend token verification and set it in:
	- `mobile/.env` as `GOOGLE_WEB_CLIENT_ID`
	- `backend/.env` as `GOOGLE_CLIENT_ID`
- If consent screen is in testing mode, add your Google account to test users.
- Reinstall app (or run `flutter clean` then `flutter run`) after OAuth changes.

## Validation commands

- Static analysis:
	```bash
	flutter analyze
	```
- Tests:
	```bash
	flutter test
	```
