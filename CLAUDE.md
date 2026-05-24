# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KuboChain is a boda-boda (motorcycle taxi) ride-hailing platform for Goma, DRC. It has three sub-projects that communicate with each other:

- **Flutter mobile app** (`lib/`) — passenger and rider interfaces
- **FastAPI backend** (`backend/fastapi_server/`) — REST API + WebSocket server
- **React admin dashboard** (`dashboard/`) — operations, finance, and safety management UI

Currency is Congolese Francs (FC/CDF). Default map center is Goma, DRC (`-1.6792, 29.2228`).

---

## Commands

### Flutter (mobile app)

```bash
flutter pub get           # Install dependencies
flutter analyze           # Static analysis (mirrors CI)
flutter test              # Run all widget/unit tests
flutter test test/widget_test.dart  # Run a single test file
flutter run               # Run on connected device/emulator
flutter pub run flutter_launcher_icons:main  # Regenerate launcher icons
```

> The `.fvmrc` pins Flutter to `3.35.6`. CI uses `3.41.2`. Use FVM (`fvm use`) if installed; otherwise ensure your Flutter version is compatible.

### Backend (FastAPI)

All commands run from `backend/fastapi_server/`:

```bash
pip install -r requirements.txt   # Install dependencies
ruff check app                    # Lint (mirrors CI)
pytest -q                         # Run all tests (uses SQLite in-memory, no Postgres needed)
pytest tests/test_auth.py -q      # Run a single test file
uvicorn app.main:app --reload     # Run dev server on :8000
```

Migrations (requires a running Postgres):
```bash
alembic upgrade head                           # Apply all migrations
alembic revision --autogenerate -m "message"  # Generate a new migration
```

### Backend (Docker — full stack)

```bash
cd backend
cp .env.example .env   # Then fill in DB_PASSWORD, JWT_SECRET, etc.
docker compose up --build -d
docker compose exec -T api alembic upgrade head
```

### Dashboard (React admin)

```bash
cd dashboard
npm install
npm run dev      # Dev server (Vite)
npm run build    # Production build → dist/
```

---

## Architecture

### Flutter App

**Routing**: `MaterialApp` with named routes defined in `lib/core/routes/app_routes.dart`. Navigation uses `NavigationService.navigatorKey` (a global `GlobalKey<NavigatorState>`) so routes can be pushed from outside the widget tree (e.g., from notification tap handlers).

**State management**: Riverpod `ChangeNotifierProvider`. The four providers are declared in `lib/providers/providers.dart`:
- `authProvider` — user session, login/register/logout, role checks
- `rideProvider` — ride lifecycle state machine and socket event listeners  
- `locationProvider` — GPS position, address lookup, location permissions
- `driverProvider` — rider-side: incoming requests, online toggle, earnings

**Networking**: `ApiService` (static class, `lib/core/services/api_service.dart`) wraps Dio. It auto-attaches the Bearer token, auto-refreshes on 401 (rotating refresh token), and retries up to 3 times on connection/timeout errors with exponential back-off. Update `_host` (and `_wsHost` in `socket_service.dart`) to your machine's LAN IP when testing on a physical device.

**WebSocket**: `SocketService` (`lib/core/services/socket_service.dart`) uses `dart:io WebSocket` (not socket.io). Protocol: `{"event": "eventName", "data": {...}}`. It auto-reconnects with exponential back-off up to 60 s. `RideProvider.listenToRideEvents()` registers socket callbacks after joining a ride room.

**Storage**: `StorageService` stores JWTs and the serialised user JSON in `flutter_secure_storage` (Keychain/Keystore), and non-sensitive prefs (onboarding flag, avatar colour) in `SharedPreferences`. Values are in-memory-cached at startup so reads are synchronous.

**User roles**: `passenger`, `rider`, `admin`. The splash screen reads the cached role and routes accordingly. Providers expose `isPassenger`, `isRider`, `isAdmin` booleans.

**Maps**: `flutter_map` (OpenStreetMap tiles, not Google Maps). Live driver location is rendered via `LiveMapWidget`.

### FastAPI Backend

