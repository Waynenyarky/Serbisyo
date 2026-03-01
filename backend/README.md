# Serbisyo Backend

Node.js + Express API with MongoDB for the Serbisyo mobile app.

## Setup

1. **MongoDB**: Install [MongoDB](https://www.mongodb.com/try/download/community) or use [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) and set the connection string in `.env`.

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment**: Copy `.env.example` to `.env` and set:
   - `MONGODB_URI` – MongoDB connection string (default: `mongodb://localhost:27017/serbisyo`)
   - `PORT` – API port (default: `3000`)
   - `JWT_SECRET` – Secret for JWT signing

4. **Seed categories and services**
   ```bash
   npm run seed
   ```

5. **Run the server**
   ```bash
   npm run dev
   ```
   API base URL: `http://localhost:3000` (routes under `/api`).

## API Endpoints

- `POST /api/auth/register` – Register (body: email, password, fullName)
- `POST /api/auth/login` – Login (body: email, password)
- `GET /api/auth/me` – Current user (header: `Authorization: Bearer <token>`)
- `GET /api/categories` – List service categories
- `GET /api/services` – List services (query: categoryId, q)
- `GET /api/services/:id` – Service by id
- `GET /api/bookings` – My bookings (auth required)
- `GET /api/bookings/:id` – Booking by id (auth required)
- `POST /api/bookings` – Create booking (auth required)
- `GET /api/messages/threads` – My message threads (auth required)
- `GET /api/messages/threads/:id` – Thread with messages (auth required)
- `POST /api/messages/threads/:id/messages` – Send message (auth required)

## Mobile connection

In the Flutter app, set the API base URL:

- **Windows / same machine**: `http://localhost:3000`
- **Android emulator**: `http://10.0.2.2:3000`
- **Device on same network**: `http://YOUR_PC_IP:3000`

Run the app with:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```
