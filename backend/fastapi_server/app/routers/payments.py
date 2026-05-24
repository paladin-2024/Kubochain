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

_TERMINAL_STATUSES = frozenset({"paid", "processing"})
_VALID_PAYMENT_STATUSES = frozenset({"paid", "failed", "pending", "processing"})


@router.post("/initiate", response_model=PaymentInitiateOut)
async def initiate(
    body: PaymentInitiateIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # with_for_update() locks the row so concurrent requests serialise here
    result = await db.execute(
        select(Ride).where(Ride.id == body.ride_id).with_for_update()
    )
    ride = result.scalar_one_or_none()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    if ride.passenger_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your ride")
    if ride.status != "completed":
        raise HTTPException(status_code=400, detail="Ride is not completed")
    if ride.payment_status in _TERMINAL_STATUSES:
        raise HTTPException(status_code=409, detail="Ce trajet a déjà été payé")

    ride.payment_status = "processing"
    ride.payment_phone = body.phone_number
    ride.payment_method = body.payment_method
    await db.commit()

    try:
        service_result = await initiate_payment(
            body.phone_number, float(ride.price), str(ride.id), body.payment_method
        )
    except Exception as exc:
        ride.payment_status = "failed"
        await db.commit()
        _log.error("payment_service error ride=%s: %s", ride.id, exc)
        raise HTTPException(status_code=502, detail="Service de paiement indisponible")

    raw_status = service_result.get("status", "failed")
    ride.payment_status = raw_status if raw_status in _VALID_PAYMENT_STATUSES else "failed"
    ride.payment_reference = service_result.get("reference")
    await db.commit()

    _log.info("payment_complete ride=%s method=%s status=%s", ride.id, body.payment_method, ride.payment_status)

    if ride.driver_id:
        driver = (await db.execute(select(Driver).where(Driver.id == ride.driver_id))).scalar_one_or_none()
        if driver:
            driver_user = await db.get(User, driver.user_id)
            if driver_user and driver_user.fcm_token:
                try:
                    await send_push(
                        token=driver_user.fcm_token,
                        title="Paiement reçu",
                        body=f"FC {float(ride.price):.0f} via Airtel Money — {current_user.first_name}",
                        data={"type": "payment_received", "ride_id": str(ride.id)},
                    )
                except Exception:
                    _log.warning("FCM failed for driver %s — payment still succeeded", driver.id)

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
    """Airtel Money webhook — placeholder, logs and acknowledges.

    PRODUCTION REQUIREMENT: Before going live, verify the Airtel Money
    HMAC-SHA256 signature from the X-Airtel-Signature header against the
    shared secret to prevent spoofed callbacks from marking rides as paid.
    """
    try:
        body = await request.json()
        _log.info("airtel_callback body=%s", body)
    except Exception:
        pass
    return {"status": "received"}
