import uuid
import math
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from ..database import get_db
from ..models.user import User
from ..models.driver import Driver
from ..models.ride import Ride
from ..schemas.ride import CreateRideIn, CancelRideIn, RateRideIn, RideOut, LocationIn, DriverInfo, PassengerInfo
from ..core.dependencies import get_current_user
from ..core.ws_manager import ws_manager
from ..services.notifications import send_push

router = APIRouter(prefix="/rides", tags=["rides"])


async def _build_ride_out(ride: Ride, db: AsyncSession) -> RideOut:
    driver_info = None
    passenger_info = None

    if ride.passenger_id:
        p = await db.get(User, ride.passenger_id)
        if p:
            passenger_info = PassengerInfo(
                id=p.id, first_name=p.first_name, last_name=p.last_name,
                phone=p.phone, profile_image=p.profile_image, rating=float(p.rating),
            )

    if ride.driver_id:
        d = (await db.execute(select(Driver).where(Driver.id == ride.driver_id))).scalar_one_or_none()
        if d:
            du = await db.get(User, d.user_id)
            driver_info = DriverInfo(
                id=d.id, user_id=d.user_id,
                first_name=du.first_name if du else None,
                last_name=du.last_name if du else None,
                phone=du.phone if du else None,
                profile_image=du.profile_image if du else None,
                rating=float(du.rating) if du else None,
                vehicle_make=d.vehicle_make, vehicle_model=d.vehicle_model,
                vehicle_color=d.vehicle_color, vehicle_plate=d.vehicle_plate,
                vehicle_type=d.vehicle_type,
            )

    return RideOut(
        id=ride.id,
        status=ride.status,
        price=float(ride.price),
        distance=float(ride.distance),
        estimated_minutes=ride.estimated_minutes,
        ride_type=ride.ride_type,
        pickup=LocationIn(address=ride.pickup_address, lat=float(ride.pickup_lat), lng=float(ride.pickup_lng)),
        destination=LocationIn(address=ride.destination_address, lat=float(ride.destination_lat), lng=float(ride.destination_lng)),
        driver=driver_info,
        passenger=passenger_info,
        rating=ride.rating,
        rating_comment=ride.rating_comment,
        rating_tags=ride.rating_tags,
        cancel_reason=ride.cancel_reason,
        cancelled_by=ride.cancelled_by,
        payment_method=ride.payment_method,
        payment_status=ride.payment_status,
        payment_reference=ride.payment_reference,
        accepted_at=ride.accepted_at,
        arrived_at=ride.arrived_at,
        started_at=ride.started_at,
        completed_at=ride.completed_at,
        created_at=ride.created_at,
    )


