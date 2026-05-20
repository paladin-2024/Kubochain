"""Security and input validation tests."""
import pytest
from httpx import AsyncClient
from app.core.security import (
    create_access_token, create_refresh_token,
    decode_access_token, decode_refresh_token,
    hash_password, verify_password,
)


# ── JWT token validation ──────────────────────────────────────────────────────

def test_access_token_roundtrip():
    token = create_access_token("user-123", "passenger")
    payload = decode_access_token(token)
    assert payload["sub"] == "user-123"
    assert payload["role"] == "passenger"
    assert payload["type"] == "access"


def test_refresh_token_roundtrip():
    token = create_refresh_token("user-456", "rider")
    payload = decode_refresh_token(token)
    assert payload["sub"] == "user-456"
    assert payload["type"] == "refresh"


def test_access_token_rejected_as_refresh():
    token = create_access_token("user-123", "passenger")
    with pytest.raises(Exception):
        decode_refresh_token(token)


def test_refresh_token_rejected_as_access():
    token = create_refresh_token("user-123", "passenger")
    with pytest.raises(Exception):
        decode_access_token(token)


def test_invalid_token_raises():
    with pytest.raises(Exception):
        decode_access_token("this.is.garbage")


# ── Password hashing ──────────────────────────────────────────────────────────

def test_password_hash_verify():
    hashed = hash_password("MySecret99")
    assert verify_password("MySecret99", hashed)


def test_wrong_password_fails():
    hashed = hash_password("MySecret99")
    assert not verify_password("WrongPassword1", hashed)


def test_hash_is_not_plaintext():
    hashed = hash_password("MySecret99")
    assert hashed != "MySecret99"
    assert hashed.startswith("$2b$")


# ── Input validation ──────────────────────────────────────────────────────────

async def test_register_invalid_phone(client: AsyncClient):
    resp = await client.post("/api/auth/register", json={
        "first_name": "X",
        "last_name": "Y",
        "email": "x@test.com",
        "phone": "not-a-phone",
        "password": "Secret123",
        "role": "passenger",
        "otp_code": "000000",
    })
    assert resp.status_code == 422


async def test_register_invalid_email(client: AsyncClient):
    resp = await client.post("/api/auth/register", json={
        "first_name": "X",
        "last_name": "Y",
        "email": "notanemail",
        "phone": "+243800000099",
        "password": "Secret123",
        "role": "passenger",
        "otp_code": "000000",
    })
    assert resp.status_code == 422


async def test_login_invalid_phone_format(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "phone": "abc",
        "password": "Secret123",
    })
    assert resp.status_code == 422


async def test_health_endpoint(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


async def test_security_headers_present(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.headers.get("x-content-type-options") == "nosniff"
    assert resp.headers.get("x-frame-options") == "DENY"
    assert resp.headers.get("cache-control") == "no-store"
