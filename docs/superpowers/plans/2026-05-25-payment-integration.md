# Payment Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add end-to-end Airtel Money + Cash payment flow across the Flutter passenger app, Flutter driver app, and React admin dashboard, with a stubbed Airtel API swappable for real credentials in one function.

**Architecture:** Backend-first — add payment fields to the `rides` table, a stub payment service, and a `/payments` router. Flutter adds three new screens (payment, receipt, history) and wires the post-trip flow. The admin dashboard replaces mock data with real endpoints and adds a payment status override control.

**Tech Stack:** FastAPI + SQLAlchemy async + Alembic (backend); Flutter + Riverpod + Dio (mobile); React + Recharts + Tailwind (dashboard)

---

## File Map

**New files:**
- `backend/fastapi_server/app/services/payment.py`
- `backend/fastapi_server/app/schemas/payment.py`
- `backend/fastapi_server/app/routers/payments.py`
- `backend/fastapi_server/alembic/versions/xxxx_add_payment_fields.py`
- `backend/fastapi_server/tests/test_payments.py`
- `lib/screens/passenger/airtel_payment_screen.dart`
- `lib/screens/passenger/payment_receipt_screen.dart`
- `lib/screens/passenger/payment_history_screen.dart`

**Modified files:**
- `backend/fastapi_server/app/main.py` — register payments router
- `backend/fastapi_server/app/models/ride.py` — 4 new fields
- `backend/fastapi_server/app/schemas/ride.py` — add payment fields to `CreateRideIn` + `RideOut`
- `backend/fastapi_server/app/routers/rides.py` — store `payment_method` on create
- `backend/fastapi_server/app/routers/admin_extras.py` — update transactions, add finance/stats, finance/chart, payments status override
- `lib/models/ride_model.dart` — add payment fields
- `lib/core/services/api_service.dart` — 3 new methods
- `lib/screens/passenger/payment_screen.dart` — remove card option
- `lib/screens/passenger/choose_rider_screen.dart` — capture payment method
- `lib/screens/passenger/trip_screen.dart` — trigger payment flow on complete
- `lib/screens/passenger/profile_screen.dart` — add payment history entry
- `lib/providers/ride_provider.dart` — pass payment_method on booking
- `lib/main.dart` — handle `payment_received` FCM type
- `dashboard/src/pages/FinanceDashboard.jsx` — real data + method breakdown
- `dashboard/src/pages/Transactions.jsx` — real data + status controls

---

## Task 1: Alembic migration — add payment fields to rides

**Files:**
- Create: `backend/fastapi_server/alembic/versions/xxxx_add_payment_fields.py`

- [ ] **Step 1: Generate the migration file**

```bash
cd backend/fastapi_server
alembic revision --autogenerate -m "add_payment_fields_to_rides"
```

- [ ] **Step 2: Replace the auto-generated body with explicit ops**

Open the newly created file in `alembic/versions/` and replace `upgrade()`/`downgrade()` with:

```python
def upgrade() -> None:
    op.add_column('rides', sa.Column('payment_method', sa.String(20), nullable=False, server_default='cash'))
    op.add_column('rides', sa.Column('payment_status', sa.String(20), nullable=False, server_default='pending'))
    op.add_column('rides', sa.Column('payment_phone', sa.Text(), nullable=True))
    op.add_column('rides', sa.Column('payment_reference', sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column('rides', 'payment_reference')
    op.drop_column('rides', 'payment_phone')
    op.drop_column('rides', 'payment_status')
    op.drop_column('rides', 'payment_method')
```

- [ ] **Step 3: Apply the migration**

```bash
cd backend/fastapi_server
alembic upgrade head
```

Expected: `Running upgrade ... -> <revision_id>, add_payment_fields_to_rides`

- [ ] **Step 4: Update the Ride SQLAlchemy model**

In `backend/fastapi_server/app/models/ride.py`, add after the `ride_type` line:

```python
    payment_method: Mapped[str] = mapped_column(String(20), default="cash")
    payment_status: Mapped[str] = mapped_column(String(20), default="pending")
    payment_phone: Mapped[str | None] = mapped_column(Text, nullable=True)
    payment_reference: Mapped[str | None] = mapped_column(Text, nullable=True)
```

- [ ] **Step 5: Commit**

```
git add backend/fastapi_server/alembic/versions/ backend/fastapi_server/app/models/ride.py
git commit -m "feat: add payment fields to rides table"
```

---

## Task 2: Payment service stub

**Files:**
- Create: `backend/fastapi_server/app/services/payment.py`
- Create: `backend/fastapi_server/tests/test_payments.py`

- [ ] **Step 1: Write the failing test**

Create `backend/fastapi_server/tests/test_payments.py`:

```python
"""Payment service and endpoint tests."""
import pytest
from app.services.payment import initiate_payment


async def test_stub_returns_paid_status():
    result = await initiate_payment("+243812345678", 5000.0, "test-ride-id", "airtel_money")
    assert result["status"] == "paid"


async def test_stub_returns_reference():
    result = await initiate_payment("+243812345678", 5000.0, "test-ride-id", "airtel_money")
    assert result["reference"].startswith("STUB-")


async def test_stub_works_for_cash():
    result = await initiate_payment("+243812345678", 3000.0, "test-ride-id", "cash")
    assert result["status"] == "paid"
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend/fastapi_server
pytest tests/test_payments.py -v
```

Expected: `ERROR` — `ModuleNotFoundError: No module named 'app.services.payment'`

