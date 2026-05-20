from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from ..database import get_db
from ..models.user import User
from ..models.driver import Driver
from ..models.ride import Ride
from ..schemas.driver import (
    UpdateLocationIn, ToggleAvailabilityIn, UpdateVehicleIn,
    DriverOut, EarningsOut, TopRiderOut,
)
from ..core.dependencies import get_current_user, rider_only
from ..core.ws_manager import ws_manager

router = APIRouter(prefix="/drivers", tags=["drivers"])


def _driver_to_out(driver: Driver, user: User) -> DriverOut:
    return DriverOut(
        id=driver.id,
        user_id=driver.user_id,
        first_name=user.first_name,
        last_name=user.last_name,
        phone=user.phone,
        profile_image=user.profile_image,
        vehicle_make=driver.vehicle_make,
        vehicle_model=driver.vehicle_model,
        vehicle_color=driver.vehicle_color,
        vehicle_plate=driver.vehicle_plate,
        vehicle_type=driver.vehicle_type,
        is_online=driver.is_online,
        is_verified=driver.is_verified,
        rating=float(driver.rating),
        rating_count=driver.rating_count,
        total_rides=driver.total_rides,
        lat=float(driver.lat) if driver.lat else None,
        lng=float(driver.lng) if driver.lng else None,
    )


@router.get("/top-rated")
async def get_top_rated(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("""
        SELECT
            d.id, d.rating, d.rating_count, d.total_rides, d.total_earnings,
            d.vehicle_make, d.vehicle_model, d.vehicle_plate, d.vehicle_type, d.is_online,
            u.first_name, u.last_name, u.profile_image,
            (SELECT COUNT(*) FROM rides r WHERE r.driver_id = d.id AND r.status='completed' AND r.rating=5) AS five_star_count
        FROM drivers d
        JOIN users u ON d.user_id = u.id
        WHERE d.rating_count > 0
        ORDER BY d.rating DESC NULLS LAST, d.rating_count DESC
        LIMIT 20
    """))
    rows = result.fetchall()
    riders = [
        TopRiderOut(
            rank=i + 1,
            id=r[0],
            rating=float(r[1] or 0),
            rating_count=int(r[2] or 0),
            total_rides=int(r[3] or 0),
            total_earnings=float(r[4] or 0),
            vehicle_make=r[5] or "",
            vehicle_model=r[6] or "",
            vehicle_plate=r[7] or "",
            vehicle_type=r[8] or "",
            is_online=bool(r[9]),
            first_name=r[10] or "",
            last_name=r[11] or "",
            profile_image=r[12],
            five_star_count=int(r[13] or 0),
            name=f"{r[10] or ''} {r[11] or ''}".strip(),
            vehicle=f"{r[5] or ''} {r[6] or ''}".strip(),
            top_tags=[],
        )
        for i, r in enumerate(rows)
    ]
    return {"riders": riders}


