# Payment Integration Design
**Date:** 2026-05-25
**Status:** Approved
**Scope:** Airtel Money + Cash — Mobile app (passenger + driver) + Admin dashboard

---

## Overview

Add end-to-end payment processing to KuboChain. The primary method is **Airtel Money** (most realistic for Goma DRC prototype), with **Cash** as the default fallback. MTN MoMo UI is kept but not wired. Card option is removed. The Airtel API call is **stubbed** (2s delay, mock success) — swappable with real credentials in one function.

---

## 1. Database Changes

New fields on the `rides` table (Alembic migration required):

| Field | Type | Default | Description |
|---|---|---|---|
| `payment_method` | `VARCHAR(20)` | `'cash'` | `airtel_money \| mtn_momo \| cash` |
| `payment_status` | `VARCHAR(20)` | `'pending'` | `pending \| processing \| paid \| failed` |
| `payment_phone` | `TEXT` | `NULL` | Phone number charged |
| `payment_reference` | `TEXT` | `NULL` | Airtel transaction ID (stub: `STUB-<uuid>`) |

---

## 2. Backend

### 2.1 Payment Service (`app/services/payment.py`)

Single async function — stub now, real API later:

```python
async def initiate_payment(phone, amount, ride_id, method) -> dict:
    # STUB: replace body with real Airtel API call when credentials available
    await asyncio.sleep(2)
    return {"reference": f"STUB-{uuid4()}", "status": "paid"}
```

No other code changes when real credentials arrive — only this function body.

### 2.2 Payments Router (`app/routers/payments.py`)

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/api/payments/initiate` | passenger | Triggers payment, updates ride, sends FCM to driver |
| `GET` | `/api/payments/{ride_id}/status` | passenger | Returns `payment_status` + `payment_reference` |
| `GET` | `/api/payments/history` | passenger | Paginated payment history (joined with ride data) |
| `POST` | `/api/payments/callback` | none | Airtel webhook placeholder — logs and returns 200 |

**`POST /api/payments/initiate` body:**
```json
{ "ride_id": "uuid", "phone_number": "+243XXXXXXXXX", "payment_method": "airtel_money" }
```

**`POST /api/payments/initiate` flow:**
1. Validate ride belongs to current user and status is `completed`
2. Set `payment_status = 'processing'`, `payment_phone = phone`
3. Call `payment_service.initiate_payment()`
4. On success: set `payment_status = 'paid'`, `payment_reference = reference`
5. Send FCM to driver: "Paiement reçu — FC {amount} via Airtel Money"
6. Return `{status: 'paid', reference: '...', amount: ...}`

**`GET /api/payments/history` response:**
```json
[{
  "ride_id": "uuid",
  "amount": 5500,
  "payment_method": "airtel_money",
  "payment_status": "paid",
  "payment_reference": "STUB-xxxx",
  "payment_phone": "+243...",
  "pickup_address": "...",
  "destination_address": "...",
  "driver_name": "...",
  "created_at": "2026-05-25T10:00:00Z"
}]
```

### 2.3 Ride Booking Update

`POST /api/rides` — accept optional `payment_method` field (default `cash`). Store on ride at creation.

### 2.4 Admin Endpoints (`app/routers/admin.py` additions)

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/admin/finance/stats?period=7d` | Revenue, commission, earnings, refunds, method breakdown |
| `GET` | `/api/admin/finance/chart?period=7d` | Daily revenue/commission array for chart |
| `GET` | `/api/admin/transactions?page=1&status=&method=&search=` | Paginated transaction list |
| `PATCH` | `/api/admin/payments/{ride_id}/status` | Manual override: set `payment_status` |

**`GET /api/admin/finance/stats` response shape:**
```json
{
  "total_revenue": 4850000,
  "platform_commission": 727500,
  "driver_earnings": 4122500,
  "avg_fare": 5200,
  "total_rides": 932,
  "total_transactions": 1048,
  "by_method": {
    "airtel_money": { "count": 620, "total": 3200000 },
    "cash": { "count": 412, "total": 1650000 }
  }
}
```

---

## 3. Flutter — Passenger App

### 3.1 PaymentScreen changes
- Remove card (`id: 'card'`) from `_methods` list
- Pass selected method back to caller (already working via `Navigator.pop(context, _selectedMethod)`)

### 3.2 Pass payment method on booking
In `ride_provider.dart → requestRide()`: include `payment_method` in POST body.

### 3.3 New: `AirtelPaymentScreen`
**Path:** `lib/screens/passenger/airtel_payment_screen.dart`

States:
- **Idle** — amount display, phone input (pre-filled from `auth.user.phone`), "Payer maintenant" button
- **Processing** — disabled button, spinner, "Traitement en cours..."
- **Success** — green checkmark, amount confirmed → auto-navigate to `PaymentReceiptScreen` after 1.5s
- **Failed** — red icon, error message, "Réessayer" button (max 3 attempts), after 3 failures show "Contactez le support"

Triggered from `TripScreen._onStatusChange()` when `rideStatus == completed` and `payment_method == 'airtel_money'`.

