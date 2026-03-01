# Serbisyo

Home services booking platform (Airbnb-inspired).

## Run the app

### 1. Backend (MongoDB + Node)

```bash
cd backend
npm install
# Set MONGODB_URI in .env (default: mongodb://localhost:27017/serbisyo)
npm run seed    # seed categories and services
npm run dev     # start API on http://localhost:3000
```

See [backend/README.md](backend/README.md) for API details.

### 2. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

- **Windows / same machine**: `API_BASE_URL=http://localhost:3000`
- **Android emulator**: `API_BASE_URL=http://10.0.2.2:3000`
- **Physical device (same network)**: `API_BASE_URL=http://YOUR_PC_IP:3000`

Log in or create an account in the app; categories and services come from the backend. Bookings and messages require a logged-in user.