- [ ] **Step 3: Create the payment service**

Create `backend/fastapi_server/app/services/payment.py`:

```python
import asyncio
import uuid as _uuid


async def initiate_payment(phone: str, amount: float, ride_id: str, method: str) -> dict:
    """Stub Airtel Money payment — replace body with real API call when credentials available."""
    await asyncio.sleep(2)
    return {"reference": f"STUB-{_uuid.uuid4()}", "status": "paid"}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd backend/fastapi_server
pytest tests/test_payments.py -v
```

Expected: `3 passed`

- [ ] **Step 5: Commit**

```
git add backend/fastapi_server/app/services/payment.py backend/fastapi_server/tests/test_payments.py
git commit -m "feat: add stubbed Airtel Money payment service"
```

---

## Task 3: Payment schemas

**Files:**
- Create: `backend/fastapi_server/app/schemas/payment.py`

- [ ] **Step 1: Create the schemas file**

Create `backend/fastapi_server/app/schemas/payment.py`:

```python
import uuid
from pydantic import BaseModel, field_validator
from typing import Optional


class PaymentInitiateIn(BaseModel):
    ride_id: uuid.UUID
    phone_number: str
    payment_method: str = "airtel_money"

    @field_validator("payment_method")
    @classmethod
    def valid_method(cls, v: str) -> str:
        if v not in ("airtel_money", "mtn_momo", "cash"):
            raise ValueError("payment_method must be airtel_money, mtn_momo, or cash")
        return v

    @field_validator("phone_number")
    @classmethod
    def valid_phone(cls, v: str) -> str:
        v = v.strip()
        if not v.startswith("+") or len(v) < 10:
            raise ValueError("phone_number must be in E.164 format e.g. +243812345678")
        return v


class PaymentStatusOut(BaseModel):
    payment_status: str
    payment_reference: Optional[str] = None


class PaymentHistoryItem(BaseModel):
    ride_id: str
    amount: float
    payment_method: str
    payment_status: str
    payment_reference: Optional[str] = None
    payment_phone: Optional[str] = None
    pickup_address: str
    destination_address: str
    driver_name: Optional[str] = None
    created_at: Optional[str] = None


class PaymentInitiateOut(BaseModel):
    status: str
    reference: Optional[str] = None
    amount: float
```

- [ ] **Step 2: Commit**

```
git add backend/fastapi_server/app/schemas/payment.py
git commit -m "feat: add payment Pydantic schemas"
```

---

## Task 4: Payments router

**Files:**
- Create: `backend/fastapi_server/app/routers/payments.py`

- [ ] **Step 1: Create the payments router**

Create `backend/fastapi_server/app/routers/payments.py`:

```python
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..database import get_db
from ..models.ride import Ride
from ..models.user import User
from ..models.driver import Driver
from ..core.dependencies import get_current_user
from ..services.payment import initiate_payment
from ..services.notifications import send_push
from ..schemas.payment import PaymentInitiateIn, PaymentInitiateOut, PaymentStatusOut, PaymentHistoryItem
import logging

router = APIRouter(prefix="/payments", tags=["payments"])
_log = logging.getLogger("kubochain.audit")


@router.post("/initiate", response_model=PaymentInitiateOut)
async def initiate(
    body: PaymentInitiateIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, body.ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    if ride.passenger_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your ride")
    if ride.status != "completed":
        raise HTTPException(status_code=400, detail="Ride is not completed")
    if ride.payment_status == "paid":
        raise HTTPException(status_code=409, detail="Ce trajet a déjà été payé")

    ride.payment_status = "processing"
    ride.payment_phone = body.phone_number
    ride.payment_method = body.payment_method
    await db.commit()

    result = await initiate_payment(
        body.phone_number, float(ride.price), str(ride.id), body.payment_method
    )

    ride.payment_status = result["status"]
    ride.payment_reference = result["reference"]
    await db.commit()

    _log.info("payment_complete ride=%s method=%s status=%s", ride.id, body.payment_method, result["status"])

    if ride.driver_id:
        driver = (await db.execute(select(Driver).where(Driver.id == ride.driver_id))).scalar_one_or_none()
        if driver:
            driver_user = await db.get(User, driver.user_id)
            if driver_user and driver_user.fcm_token:
                await send_push(
                    token=driver_user.fcm_token,
                    title="Paiement reçu",
                    body=f"FC {float(ride.price):.0f} via Airtel Money — {current_user.first_name}",
                    data={"type": "payment_received", "ride_id": str(ride.id)},
                )

    return PaymentInitiateOut(
        status=ride.payment_status,
        reference=ride.payment_reference,
        amount=float(ride.price),
    )


@router.get("/history", response_model=list[PaymentHistoryItem])
async def get_history(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Ride)
        .where(Ride.passenger_id == current_user.id)
        .order_by(Ride.created_at.desc())
        .limit(50)
    )
    rides = result.scalars().all()
    items = []
    for ride in rides:
        driver_name = None
        if ride.driver_id:
            driver = (await db.execute(select(Driver).where(Driver.id == ride.driver_id))).scalar_one_or_none()
            if driver:
                du = await db.get(User, driver.user_id)
                if du:
                    driver_name = f"{du.first_name} {du.last_name}"
        items.append(PaymentHistoryItem(
            ride_id=str(ride.id),
            amount=float(ride.price),
            payment_method=ride.payment_method or "cash",
            payment_status=ride.payment_status or "pending",
            payment_reference=ride.payment_reference,
            payment_phone=ride.payment_phone,
            pickup_address=ride.pickup_address,
            destination_address=ride.destination_address,
            driver_name=driver_name,
            created_at=ride.created_at.isoformat() if ride.created_at else None,
        ))
    return items


@router.get("/{ride_id}/status", response_model=PaymentStatusOut)
async def get_status(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride or ride.passenger_id != current_user.id:
        raise HTTPException(status_code=404, detail="Ride not found")
    return PaymentStatusOut(
        payment_status=ride.payment_status or "pending",
        payment_reference=ride.payment_reference,
    )


@router.post("/callback")
async def airtel_callback(request: Request):
    """Airtel Money webhook — placeholder, logs and acknowledges."""
    try:
        body = await request.json()
        _log.info("airtel_callback body=%s", body)
    except Exception:
        pass
    return {"status": "received"}
```