@router.get("/nearby")
async def get_nearby_drivers(
    lat: float,
    lng: float,
    max_distance: int = 5000,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(text("""
        SELECT
            d.id, d.user_id, d.vehicle_make, d.vehicle_model, d.vehicle_color,
            d.vehicle_plate, d.vehicle_type, d.is_online, d.is_verified,
            d.rating, d.rating_count, d.total_rides, d.lat, d.lng,
            u.first_name, u.last_name, u.phone, u.profile_image,
            (6371000 * acos(LEAST(1.0,
                cos(radians(:lat)) * cos(radians(d.lat::float)) *
                cos(radians(d.lng::float) - radians(:lng)) +
                sin(radians(:lat)) * sin(radians(d.lat::float))
            ))) AS distance_m
        FROM drivers d
        JOIN users u ON d.user_id = u.id
        WHERE d.is_online = true AND d.lat IS NOT NULL AND d.lng IS NOT NULL
          AND (6371000 * acos(LEAST(1.0,
                cos(radians(:lat)) * cos(radians(d.lat::float)) *
                cos(radians(d.lng::float) - radians(:lng)) +
                sin(radians(:lat)) * sin(radians(d.lat::float))
               ))) <= :max_distance
        ORDER BY distance_m
        LIMIT 20
    """), {"lat": lat, "lng": lng, "max_distance": max_distance})

    rows = result.fetchall()
    drivers = [
        DriverOut(
            id=r[0], user_id=r[1], vehicle_make=r[2], vehicle_model=r[3],
            vehicle_color=r[4], vehicle_plate=r[5], vehicle_type=r[6],
            is_online=r[7], is_verified=r[8], rating=float(r[9] or 5),
            rating_count=int(r[10] or 0), total_rides=int(r[11] or 0),
            lat=float(r[12]) if r[12] else None,
            lng=float(r[13]) if r[13] else None,
            first_name=r[14], last_name=r[15], phone=r[16], profile_image=r[17],
        )
        for r in rows
    ]
    return {"drivers": drivers}


@router.put("/location")
async def update_location(
    body: UpdateLocationIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(rider_only),
):
    driver = (await db.execute(select(Driver).where(Driver.user_id == current_user.id))).scalar_one_or_none()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    driver.lat = body.lat
    driver.lng = body.lng
    await db.commit()

    # Broadcast location to active ride room
    active_ride = (await db.execute(
        select(Ride).where(
            Ride.driver_id == driver.id,
            Ride.status.in_(["accepted", "arriving", "in_progress"]),
        ).limit(1)
    )).scalar_one_or_none()

    if active_ride:
        await ws_manager.emit_to_room(
            f"ride_{active_ride.id}",
            "ride:driverLocation",
            {"lat": body.lat, "lng": body.lng, "rideId": str(active_ride.id)},
        )

    return {"success": True}


@router.put("/availability")
async def toggle_availability(
    body: ToggleAvailabilityIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(rider_only),
):
    driver = (await db.execute(select(Driver).where(Driver.user_id == current_user.id))).scalar_one_or_none()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    driver.is_online = body.is_online
    await db.commit()

    return {"driver": _driver_to_out(driver, current_user)}


@router.put("/vehicle")
async def update_vehicle(
    body: UpdateVehicleIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(rider_only),
):
    driver = (await db.execute(select(Driver).where(Driver.user_id == current_user.id))).scalar_one_or_none()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    if body.vehicle_make is not None:
        driver.vehicle_make = body.vehicle_make
    if body.vehicle_model is not None:
        driver.vehicle_model = body.vehicle_model
    if body.vehicle_plate is not None:
        driver.vehicle_plate = body.vehicle_plate
    if body.vehicle_color is not None:
        driver.vehicle_color = body.vehicle_color
    if body.vehicle_type is not None:
        driver.vehicle_type = body.vehicle_type

    await db.commit()
    return {"message": "Vehicle updated"}


@router.get("/earnings")
async def get_earnings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(rider_only),
):
    driver = (await db.execute(select(Driver).where(Driver.user_id == current_user.id))).scalar_one_or_none()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    # Reset today_earnings if it's a new day
    today = date.today()
    if driver.last_earnings_reset != today:
        driver.today_earnings = 0
        driver.last_earnings_reset = today
        await db.commit()

    recent_rides = (await db.execute(
        select(Ride)
        .where(Ride.driver_id == driver.id, Ride.status == "completed")
        .order_by(Ride.completed_at.desc())
        .limit(20)
    )).scalars().all()

    from ..routers.rides import _build_ride_out
    rides_out = [await _build_ride_out(r, db) for r in recent_rides]

    return EarningsOut(
        today_earnings=float(driver.today_earnings),
        total_earnings=float(driver.total_earnings),
        total_rides=driver.total_rides,
        recent_rides=[r.model_dump(mode="json") for r in rides_out],
    )
