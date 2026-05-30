import uuid
import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select, func, or_
from ..database import get_db
from ..models.user import User
from ..models.driver import Driver
from ..models.ride import Ride
from ..models.promotion import Promotion
from ..models.surge import SurgeZone, SurgeRule
from ..models.campaign import Campaign
from ..models.audit_log import AuditLog
from ..core.dependencies import admin_only
from ..services.notifications import send_push


async def _audit(db: AsyncSession, action: str, admin: User, target: str, meta: dict = None):
    log = AuditLog(action=action, admin=f"Admin {admin.first_name}", admin_id=admin.id, target=target, meta=meta or {})
    db.add(log)
    await db.flush()

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


@router.delete("/drivers/{driver_id}", status_code=204)
async def delete_driver(
    driver_id: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(admin_only),
):
    driver = await db.get(Driver, uuid.UUID(driver_id))
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")
    user = await db.get(User, driver.user_id)
    await _audit(db, "driver_deleted", admin, f"Driver {driver_id}", {"user_id": str(driver.user_id)})
    await db.delete(driver)
    if user:
        user.is_active = False
    await db.commit()


def _user_out(u: User) -> dict:
    return {
        "id": str(u.id),
        "firstName": u.first_name,
        "lastName": u.last_name,
        "email": u.email,
        "phone": u.phone,
        "role": u.role,
        "status": "active" if u.is_active else "suspended",
        "rating": float(u.rating),
        "totalRides": u.total_rides,
        "createdAt": u.created_at.isoformat() if u.created_at else None,
        "isVerified": u.is_active,
    }


@router.get("/users")
async def get_all_users(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
    role: str = "",
    search: str = "",
):
    q = select(User)
    if role:
        q = q.where(User.role == role)
    if search:
        s = f"%{search}%"
        q = q.where(or_(
            User.first_name.ilike(s), User.last_name.ilike(s),
            User.email.ilike(s), User.phone.ilike(s),
        ))
    result = await db.execute(q.order_by(User.created_at.desc()).limit(200))
    return {"users": [_user_out(u) for u in result.scalars().all()]}