**Entry point**: `app/main.py`. Routers are registered at `/api` prefix: `auth`, `rides`, `drivers`, `chat`, `admin`, `admin_extras`. The WebSocket endpoint (`/ws`) has no prefix.

**Database**: SQLAlchemy async + asyncpg + PostgreSQL in production. The `get_db` dependency (`app/core/dependencies.py`) yields an `AsyncSession`. Tests override `get_db` with an in-memory SQLite session (see `tests/conftest.py`) — no Postgres is needed to run tests.

**Auth flow**: Access tokens expire in 15 minutes; refresh tokens in 7 days. `get_current_user` extracts the user from a Bearer token. `rider_only` and `admin_only` dependency wrappers enforce role access.

**WebSocket server** (`app/routers/ws.py`): A single `/ws` endpoint handles all real-time events. Clients authenticate via `?token=JWT` query param or first message. `ConnectionManager` (`app/core/ws_manager.py`) tracks user→sockets and room→sockets mappings. Key rooms:
- `drivers_online` — all online drivers receive new ride broadcasts
- `ride_{uuid}` — both passenger and driver join this room for a specific ride

**Ride lifecycle**: `pending` → `accepted` → `arriving` → `in_progress` → `awaiting_confirmation` → `completed`. The driver marks complete first; the passenger then confirms, which triggers earnings update and FCM notification to driver.

**OTP**: Twilio sends SMS in production. If `TWILIO_ACCOUNT_SID` is blank, the OTP code is printed to the server console (useful in local dev).

**Push notifications**: Firebase Admin SDK (`app/services/notifications.py`). Requires `firebase-credentials.json` mounted into the container.

**File uploads**: Served as static files from `/uploads`. Profile images go to `/api/auth/profile-image`; driver documents to `/api/auth/documents`. Max 5 MB per file (configurable via `MAX_UPLOAD_MB`).

**Rate limiting**: slowapi at 200 req/min globally; stricter limits on auth endpoints (10/min login, 5/min OTP, 10/min register).

**Configuration**: Pydantic `Settings` loaded from `.env`. `JWT_SECRET` defaults to `"change_me"` — this raises a `RuntimeError` in production but only warns in dev. Generate one with `python3 -c "import secrets; print(secrets.token_hex(64))"`.

### React Dashboard

Single-page app with React Router v6. `PrivateRoute` checks `localStorage.getItem('admin_token')`. All API calls go through `src/config/api.js` (axios instance with Bearer token interceptor). Socket.io client is in `src/config/socket.js`. UI is built with Tailwind CSS (`dark-bg` custom palette).

---

## Key Conventions

**Flutter/Dart**:
- Screens are split into `lib/screens/passenger/` and `lib/screens/rider/` for role-specific views; shared screens live in `lib/screens/common/`.
- API request/response field names use `snake_case` to match the FastAPI schema (e.g., `first_name`, `profile_image`). The models convert these in `fromJson`/`toJson`.
- Several linter rules are suppressed in `analysis_options.yaml` as pre-existing technical debt: `deprecated_member_use`, `use_build_context_synchronously`, `unnecessary_import`, etc. Do not add new violations.

**Backend/Python**:
- `ruff.toml` targets Python 3.13 and ignores `F821` (SQLAlchemy forward-reference false positive).
- All router functions are `async`. DB queries use `await db.execute(select(...))`.
- Schema classes use snake_case Pydantic models (`RegisterIn`, `UserOut`, `RideOut`, etc.).

**WebSocket event naming**:
- Client → Server: `driver:setOnline`, `driver:updateLocation`, `ride:join`, `ride:leave`, `ride:arrived`, `chat:send`, `chat:read`
- Server → Client: `ride:newRequest`, `ride:accepted`, `ride:driverArrived`, `ride:started`, `ride:awaitingConfirmation`, `ride:completed`, `ride:cancelled`, `ride:driverLocation`, `chat:message`, `chat:read`

## Test Credentials

| Role      | Email                | Password   |
|-----------|----------------------|------------|
| Passenger | passenger@test.com   | Test1234!  |
| Driver    | driver@test.com      | Test1234!  |

Seed with `python seed_test_users.py` (admin) from `backend/fastapi_server/`.
