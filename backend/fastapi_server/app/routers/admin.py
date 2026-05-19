from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select, func
from ..database import get_db
from ..models.user import User
from ..models.driver import Driver
from ..models.ride import Ride
from ..core.dependencies import admin_only
from ..services.notifications import send_push

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/stats")
async def get_stats(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    total_users = (await db.execute(select(func.count(User.id)))).scalar()
    total_drivers = (await db.execute(select(func.count(Driver.id)))).scalar()
    total_rides = (await db.execute(select(func.count(Ride.id)))).scalar()
    active_rides = (await db.execute(
        select(func.count(Ride.id)).where(Ride.status.in_(["pending", "accepted", "arriving", "in_progress"]))
    )).scalar()
    completed_rides = (await db.execute(
        select(func.count(Ride.id)).where(Ride.status == "completed")
    )).scalar()
    total_revenue = (await db.execute(
        select(func.sum(Ride.price)).where(Ride.status == "completed")
    )).scalar() or 0
    online_drivers = (await db.execute(
        select(func.count(Driver.id)).where(Driver.is_online == True)  # noqa: E712
    )).scalar()

    return {
        "totalUsers": total_users,
        "totalDrivers": total_drivers,
        "totalRides": total_rides,
        "activeRides": active_rides,
        "completedRides": completed_rides,
        "totalRevenue": float(total_revenue),
        "onlineDrivers": online_drivers,
    }


@router.get("/rides")
async def get_all_rides(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    result = await db.execute(select(Ride).order_by(Ride.created_at.desc()).limit(100))
    rides = result.scalars().all()
    from ..routers.rides import _build_ride_out
    return {"rides": [await _build_ride_out(r, db) for r in rides]}


@router.get("/rides/active")
async def get_active_rides(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    result = await db.execute(
        select(Ride)
        .where(Ride.status.in_(["pending", "accepted", "arriving", "in_progress"]))
        .order_by(Ride.created_at.desc())
    )
    rides = result.scalars().all()
    from ..routers.rides import _build_ride_out
    return {"rides": [await _build_ride_out(r, db) for r in rides]}


@router.get("/drivers")
async def get_all_drivers(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    result = await db.execute(
        select(Driver, User).join(User, Driver.user_id == User.id).order_by(Driver.created_at.desc())
    )
    rows = result.all()
    from ..routers.drivers import _driver_to_out
    return {"drivers": [_driver_to_out(d, u) for d, u in rows]}


@router.get("/users")
async def get_all_users(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    result = await db.execute(select(User).order_by(User.created_at.desc()).limit(200))
    users = result.scalars().all()
    from ..schemas.auth import UserOut
    return {"users": [UserOut.model_validate(u) for u in users]}


@router.get("/users/{user_id}")
async def get_user_by_id(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    import uuid
    user = await db.get(User, uuid.UUID(user_id))
    if not user:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="User not found")
    from ..schemas.auth import UserOut
    return {"user": UserOut.model_validate(user)}


@router.get("/reports")
async def get_reports(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    result = await db.execute(text("""
        SELECT
            DATE_TRUNC('day', created_at) AS day,
            COUNT(*) AS total,
            COUNT(*) FILTER (WHERE status = 'completed') AS completed,
            COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled,
            COALESCE(SUM(price) FILTER (WHERE status = 'completed'), 0) AS revenue
        FROM rides
        WHERE created_at >= NOW() - INTERVAL '30 days'
        GROUP BY day
        ORDER BY day DESC
    """))
    rows = result.fetchall()
    return {
        "daily": [
            {"date": str(r[0])[:10], "total": r[1], "completed": r[2], "cancelled": r[3], "revenue": float(r[4])}
            for r in rows
        ]
    }


@router.get("/top-riders")
async def get_top_riders(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    from ..routers.drivers import get_top_rated
    return await get_top_rated(db)


@router.post("/notifications")
async def send_admin_notification(
    body: dict,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    title = body.get("title", "KuboChain")
    message = body.get("message", "")
    role = body.get("role")

    query = select(User).where(User.fcm_token.isnot(None), User.fcm_token != "")
    if role:
        query = query.where(User.role == role)

    result = await db.execute(query)
    users = result.scalars().all()
    tokens = [u.fcm_token for u in users if u.fcm_token]

    if tokens:
        await send_push(tokens=tokens, title=title, body=message, data={"type": "admin_notification"})

    return {"sent": len(tokens)}


@router.get("/notifications/history")
async def get_notification_history(_: User = Depends(admin_only)):
    return {"notifications": []}