- [ ] **Step 2: Add endpoint tests to test_payments.py**

Append to `backend/fastapi_server/tests/test_payments.py`:

```python
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


async def test_payment_history_empty(client: AsyncClient):
    token = await _get_token(client)
    resp = await client.get("/api/payments/history", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json() == []


async def test_payment_status_unknown_ride(client: AsyncClient):
    token = await _get_token(client)
    fake_id = "00000000-0000-0000-0000-000000000000"
    resp = await client.get(f"/api/payments/{fake_id}/status", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 404


async def test_payment_callback_stub(client: AsyncClient):
    resp = await client.post("/api/payments/callback", json={"reference": "TEST-123"})
    assert resp.status_code == 200
    assert resp.json()["status"] == "received"
```

- [ ] **Step 3: Register router in main.py**

In `backend/fastapi_server/app/main.py`, add to imports:

```python
from .routers import auth, rides, drivers, chat, admin, ws, payments
```

And add after the existing `app.include_router` calls:

```python
app.include_router(payments.router, prefix="/api")
```

- [ ] **Step 4: Run all tests**

```bash
cd backend/fastapi_server
pytest tests/test_payments.py -v
```

Expected: `6 passed`

- [ ] **Step 5: Commit**

```
git add backend/fastapi_server/app/routers/payments.py backend/fastapi_server/app/main.py backend/fastapi_server/tests/test_payments.py
git commit -m "feat: add payments router with initiate, history, status, callback"
```

---

## Task 5: Update rides router — accept payment_method on booking

**Files:**
- Modify: `backend/fastapi_server/app/schemas/ride.py`
- Modify: `backend/fastapi_server/app/routers/rides.py`

- [ ] **Step 1: Add payment_method to CreateRideIn and RideOut schemas**

In `backend/fastapi_server/app/schemas/ride.py`, update `CreateRideIn`:

```python
class CreateRideIn(BaseModel):
    pickup: LocationIn
    destination: LocationIn
    ride_type: str = "economy"
    price: float
    distance: float
    payment_method: str = "cash"
```

Add to `RideOut` (after `cancelled_by`):

```python
    payment_method: Optional[str] = "cash"
    payment_status: Optional[str] = "pending"
    payment_reference: Optional[str] = None
```

- [ ] **Step 2: Store payment_method when creating ride**

In `backend/fastapi_server/app/routers/rides.py`, find the `create_ride` endpoint. In the `Ride(...)` constructor call, add:

```python
        payment_method=body.payment_method,
```

- [ ] **Step 3: Return payment fields in _build_ride_out**

In `_build_ride_out` in `rides.py`, add to the `RideOut(...)` constructor:

```python
        payment_method=ride.payment_method,
        payment_status=ride.payment_status,
        payment_reference=ride.payment_reference,
```

- [ ] **Step 4: Run existing tests to confirm nothing broke**

```bash
cd backend/fastapi_server
pytest tests/test_auth.py tests/test_security.py tests/test_payments.py -v
```

Expected: all passing (same count as before)

- [ ] **Step 5: Commit**

```
git add backend/fastapi_server/app/schemas/ride.py backend/fastapi_server/app/routers/rides.py
git commit -m "feat: store and return payment_method on ride creation"
```

---

## Task 6: Admin finance endpoints

**Files:**
- Modify: `backend/fastapi_server/app/routers/admin_extras.py`

- [ ] **Step 1: Update list_transactions to use real payment fields**

In `admin_extras.py`, replace the `list_transactions` function body (keep the decorator and signature):

```python
@router.get("/transactions")
async def list_transactions(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
    status: str = "",
    method: str = "",
    search: str = "",
    page: int = 1,
):
    q = select(Ride).where(Ride.status.in_(["completed", "cancelled"])).order_by(Ride.created_at.desc())
    result = await db.execute(q)
    rides = result.scalars().all()

    items = []
    for r in rides:
        # Get passenger name
        passenger_name = ""
        if r.passenger_id:
            p = await db.get(User, r.passenger_id)
            if p:
                passenger_name = f"{p.first_name} {p.last_name}"

        # Get driver name
        driver_name = ""
        if r.driver_id:
            from ..models.driver import Driver
            d = (await db.execute(select(Driver).where(Driver.id == r.driver_id))).scalar_one_or_none()
            if d:
                du = await db.get(User, d.user_id)
                if du:
                    driver_name = f"{du.first_name} {du.last_name}"

        items.append({
            "id": f"TXN-{str(r.id)[:8].upper()}",
            "ride_id": str(r.id),
            "rider": passenger_name,
            "driver": driver_name,
            "amount": float(r.price or 0),
            "commission": round(float(r.price or 0) * 0.15, 2),
            "driver_earning": round(float(r.price or 0) * 0.85, 2),
            "method": r.payment_method or "cash",
            "status": r.payment_status or "pending",
            "created_at": r.created_at.isoformat() if r.created_at else None,
        })

    # Filter
    if status:
        items = [i for i in items if i["status"] == status]
    if method:
        items = [i for i in items if i["method"] == method]
    if search:
        s = search.lower()
        items = [i for i in items if s in i["rider"].lower() or s in i["driver"].lower() or s in i["id"].lower()]

    # Paginate
    per_page = 20
    start = (page - 1) * per_page
    return items[start:start + per_page]
```

