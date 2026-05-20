"""
Auth endpoint tests.
OTP is bypassed via the dev shortcut (code="000000", no Twilio configured).
"""
from httpx import AsyncClient


# ── Helpers ───────────────────────────────────────────────────────────────────

PHONE = "+243812345678"
PASSWORD = "Secret123"
EMAIL = "test@kubochain.com"


async def _register(client: AsyncClient, phone: str = PHONE, email: str = EMAIL) -> dict:
    # Send OTP (dev mode — no Twilio needed)
    await client.post("/api/auth/send-otp", json={"phone": phone})
    resp = await client.post("/api/auth/register", json={
        "first_name": "Test",
        "last_name": "User",
        "email": email,
        "phone": phone,
        "password": PASSWORD,
        "role": "passenger",
        "otp_code": "000000",
    })
    return resp


# ── Registration ──────────────────────────────────────────────────────────────

async def test_register_success(client: AsyncClient):
    resp = await _register(client)
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == EMAIL
    assert data["user"]["role"] == "passenger"


async def test_register_duplicate_email(client: AsyncClient):
    resp = await _register(client, phone="+243812345679", email=EMAIL)
    assert resp.status_code == 409


async def test_register_weak_password(client: AsyncClient):
    await client.post("/api/auth/send-otp", json={"phone": "+243800000001"})
    resp = await client.post("/api/auth/register", json={
        "first_name": "Bad",
        "last_name": "Pass",
        "email": "bad@kubochain.com",
        "phone": "+243800000001",
        "password": "abc",
        "role": "passenger",
        "otp_code": "000000",
    })
    assert resp.status_code == 422


async def test_register_invalid_role(client: AsyncClient):
    await client.post("/api/auth/send-otp", json={"phone": "+243800000002"})
    resp = await client.post("/api/auth/register", json={
        "first_name": "X",
        "last_name": "Y",
        "email": "xy@kubochain.com",
        "phone": "+243800000002",
        "password": PASSWORD,
        "role": "admin",
        "otp_code": "000000",
    })
    assert resp.status_code == 422


# ── Login ─────────────────────────────────────────────────────────────────────

async def test_login_success(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={"phone": PHONE, "password": PASSWORD})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


async def test_login_wrong_password(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={"phone": PHONE, "password": "wrongpass1"})
    assert resp.status_code == 401


async def test_login_unknown_phone(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={"phone": "+243999999999", "password": PASSWORD})
    assert resp.status_code == 401


# ── Token refresh ─────────────────────────────────────────────────────────────

async def test_refresh_token(client: AsyncClient):
    login = await client.post("/api/auth/login", json={"phone": PHONE, "password": PASSWORD})
    refresh_token = login.json()["refresh_token"]
    resp = await client.post("/api/auth/refresh", json={"refresh_token": refresh_token})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


async def test_refresh_invalid_token(client: AsyncClient):
    resp = await client.post("/api/auth/refresh", json={"refresh_token": "not.a.real.token"})
    assert resp.status_code == 401


# ── /me ───────────────────────────────────────────────────────────────────────

async def test_get_me_authenticated(client: AsyncClient):
    login = await client.post("/api/auth/login", json={"phone": PHONE, "password": PASSWORD})
    token = login.json()["access_token"]
    resp = await client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["phone"] == PHONE


async def test_get_me_unauthenticated(client: AsyncClient):
    resp = await client.get("/api/auth/me")
    assert resp.status_code == 403


async def test_get_me_bad_token(client: AsyncClient):
    resp = await client.get("/api/auth/me", headers={"Authorization": "Bearer garbage"})
    assert resp.status_code == 401
