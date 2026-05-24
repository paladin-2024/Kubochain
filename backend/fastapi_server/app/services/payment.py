import asyncio
import uuid as _uuid


async def initiate_payment(phone: str, amount: float, ride_id: str, method: str) -> dict:
    """Stub Airtel Money payment — replace body with real API call when credentials available."""
    await asyncio.sleep(2)
    return {"reference": f"STUB-{_uuid.uuid4()}", "status": "paid"}