- [ ] **Step 2: Add finance/stats endpoint**

Add after `list_transactions` in `admin_extras.py`:

```python
@router.get("/finance/stats")
async def finance_stats(
    period: str = "7d",
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    from datetime import timedelta, timezone
    now = datetime.now(timezone.utc)
    if period == "today":
        since = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == "7d":
        since = now - timedelta(days=7)
    elif period == "30d":
        since = now - timedelta(days=30)
    else:
        since = datetime(2020, 1, 1, tzinfo=timezone.utc)

    result = await db.execute(
        select(Ride).where(Ride.status == "completed", Ride.created_at >= since)
    )
    rides = result.scalars().all()

    total_revenue = sum(float(r.price or 0) for r in rides)
    platform_commission = round(total_revenue * 0.15, 2)
    driver_earnings = round(total_revenue * 0.85, 2)
    avg_fare = round(total_revenue / len(rides), 2) if rides else 0

    by_method: dict = {}
    for r in rides:
        m = r.payment_method or "cash"
        if m not in by_method:
            by_method[m] = {"count": 0, "total": 0.0}
        by_method[m]["count"] += 1
        by_method[m]["total"] = round(by_method[m]["total"] + float(r.price or 0), 2)

    paid_count = sum(1 for r in rides if r.payment_status == "paid")

    return {
        "total_revenue": total_revenue,
        "platform_commission": platform_commission,
        "driver_earnings": driver_earnings,
        "avg_fare": avg_fare,
        "total_rides": len(rides),
        "total_transactions": paid_count,
        "by_method": by_method,
    }
```

- [ ] **Step 3: Add finance/chart endpoint**

Add after `finance_stats`:

```python
@router.get("/finance/chart")
async def finance_chart(
    period: str = "7d",
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    from datetime import timedelta, timezone
    from collections import defaultdict

    now = datetime.now(timezone.utc)
    days = 1 if period == "today" else 7 if period == "7d" else 30
    since = now - timedelta(days=days)

    result = await db.execute(
        select(Ride).where(Ride.status == "completed", Ride.created_at >= since)
    )
    rides = result.scalars().all()

    by_day: dict = defaultdict(lambda: {"revenue": 0.0, "commission": 0.0})
    fmt = "%a" if days <= 7 else "%d/%m"
    for r in rides:
        day = r.created_at.strftime(fmt)
        by_day[day]["revenue"] = round(by_day[day]["revenue"] + float(r.price or 0), 2)
        by_day[day]["commission"] = round(by_day[day]["commission"] + float(r.price or 0) * 0.15, 2)

    return [{"day": k, **v} for k, v in by_day.items()]
```

- [ ] **Step 4: Add payment status override endpoint**

Add after `finance_chart`:

```python
@router.patch("/payments/{ride_id}/status")
async def override_payment_status(
    ride_id: str,
    body: dict,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(admin_only),
):
    import uuid as _uuid
    ride = await db.get(Ride, _uuid.UUID(ride_id))
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    new_status = body.get("status")
    if new_status not in ("paid", "failed", "pending"):
        raise HTTPException(status_code=422, detail="status must be paid, failed, or pending")

    ride.payment_status = new_status
    await db.commit()
    await _audit(db, f"payment_status_override:{new_status}", admin, ride_id)
    await db.commit()
    return {"ride_id": ride_id, "payment_status": new_status}
```

- [ ] **Step 5: Add missing datetime import if needed**

Check the top of `admin_extras.py` — if `from datetime import datetime` is not present, add it.

- [ ] **Step 6: Run all backend tests**

```bash
cd backend/fastapi_server
pytest -q
```

Expected: all passing

- [ ] **Step 7: Commit**

```
git add backend/fastapi_server/app/routers/admin_extras.py
git commit -m "feat: add finance/stats, finance/chart, payment status override admin endpoints"
```

---

## Task 7: Flutter — update RideModel

**Files:**
- Modify: `lib/models/ride_model.dart`

- [ ] **Step 1: Add payment fields to RideModel**

In `lib/models/ride_model.dart`, add to the field declarations (after `completedAt`):

```dart
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentReference;
```

- [ ] **Step 2: Add to constructor**

In the `RideModel({...})` constructor, add:

```dart
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.paymentReference,
```

- [ ] **Step 3: Update fromJson**

In `RideModel.fromJson`, add inside the constructor call (after `completedAt:`):

```dart
      paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? 'pending',
      paymentReference: json['payment_reference'] ?? json['paymentReference'],
```

- [ ] **Step 4: Run Flutter analyze**

```bash
flutter analyze lib/models/ride_model.dart
```

Expected: no errors

- [ ] **Step 5: Commit**

