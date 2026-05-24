"""Payment service and endpoint tests."""
import pytest
from app.services.payment import initiate_payment


@pytest.mark.asyncio
async def test_stub_returns_paid_status():
    result = await initiate_payment("+243812345678", 5000.0, "test-ride-id", "airtel_money")
    assert result["status"] == "paid"


@pytest.mark.asyncio
async def test_stub_returns_reference():
    result = await initiate_payment("+243812345678", 5000.0, "test-ride-id", "airtel_money")
    assert result["reference"].startswith("STUB-")


@pytest.mark.asyncio
async def test_stub_works_for_cash():
    result = await initiate_payment("+243812345678", 3000.0, "test-ride-id", "cash")
    assert result["status"] == "paid"


from httpx import AsyncClient


async def _get_token(client: AsyncClient) -> str:
    phone = "+243800000099"
    await client.post("/api/auth/send-otp", json={"phone": phone})
    reg = await client.post("/api/auth/register", json={
        "first_name": "Pay", "last_name": "Test",
        "email": "paytest@kubochain.com", "phone": phone,
        "password": "Secret123", "role": "passenger", "otp_code": "000000",
    })
    return reg.json()["access_token"]


@pytest.mark.asyncio
async def test_payment_history_empty(client: AsyncClient):
    token = await _get_token(client)
    resp = await client.get("/api/payments/history", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_payment_status_unknown_ride(client: AsyncClient):
    token = await _get_token(client)
    fake_id = "00000000-0000-0000-0000-000000000000"
    resp = await client.get(f"/api/payments/{fake_id}/status", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_payment_callback_stub(client: AsyncClient):
    resp = await client.post("/api/payments/callback", json={"reference": "TEST-123"})
    assert resp.status_code == 200
    assert resp.json()["status"] == "received"