### 3.4 New: `PaymentReceiptScreen`
**Path:** `lib/screens/passenger/payment_receipt_screen.dart`

Displays:
- KuboChain logo + "Paiement confirmé ✓"
- Amount in FC (large, prominent)
- Reference number
- Driver name
- Date + time
- Route: pickup → destination
- Payment method badge (Airtel red / Cash green)

Actions:
- **"Partager via WhatsApp"** — opens WhatsApp with pre-filled message using `url_launcher`:
  ```
  KuboChain — Reçu de paiement
  Montant: FC [amount]
  Référence: [reference]
  Conducteur: [driver]
  [date]
  ```
- **"Évaluer le conducteur"** — navigates to `RateDriverScreen`

Accessible from: post-payment flow AND `PaymentHistoryScreen` (tap any entry).

### 3.5 New: `PaymentHistoryScreen`
**Path:** `lib/screens/passenger/payment_history_screen.dart`

- Calls `GET /api/payments/history`
- List items: method icon + label | amount | status badge | date
- Status badge colors: paid=green, pending=amber, processing=blue, failed=red
- Tap → `PaymentReceiptScreen`
- Entry point: passenger profile screen → "Historique des paiements" row

### 3.6 New API service methods
In `lib/core/services/api_service.dart`:
- `static Future<Map> initiatePayment({rideId, phone, method})`
- `static Future<Map> getPaymentStatus(String rideId)`
- `static Future<List> getPaymentHistory()`

---

## 4. Flutter — Driver App

### 4.1 FCM notification on payment confirmed
- Backend sends FCM when `payment_status` transitions to `paid`
- Notification: title "Paiement reçu", body "FC [amount] via Airtel Money — [passenger name]"
- `type: 'payment_received'` in FCM data
- `main.dart` tap handler: navigate to `RiderMain` (earnings tab)

### 4.2 Earnings screen
- Payment method badge next to each ride entry (already has ride list)
- No structural changes needed — just add method display

---

## 5. Admin Dashboard (React)

### 5.1 `FinanceDashboard.jsx` — wire real data
- Replace `MOCK_STATS` with `GET /api/admin/finance/stats`
- Replace `MOCK_CHART` with `GET /api/admin/finance/chart`
- Add **payment method breakdown** pie/bar: Airtel Money vs Cash (% and FC totals)
- Period selector already implemented — pass as query param

### 5.2 `Transactions.jsx` — wire real data
- Replace `MOCK_TXN` with `GET /api/admin/transactions`
- Update method filter: `airtel_money | mtn_momo | cash`
- Method badge colors: Airtel=red, Cash=green, MoMo=yellow

### 5.3 New: Payment status controls in `Transactions.jsx`
- Rows with `processing` or `failed` status show action buttons: "Marquer payé" / "Marquer échoué"
- Calls `PATCH /api/admin/payments/{ride_id}/status`
- Inline status update (no page reload)

---

## 6. Error Handling

| Scenario | Behavior |
|---|---|
| Payment initiation fails (network) | Show retry button, preserve phone input |
| 3 retries exhausted | Show "Contactez le support" message |
| Ride not found / already paid | Return 409, show "Ce trajet a déjà été payé" |
| Ride not completed | Return 400, show generic error |
| FCM to driver fails | Log silently — payment still succeeds |

---

## 7. Stub → Real Airtel API Migration

When credentials arrive, only `app/services/payment.py → initiate_payment()` changes:

```python
# Replace stub body with:
async with httpx.AsyncClient() as client:
    token = await _get_airtel_token()
    resp = await client.post(
        f"{AIRTEL_BASE_URL}/merchant/v2/payments/",
        headers={"Authorization": f"Bearer {token}"},
        json={"reference": str(ride_id), "subscriber": {"country": "CD", "currency": "CDF", "msisdn": phone}, "transaction": {"amount": amount, "country": "CD", "currency": "CDF", "id": str(ride_id)}}
    )
    return resp.json()
```

No other files change.

---

## 8. Files Touched Summary

**Backend (new/modified):**
- `app/models/ride.py` — 4 new fields
- `app/services/payment.py` — new file
- `app/routers/payments.py` — new file
- `app/routers/rides.py` — accept `payment_method` on create
- `app/routers/admin.py` — 4 new endpoints
- `alembic/versions/xxxx_add_payment_fields.py` — new migration

**Flutter (new/modified):**
- `lib/screens/passenger/payment_screen.dart` — remove card
- `lib/screens/passenger/airtel_payment_screen.dart` — new
- `lib/screens/passenger/payment_receipt_screen.dart` — new
- `lib/screens/passenger/payment_history_screen.dart` — new
- `lib/screens/passenger/trip_screen.dart` — trigger payment screen on complete
- `lib/screens/passenger/profile_screen.dart` — add payment history entry
- `lib/providers/ride_provider.dart` — pass payment_method on booking
- `lib/core/services/api_service.dart` — 3 new methods
- `lib/main.dart` — handle `payment_received` FCM type

**Dashboard (modified):**
- `dashboard/src/pages/FinanceDashboard.jsx` — real data + method breakdown
- `dashboard/src/pages/Transactions.jsx` — real data + status controls