```
git add lib/models/ride_model.dart
git commit -m "feat: add payment fields to Flutter RideModel"
```

---

## Task 8: Flutter — add payment API methods

**Files:**
- Modify: `lib/core/services/api_service.dart`

- [ ] **Step 1: Add three payment methods**

In `lib/core/services/api_service.dart`, add after `passengerConfirmRide`:

```dart
  static Future<Response> initiatePayment({
    required String rideId,
    required String phone,
    required String method,
  }) =>
      _dio.post('/payments/initiate', data: {
        'ride_id': rideId,
        'phone_number': phone,
        'payment_method': method,
      });

  static Future<Response> getPaymentStatus(String rideId) =>
      _dio.get('/payments/$rideId/status');

  static Future<Response> getPaymentHistory() =>
      _dio.get('/payments/history');
```

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/core/services/api_service.dart
```

Expected: no errors

- [ ] **Step 3: Commit**

```
git add lib/core/services/api_service.dart
git commit -m "feat: add payment API service methods"
```

---

## Task 9: Flutter — remove card option from PaymentScreen

**Files:**
- Modify: `lib/screens/passenger/payment_screen.dart`

- [ ] **Step 1: Remove the card entry from _methods**

In `lib/screens/passenger/payment_screen.dart`, find the `_methods` list and remove the card entry:

```dart
// DELETE this entire entry:
    _PayMethod(
      id: 'card',
      label: 'Carte de crédit / débit',
      subtitle: 'Visa, Mastercard · Sécurisé',
      icon: HugeIcons.strokeRoundedCreditCard,
      brandColor: Color(0xFF2563EB),
      bgLight: Color(0xFFEFF6FF),
      tag: null,
    ),
```

- [ ] **Step 2: Verify the screen still compiles**

```bash
flutter analyze lib/screens/passenger/payment_screen.dart
```

Expected: no errors

- [ ] **Step 3: Commit**

```
git add lib/screens/passenger/payment_screen.dart
git commit -m "feat: remove card payment option — not applicable in Goma"
```

---

## Task 10: Flutter — capture and pass payment_method when booking

**Files:**
- Modify: `lib/screens/passenger/choose_rider_screen.dart`
- Modify: `lib/providers/ride_provider.dart`

- [ ] **Step 1: Add payment_method parameter to requestRide**

In `lib/providers/ride_provider.dart`, update the `requestRide` signature:

```dart
  Future<bool> requestRide({
    required LocationPoint pickup,
    required LocationPoint destination,
    required String rideType,
    required double price,
    required double distance,
    String paymentMethod = 'cash',
  }) async {
```

And in the `ApiService.createRide(...)` call body, add:

```dart
        'payment_method': paymentMethod,
```

- [ ] **Step 2: Add payment method state to choose_rider_screen**

In `lib/screens/passenger/choose_rider_screen.dart`, inside `_ChooseRiderScreenState`, add the field:

```dart
  String _paymentMethod = 'cash';
```

- [ ] **Step 3: Add payment method selector button**

In `choose_rider_screen.dart`, find the widget where ride type buttons are shown (the bottom sheet or card area). Add a payment method row above the confirm button:

```dart
GestureDetector(
  onTap: () async {
    final method = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentScreen()),
    );
    if (method != null) setState(() => _paymentMethod = method);
  },
  child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const HugeIcon(icon: HugeIcons.strokeRoundedMoney01, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _paymentMethod == 'airtel_money'
                ? 'Airtel Money'
                : _paymentMethod == 'mtn_momo'
                    ? 'MTN MoMo'
                    : 'Espèces',
            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: AppColors.textSecondary),
      ],
    ),
  ),
),
```

Add the missing import at the top of the file if not present:
```dart
import '../passenger/payment_screen.dart';
```

- [ ] **Step 4: Pass paymentMethod to requestRide in _confirmRide**

In `_confirmRide()`, update the `requestRide` call:

```dart
    await ride.requestRide(
      pickup: LocationPoint(...),
      destination: LocationPoint(...),
      rideType: _selectedType,
      price: price,
      distance: widget.distanceKm,
      paymentMethod: _paymentMethod,
    );
```

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/screens/passenger/choose_rider_screen.dart lib/providers/ride_provider.dart
```

Expected: no errors

- [ ] **Step 6: Commit**

```
git add lib/screens/passenger/choose_rider_screen.dart lib/providers/ride_provider.dart
git commit -m "feat: capture and pass payment method when booking ride"
```

---

## Task 11: Flutter — AirtelPaymentScreen