@router.post("", status_code=201)
async def create_ride(
    body: CreateRideIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = Ride(
        passenger_id=current_user.id,
        pickup_address=body.pickup.address,
        pickup_lat=body.pickup.lat,
        pickup_lng=body.pickup.lng,
        destination_address=body.destination.address,
        destination_lat=body.destination.lat,
        destination_lng=body.destination.lng,
        ride_type=body.ride_type,
        price=body.price,
        distance=body.distance,
        estimated_minutes=math.ceil(body.distance * 4),
        payment_method=body.payment_method,
    )
    db.add(ride)
    await db.commit()
    await db.refresh(ride)

    ride_out = await _build_ride_out(ride, db)

    # Broadcast to online drivers
    await ws_manager.emit_to_room(ws_manager.drivers_online_room, "ride:newRequest", {"ride": ride_out.model_dump(mode="json")})

    # FCM to all online drivers
    tokens_result = await db.execute(
        text("SELECT u.fcm_token FROM drivers d JOIN users u ON d.user_id = u.id WHERE d.is_online = true AND u.fcm_token IS NOT NULL AND u.fcm_token != ''")
    )
    tokens = [r[0] for r in tokens_result.fetchall()]
    if tokens:
        await send_push(
            tokens=tokens,
            title="New Ride Request!",
            body=f"{current_user.first_name} needs a ride — {body.pickup.address.split(',')[0]}",
            data={"type": "new_ride_request", "rideId": str(ride.id)},
        )

    return {"ride": ride_out}


@router.get("/my")
async def get_my_rides(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == "rider":
        driver = (await db.execute(select(Driver).where(Driver.user_id == current_user.id))).scalar_one_or_none()
        if not driver:
            return {"rides": []}
        result = await db.execute(select(Ride).where(Ride.driver_id == driver.id).order_by(Ride.created_at.desc()))
    else:
        result = await db.execute(select(Ride).where(Ride.passenger_id == current_user.id).order_by(Ride.created_at.desc()))

    rides = result.scalars().all()
    return {"rides": [await _build_ride_out(r, db) for r in rides]}


@router.get("/{ride_id}")
async def get_ride(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    return {"ride": await _build_ride_out(ride, db)}


@router.put("/{ride_id}/accept")
async def accept_ride(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    driver = (await db.execute(select(Driver).where(Driver.user_id == current_user.id))).scalar_one_or_none()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")

    ride = await db.get(Ride, ride_id)
    if not ride or ride.status != "pending":
        raise HTTPException(status_code=400, detail="Ride no longer available")

    ride.driver_id = driver.id
    ride.status = "accepted"
    ride.accepted_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(ride)

    ride_out = await _build_ride_out(ride, db)
    await ws_manager.emit_to_room(f"ride_{ride_id}", "ride:accepted", {"ride": ride_out.model_dump(mode="json")})

    # FCM to passenger
    passenger = await db.get(User, ride.passenger_id)
    if passenger and passenger.fcm_token:
        await send_push(
            token=passenger.fcm_token,
            title="Ride Accepted!",
            body=f"{current_user.first_name} accepted your ride and is on the way",
            data={"type": "ride_accepted", "rideId": str(ride_id)},
        )

    return {"ride": ride_out}


@router.put("/{ride_id}/arrived")
async def driver_arrived(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    ride.status = "arriving"
    ride.arrived_at = datetime.now(timezone.utc)
    await db.commit()

    await ws_manager.emit_to_room(f"ride_{ride_id}", "ride:driverArrived", {"rideId": str(ride_id)})
    return {"success": True, "rideId": str(ride_id)}


@router.put("/{ride_id}/start")
async def start_ride(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    ride.status = "in_progress"
    ride.started_at = datetime.now(timezone.utc)
    await db.commit()

    await ws_manager.emit_to_room(f"ride_{ride_id}", "ride:started", {"rideId": str(ride_id)})
    return {"success": True, "rideId": str(ride_id)}


@router.put("/{ride_id}/complete")
async def complete_ride(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride or ride.status != "in_progress":
        raise HTTPException(status_code=404, detail="Ride not found or not in progress")

    ride.status = "awaiting_confirmation"
    ride.driver_completed_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(ride)

    ride_out = await _build_ride_out(ride, db)
    await ws_manager.emit_to_room(f"ride_{ride_id}", "ride:awaitingConfirmation", {"ride": ride_out.model_dump(mode="json")})

    passenger = await db.get(User, ride.passenger_id)
    if passenger and passenger.fcm_token:
        await send_push(
            token=passenger.fcm_token,
            title="Trip Complete!",
            body="Your driver ended the trip. Please confirm to complete.",
            data={"type": "trip_confirmation_needed", "rideId": str(ride_id)},
        )

    return {"ride": ride_out}


@router.put("/{ride_id}/passenger-confirm")
async def passenger_confirm_ride(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride or ride.status != "awaiting_confirmation":
        raise HTTPException(status_code=400, detail="Ride not awaiting confirmation")

    ride.status = "completed"
    ride.completed_at = datetime.now(timezone.utc)
    ride.passenger_confirmed_at = datetime.now(timezone.utc)

    # Update earnings and ride counts
    driver = (await db.execute(select(Driver).where(Driver.id == ride.driver_id))).scalar_one_or_none()
    if driver:
        driver.total_earnings = float(driver.total_earnings) + float(ride.price)
        driver.today_earnings = float(driver.today_earnings) + float(ride.price)
        driver.total_rides = driver.total_rides + 1

    current_user.total_rides = current_user.total_rides + 1
    await db.commit()
    await db.refresh(ride)

    ride_out = await _build_ride_out(ride, db)
    await ws_manager.emit_to_room(f"ride_{ride_id}", "ride:completed", {"ride": ride_out.model_dump(mode="json")})

    if driver:
        driver_user = await db.get(User, driver.user_id)
        if driver_user and driver_user.fcm_token:
            await send_push(
                token=driver_user.fcm_token,
                title="Trip Confirmed!",
                body="Passenger confirmed the trip. Earnings updated.",
                data={"type": "trip_confirmed", "rideId": str(ride_id)},
            )

    return {"ride": ride_out}


@router.put("/{ride_id}/cancel")
async def cancel_ride(
    ride_id: uuid.UUID,
    body: CancelRideIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride or ride.status in ("completed", "cancelled"):
        raise HTTPException(status_code=400, detail="Ride cannot be cancelled")

    ride.status = "cancelled"
    ride.cancel_reason = body.reason
    ride.cancelled_by = "driver" if current_user.role == "rider" else "passenger"
    await db.commit()

    await ws_manager.emit_to_room(f"ride_{ride_id}", "ride:cancelled", {"rideId": str(ride_id), "reason": body.reason})
    return {"success": True, "rideId": str(ride_id)}


@router.post("/{ride_id}/rate")
async def rate_ride(
    ride_id: uuid.UUID,
    body: RateRideIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ride = await db.get(Ride, ride_id)
    if not ride or ride.rating is not None:
        raise HTTPException(status_code=404, detail="Ride not found or already rated")

    ride.rating = body.rating
    ride.rating_comment = body.comment
    ride.rating_tags = body.tags or []
    await db.commit()

    # Recalculate driver average
    if ride.driver_id:
        driver = (await db.execute(select(Driver).where(Driver.id == ride.driver_id))).scalar_one_or_none()
        if driver:
            rated_rides = (await db.execute(
                select(Ride).where(Ride.driver_id == ride.driver_id, Ride.status == "completed", Ride.rating.isnot(None))
            )).scalars().all()
            if rated_rides:
                avg = sum(r.rating for r in rated_rides) / len(rated_rides)
                driver.rating = round(avg, 2)
                driver.rating_count = len(rated_rides)
                await db.commit()

    return {"success": True}