@router.get("/users/{user_id}")
async def get_user_by_id(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    user = await db.get(User, uuid.UUID(user_id))
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    rides_result = await db.execute(
        select(Ride).where(Ride.passenger_id == user.id).order_by(Ride.created_at.desc()).limit(10)
    )
    rides = rides_result.scalars().all()
    return {
        "user": _user_out(user),
        "recentRides": [
            {
                "id": str(r.id),
                "destination_address": r.destination_address,
                "status": r.status,
                "price": float(r.price or 0),
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in rides
        ],
    }


@router.patch("/users/{user_id}/{action}")
async def user_action(
    user_id: str,
    action: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(admin_only),
):
    user = await db.get(User, uuid.UUID(user_id))
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if action == "suspend":
        user.is_active = False
    elif action == "activate":
        user.is_active = True
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
    await _audit(db, f"user_{action}", admin, user_id, {})
    await db.commit()
    return _user_out(user)


@router.delete("/users/{user_id}", status_code=204)
async def delete_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(admin_only),
):
    user = await db.get(User, uuid.UUID(user_id))
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await _audit(db, "user_deleted", admin, user_id, {"email": user.email})
    await db.delete(user)
    await db.commit()


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


# ── Promotions ─────────────────────────────────────────────────────────────────

def _promo_out(p: Promotion) -> dict:
    return {
        "id": str(p.id), "code": p.code, "type": p.type,
        "discount": float(p.discount), "min_fare": float(p.min_fare),
        "max_uses": p.max_uses, "used": p.used, "active": p.active,
        "expires": str(p.expires) if p.expires else None,
        "description": p.description,
    }


@router.get("/promotions")
async def list_promotions(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(Promotion).order_by(Promotion.created_at.desc()))
    return [_promo_out(p) for p in result.scalars().all()]


@router.post("/promotions", status_code=201)
async def create_promotion(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    p = Promotion(
        code=body["code"].upper().strip(),
        type=body.get("type", "percentage"),
        discount=float(body.get("discount", 0)),
        min_fare=float(body.get("min_fare", 0)),
        max_uses=int(body.get("max_uses", 100)),
        expires=body.get("expires") or None,
        description=body.get("description", ""),
    )
    db.add(p)
    await _audit(db, "promo_created", admin, f"Promo {p.code}", {"code": p.code})
    await db.commit()
    await db.refresh(p)
    return _promo_out(p)


@router.patch("/promotions/{promo_id}")
async def update_promotion(promo_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    p = await db.get(Promotion, uuid.UUID(promo_id))
    if not p:
        raise HTTPException(404, "Promo not found")
    for field in ("code", "type", "discount", "min_fare", "max_uses", "expires", "description", "active"):
        if field in body:
            val = body[field]
            if field == "code":
                val = val.upper().strip()
            if field in ("discount", "min_fare"):
                val = float(val)
            if field == "max_uses":
                val = int(val)
            setattr(p, field, val)
    await _audit(db, "promo_updated", admin, f"Promo {p.code}", body)
    await db.commit()
    return _promo_out(p)


@router.delete("/promotions/{promo_id}", status_code=204)
async def delete_promotion(promo_id: str, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    p = await db.get(Promotion, uuid.UUID(promo_id))
    if not p:
        raise HTTPException(404, "Promo not found")
    await _audit(db, "promo_deleted", admin, f"Promo {p.code}", {"code": p.code})
    await db.delete(p)
    await db.commit()


# ── Surge Pricing ──────────────────────────────────────────────────────────────

def _zone_out(z: SurgeZone) -> dict:
    return {
        "id": str(z.id), "name": z.name, "active": z.active,
        "multiplier": float(z.multiplier), "trigger": z.trigger,
        "expires_at": z.expires_at.isoformat() if z.expires_at else None,
    }


def _rule_out(r: SurgeRule) -> dict:
    return {
        "id": str(r.id), "name": r.name, "schedule": r.schedule,
        "multiplier": float(r.multiplier), "enabled": r.enabled,
        "zones": json.loads(r.zones),
    }


@router.get("/surge/zones")
async def list_surge_zones(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(SurgeZone).order_by(SurgeZone.created_at))
    return [_zone_out(z) for z in result.scalars().all()]


@router.post("/surge/zones", status_code=201)
async def create_surge_zone(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    z = SurgeZone(
        name=body["name"],
        multiplier=float(body.get("multiplier", 1.5)),
        trigger=body.get("trigger", "manual"),
    )
    db.add(z)
    await _audit(db, "surge_zone_created", admin, f"Zone {z.name}", {"name": z.name})
    await db.commit()
    await db.refresh(z)
    return _zone_out(z)


@router.patch("/surge/zones/{zone_id}")
async def update_surge_zone(zone_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    z = await db.get(SurgeZone, uuid.UUID(zone_id))
    if not z:
        raise HTTPException(404, "Zone not found")
    for field in ("active", "multiplier", "trigger", "expires_at"):
        if field in body:
            setattr(z, field, body[field])
    if body.get("active"):
        await _audit(db, "surge_activated", admin, f"Zone {z.name}", {"multiplier": float(z.multiplier)})
    await db.commit()
    return _zone_out(z)


@router.get("/surge/rules")
async def list_surge_rules(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(SurgeRule).order_by(SurgeRule.created_at))
    return [_rule_out(r) for r in result.scalars().all()]


@router.patch("/surge/rules/{rule_id}")
async def update_surge_rule(rule_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    r = await db.get(SurgeRule, uuid.UUID(rule_id))
    if not r:
        raise HTTPException(404, "Rule not found")
    for field in ("enabled", "multiplier", "name", "schedule"):
        if field in body:
            setattr(r, field, body[field])
    await db.commit()
    return _rule_out(r)


@router.post("/surge/global")
async def set_global_surge(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    active = body.get("active", False)
    multiplier = float(body.get("multiplier", 1.5))
    result = await db.execute(select(SurgeZone))
    zones = result.scalars().all()
    for z in zones:
        z.active = active
        if active:
            z.multiplier = multiplier
    await _audit(db, "surge_activated" if active else "surge_deactivated", admin,
                 "All Zones", {"multiplier": multiplier, "active": active})
    await db.commit()
    return {"updated": len(zones), "active": active, "multiplier": multiplier}


# ── Campaigns ─────────────────────────────────────────────────────────────────

def _campaign_out(c: Campaign) -> dict:
    return {
        "id": str(c.id), "name": c.name, "type": c.type, "target": c.target,
        "status": c.status,
        "start": str(c.start) if c.start else None,
        "end": str(c.end) if c.end else None,
        "reach": c.reach, "conversions": c.conversions,
        "budget": float(c.budget), "spent": float(c.spent),
    }


@router.get("/campaigns")
async def list_campaigns(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(Campaign).order_by(Campaign.created_at.desc()))
    return [_campaign_out(c) for c in result.scalars().all()]


@router.post("/campaigns", status_code=201)
async def create_campaign(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    c = Campaign(
        name=body["name"],
        type=body.get("type", "push"),
        target=body.get("target", "all_users"),
        status=body.get("status", "active"),
        start=body.get("start") or None,
        end=body.get("end") or None,
        budget=float(body.get("budget", 0)),
    )
    db.add(c)
    await _audit(db, "campaign_created", admin, f"Campaign {c.name}", {"type": c.type})
    await db.commit()
    await db.refresh(c)
    return _campaign_out(c)


@router.patch("/campaigns/{campaign_id}")
async def update_campaign(campaign_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    c = await db.get(Campaign, uuid.UUID(campaign_id))
    if not c:
        raise HTTPException(404, "Campaign not found")
    for field in ("status", "name", "reach", "conversions", "spent"):
        if field in body:
            setattr(c, field, body[field])
    await db.commit()
    return _campaign_out(c)


@router.delete("/campaigns/{campaign_id}", status_code=204)
async def delete_campaign(campaign_id: str, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    c = await db.get(Campaign, uuid.UUID(campaign_id))
    if not c:
        raise HTTPException(404, "Campaign not found")
    await db.delete(c)
    await db.commit()


# ── Audit Log ─────────────────────────────────────────────────────────────────

@router.get("/audit")
async def get_audit_log(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(AuditLog).order_by(AuditLog.created_at.desc()).limit(200))
    return [
        {
            "id": str(l.id), "action": l.action, "admin": l.admin,
            "target": log.target, "meta": log.meta,
            "created_at": log.created_at.isoformat(),
        }
        for log in result.scalars().all()
    ]


# ── Dispatch — online drivers ──────────────────────────────────────────────────

@router.get("/drivers/online")
async def get_online_drivers(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(
        select(Driver, User)
        .join(User, Driver.user_id == User.id)
        .where(Driver.is_online == True)  # noqa: E712
    )
    rows = result.all()
    return [
        {
            "id": str(d.id),
            "name": f"{u.first_name} {u.last_name}".strip(),
            "status": "busy" if d.total_rides > 0 else "online",
            "lat": float(d.lat) if d.lat else None,
            "lng": float(d.lng) if d.lng else None,
            "rides_today": d.total_rides,
        }
        for d, u in rows
        if d.lat and d.lng
    ]