**Files:**
- Create: `lib/screens/passenger/airtel_payment_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/screens/passenger/airtel_payment_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/providers.dart';
import 'payment_receipt_screen.dart';

class AirtelPaymentScreen extends ConsumerStatefulWidget {
  final String rideId;
  final double amount;
  final String pickupAddress;
  final String destinationAddress;
  final String? driverName;

  const AirtelPaymentScreen({
    super.key,
    required this.rideId,
    required this.amount,
    required this.pickupAddress,
    required this.destinationAddress,
    this.driverName,
  });

  @override
  ConsumerState<AirtelPaymentScreen> createState() => _AirtelPaymentScreenState();
}

class _AirtelPaymentScreenState extends ConsumerState<AirtelPaymentScreen> {
  final _phoneCtrl = TextEditingController();
  _PayState _state = _PayState.idle;
  String? _error;
  int _attempts = 0;
  static const _maxAttempts = 3;
  String? _reference;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _phoneCtrl.text = auth.user?.phone ?? '';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_attempts >= _maxAttempts) return;
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Entrez votre numéro Airtel Money');
      return;
    }
    setState(() { _state = _PayState.processing; _error = null; });
    _attempts++;
    try {
      final res = await ApiService.initiatePayment(
        rideId: widget.rideId,
        phone: phone,
        method: 'airtel_money',
      );
      final data = res.data as Map<String, dynamic>;
      if (data['status'] == 'paid') {
        _reference = data['reference'] as String?;
        setState(() => _state = _PayState.success);
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentReceiptScreen(
              amount: widget.amount,
              reference: _reference ?? '',
              driverName: widget.driverName,
              pickupAddress: widget.pickupAddress,
              destinationAddress: widget.destinationAddress,
              paymentMethod: 'airtel_money',
            ),
          ),
        );
      } else {
        setState(() {
          _state = _PayState.failed;
          _error = 'Paiement refusé. Vérifiez votre solde Airtel.';
        });
      }
    } catch (_) {
      setState(() {
        _state = _PayState.failed;
        _error = _attempts >= _maxAttempts
            ? 'Échec après $_maxAttempts tentatives. Contactez le support.'
            : 'Erreur réseau. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payer via Airtel Money',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE02020).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE02020).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text('Montant à payer',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text('FC ${widget.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.sora(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${widget.pickupAddress} → ${widget.destinationAddress}',
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (_state != _PayState.success) ...[
              Text('Numéro Airtel Money',
                  style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                enabled: _state == _PayState.idle || _state == _PayState.failed,
                decoration: InputDecoration(
                  hintText: '+243XXXXXXXXX',
                  prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSmartphone01, size: 20, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.error))),
              ]),
            ],

            const Spacer(),

            // State-driven bottom button
            if (_state == _PayState.processing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Center(child: Text('Traitement en cours...',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary))),
            ] else if (_state == _PayState.success) ...[
              Center(child: Column(children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 56, color: AppColors.success),
                const SizedBox(height: 12),
                Text('Paiement confirmé !',
                    style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success)),
              ])),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _attempts >= _maxAttempts ? AppColors.textSecondary : const Color(0xFFE02020),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: _attempts >= _maxAttempts ? null : _pay,
                  child: Text(
                    _state == _PayState.failed ? 'Réessayer' : 'Payer maintenant',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

enum _PayState { idle, processing, success, failed }
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/screens/passenger/airtel_payment_screen.dart
```

Expected: no errors

- [ ] **Step 3: Commit**

```
git add lib/screens/passenger/airtel_payment_screen.dart
git commit -m "feat: add AirtelPaymentScreen with retry logic"
```

---

## Task 12: Flutter — PaymentReceiptScreen

**Files:**
- Create: `lib/screens/passenger/payment_receipt_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/screens/passenger/payment_receipt_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import 'rate_driver_screen.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final double amount;
  final String reference;
  final String? driverName;
  final String pickupAddress;
  final String destinationAddress;
  final String paymentMethod;
  final DateTime? paidAt;

  const PaymentReceiptScreen({
    super.key,
    required this.amount,
    required this.reference,
    this.driverName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.paymentMethod,
    this.paidAt,
  });

  String get _methodLabel => paymentMethod == 'airtel_money'
      ? 'Airtel Money'
      : paymentMethod == 'mtn_momo'
          ? 'MTN MoMo'
          : 'Espèces';

  Color get _methodColor =>
      paymentMethod == 'airtel_money' ? const Color(0xFFE02020) : paymentMethod == 'mtn_momo' ? const Color(0xFFFFC107) : AppColors.success;

  Future<void> _shareWhatsApp() async {
    final date = (paidAt ?? DateTime.now()).toLocal();
    final msg = Uri.encodeComponent(
      'KuboChain — Reçu de paiement\n'
      'Montant: FC ${amount.toStringAsFixed(0)}\n'
      'Méthode: $_methodLabel\n'
      'Référence: $reference\n'
      '${driverName != null ? 'Conducteur: $driverName\n' : ''}'
      'Date: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}\n'
      'De: $pickupAddress\n'
      'Vers: $destinationAddress',
    );
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final date = (paidAt ?? DateTime.now()).toLocal();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 40, color: AppColors.success),
                    ),
                    const SizedBox(height: 12),
                    Text('Paiement confirmé',
                        style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('FC ${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.sora(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 24),
                    _ReceiptCard(children: [
                      _ReceiptRow(label: 'Méthode', value: _methodLabel, valueColor: _methodColor),
                      _ReceiptRow(label: 'Référence', value: reference, mono: true),
                      if (driverName != null) _ReceiptRow(label: 'Conducteur', value: driverName!),
                      _ReceiptRow(label: 'Date', value: '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                      _ReceiptRow(label: 'De', value: pickupAddress, maxLines: 2),
                      _ReceiptRow(label: 'Vers', value: destinationAddress, maxLines: 2),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _shareWhatsApp,
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 18, color: AppColors.primary),
                      label: Text('Partager via WhatsApp',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RateDriverScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                      child: Text('Évaluer le conducteur',
                          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final List<Widget> children;
  const _ReceiptCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: AppColors.softShadow,
    ),
    child: Column(children: children),
  );
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;
  final int maxLines;
  const _ReceiptRow({required this.label, required this.value, this.valueColor, this.mono = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: mono
                ? const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)
                : GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary))),
      ],
    ),
  );
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/screens/passenger/payment_receipt_screen.dart
```

Expected: no errors

- [ ] **Step 3: Commit**

```
git add lib/screens/passenger/payment_receipt_screen.dart
git commit -m "feat: add PaymentReceiptScreen with WhatsApp share"
```

---

## Task 13: Flutter — PaymentHistoryScreen + profile entry

**Files:**
- Create: `lib/screens/passenger/payment_history_screen.dart`
- Modify: `lib/screens/passenger/profile_screen.dart`

- [ ] **Step 1: Create PaymentHistoryScreen**

Create `lib/screens/passenger/payment_history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'payment_receipt_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getPaymentHistory();
      setState(() {
        _items = List<Map<String, dynamic>>.from(res.data as List);
        _loading = false;
      });
    } catch (_) {
      setState(() { _error = 'Impossible de charger l\'historique'; _loading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return AppColors.success;
      case 'processing': return Colors.blue;
      case 'failed': return AppColors.error;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid': return 'Payé';
      case 'processing': return 'En cours';
      case 'failed': return 'Échoué';
      default: return 'En attente';
    }
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'airtel_money': return 'Airtel Money';
      case 'mtn_momo': return 'MTN MoMo';
      default: return 'Espèces';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Historique des paiements',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: const Text('Réessayer')),
                ]))
              : _items.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedInvoice01, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('Aucun paiement', style: GoogleFonts.sora(fontSize: 16, color: AppColors.textSecondary)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final status = item['payment_status'] as String? ?? 'pending';
                        final method = item['payment_method'] as String? ?? 'cash';
                        final amount = (item['amount'] as num?)?.toDouble() ?? 0;
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PaymentReceiptScreen(
                              amount: amount,
                              reference: item['payment_reference'] as String? ?? '-',
                              driverName: item['driver_name'] as String?,
                              pickupAddress: item['pickup_address'] as String? ?? '',
                              destinationAddress: item['destination_address'] as String? ?? '',
                              paymentMethod: method,
                            ),
                          )),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const HugeIcon(icon: HugeIcons.strokeRoundedMoney01, size: 22, color: AppColors.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('FC ${amount.toStringAsFixed(0)}',
                                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(_methodLabel(method),
                                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(_statusLabel(status),
                                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(status))),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}
```

- [ ] **Step 2: Add entry in profile screen**

In `lib/screens/passenger/profile_screen.dart`, find the `_ActionTile` for 'Aide & Support' (around line 253). Add before it:

```dart
                      _ActionTile(
                        icon: HugeIcons.strokeRoundedInvoice01,
                        label: 'Historique des paiements',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                        ),
                      ),
                      const _TileDivider(),
```

Add the import at the top of `profile_screen.dart`:

```dart
import 'payment_history_screen.dart';
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/screens/passenger/payment_history_screen.dart lib/screens/passenger/profile_screen.dart
```

Expected: no errors

- [ ] **Step 4: Commit**

```
git add lib/screens/passenger/payment_history_screen.dart lib/screens/passenger/profile_screen.dart
git commit -m "feat: add PaymentHistoryScreen and profile entry point"
```

---

## Task 14: Flutter — trigger payment flow from TripScreen on completion

**Files:**
- Modify: `lib/screens/passenger/trip_screen.dart`

- [ ] **Step 1: Update _onStatusChange to route based on payment method**

In `lib/screens/passenger/trip_screen.dart`, replace the `_onStatusChange` completed block:

```dart
  void _onStatusChange() {
    final ride = ref.read(rideProvider);
    if (ride.rideStatus == RideStatus.completed && mounted) {
      HapticFeedback.mediumImpact();
      final currentRide = ride.currentRide;
      final method = currentRide?.paymentMethod ?? 'cash';
      if (method == 'airtel_money' || method == 'mtn_momo') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AirtelPaymentScreen(
              rideId: currentRide!.id,
              amount: currentRide.price,
              pickupAddress: currentRide.pickup.address,
              destinationAddress: currentRide.destination.address,
              driverName: currentRide.driver?['firstName'],
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RateDriverScreen()),
        );
      }
    }
    if (ride.rideStatus == RideStatus.awaitingConfirmation && mounted) {
      setState(() {});
    }
  }
```

- [ ] **Step 2: Add import**

Add at the top of `trip_screen.dart`:

```dart
import 'airtel_payment_screen.dart';
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/screens/passenger/trip_screen.dart
```

Expected: no errors

- [ ] **Step 4: Commit**

```
git add lib/screens/passenger/trip_screen.dart
git commit -m "feat: route to AirtelPaymentScreen after trip if mobile money selected"
```

---

## Task 15: Flutter — handle payment_received FCM type

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add payment_received case to tap handler**

In `lib/main.dart`, find `NotificationService.setNotificationTapHandler`. Add a case for `payment_received`:

```dart
  NotificationService.setNotificationTapHandler((data) {
    NotificationService.storePendingNotification(data);
    final type = data['type'] as String?;
    if (type == 'new_ride_request') {
      NavigationService.navigateTo(AppRoutes.riderMain);
    } else if (type == 'ride_accepted' || type == 'trip_confirmation_needed') {
      NavigationService.navigateTo(AppRoutes.passengerMain);
    } else if (type == 'chat_message') {
      NavigationService.navigateTo(AppRoutes.passengerMain);
    } else if (type == 'payment_received') {
      NavigationService.navigateTo(AppRoutes.riderMain);
    }
  });
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/main.dart
```

Expected: no errors

- [ ] **Step 3: Commit**

```
git add lib/main.dart
git commit -m "feat: handle payment_received FCM notification for driver"
```

---

## Task 16: Dashboard — wire FinanceDashboard to real data

**Files:**
- Modify: `dashboard/src/pages/FinanceDashboard.jsx`

- [ ] **Step 1: Replace mock stats fetch with real API call**

In `FinanceDashboard.jsx`, find the `useEffect` or data-loading logic (or add one). Replace the `MOCK_STATS` usage:

```jsx
const [stats, setStats] = useState(MOCK_STATS);
const [chart, setChart] = useState(MOCK_CHART);
const [period, setPeriod] = useState('7d');

useEffect(() => {
  api.get(`/admin/finance/stats?period=${period}`)
    .then(r => { if (r.data) setStats(r.data); })
    .catch(() => {});
  api.get(`/admin/finance/chart?period=${period}`)
    .then(r => { if (r.data?.length) setChart(r.data); })
    .catch(() => {});
}, [period]);
```

- [ ] **Step 2: Add payment method breakdown widget**

In the JSX, add after the existing charts section:

```jsx
{/* Payment method breakdown */}
<div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
  <h3 className="text-sm font-semibold text-slate-700 mb-4">Répartition des paiements</h3>
  <div className="space-y-3">
    {stats.by_method && Object.entries(stats.by_method).map(([method, data]) => {
      const label = method === 'airtel_money' ? 'Airtel Money' : method === 'mtn_momo' ? 'MTN MoMo' : 'Espèces';
      const color = method === 'airtel_money' ? '#E02020' : method === 'mtn_momo' ? '#FFC107' : '#10B981';
      const total = Object.values(stats.by_method).reduce((s, v) => s + v.count, 0);
      const pct = total > 0 ? Math.round((data.count / total) * 100) : 0;
      return (
        <div key={method}>
          <div className="flex justify-between text-sm mb-1">
            <span className="font-medium" style={{ color }}>{label}</span>
            <span className="text-slate-500">{data.count} trajets · FC {data.total.toLocaleString()}</span>
          </div>
          <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
            <div className="h-full rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: color }} />
          </div>
        </div>
      );
    })}
  </div>
</div>
```

- [ ] **Step 3: Commit**

```
git add dashboard/src/pages/FinanceDashboard.jsx
git commit -m "feat: wire FinanceDashboard to real API data with payment method breakdown"
```

---

## Task 17: Dashboard — wire Transactions to real data + status controls

**Files:**
- Modify: `dashboard/src/pages/Transactions.jsx`

- [ ] **Step 1: Replace mock data fetch**

In `Transactions.jsx`, find the `useEffect` that calls `api.get('/admin/transactions')`. Update it to pass filter params:

```jsx
const [txns, setTxns] = useState([]);
const [search, setSearch] = useState('');
const [statusFilter, setStatusFilter] = useState('all');
const [methodFilter, setMethodFilter] = useState('all');
const [page, setPage] = useState(1);

const load = useCallback(() => {
  const params = new URLSearchParams({ page });
  if (statusFilter !== 'all') params.append('status', statusFilter);
  if (methodFilter !== 'all') params.append('method', methodFilter);
  if (search) params.append('search', search);
  api.get(`/admin/transactions?${params}`)
    .then(r => { if (r.data) setTxns(r.data); })
    .catch(() => {});
}, [page, statusFilter, methodFilter, search]);

useEffect(() => { load(); }, [load]);
```

- [ ] **Step 2: Add payment status override button**

In the transactions table row JSX, add an action column for `processing` or `failed` rows:

```jsx
{(txn.status === 'processing' || txn.status === 'failed' || txn.status === 'pending') && (
  <div className="flex gap-2">
    <button
      onClick={() => overrideStatus(txn.ride_id, 'paid')}
      className="text-xs px-3 py-1 rounded-full bg-success/10 text-success border border-success/20 hover:bg-success/20 font-medium"
    >
      Marquer payé
    </button>
    {txn.status !== 'failed' && (
      <button
        onClick={() => overrideStatus(txn.ride_id, 'failed')}
        className="text-xs px-3 py-1 rounded-full bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20 font-medium"
      >
        Marquer échoué
      </button>
    )}
  </div>
)}
```

Add the `overrideStatus` function inside the component:

```jsx
const overrideStatus = async (rideId, newStatus) => {
  try {
    await api.patch(`/admin/payments/${rideId}/status`, { status: newStatus });
    setTxns(prev => prev.map(t => t.ride_id === rideId ? { ...t, status: newStatus } : t));
  } catch (e) {
    console.error('Override failed', e);
  }
};
```

- [ ] **Step 3: Commit**

```
git add dashboard/src/pages/Transactions.jsx
git commit -m "feat: wire Transactions to real API with payment status override controls"
```

---

## Final verification

- [ ] **Run full backend test suite**

```bash
cd backend/fastapi_server
pytest -q
```

Expected: all tests passing

- [ ] **Run Flutter analyze**

```bash
flutter analyze
```

Expected: no errors

- [ ] **Run ruff**

```bash
cd backend/fastapi_server
ruff check app
```

Expected: no violations

- [ ] **Final commit**

```
git add .
git commit -m "feat: complete payment integration — Airtel Money + Cash across app, driver, and dashboard"
```
