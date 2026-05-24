"""
Extra admin endpoints — banners, versions, feature flags, zones, config,
support tickets, incidents, SOS, payouts, staff, referrals, finance, health.
"""
import uuid
import time
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, text
from ..database import get_db
from ..models.user import User
from ..models.driver import Driver
from ..models.ride import Ride
from ..models.ops import AppBanner, AppVersion, FeatureFlag, Zone
from ..models.support_models import SupportTicket, Incident, SosReport
from ..models.payout import Payout
from ..models.platform_config import PlatformConfig
from ..models.audit_log import AuditLog
from ..core.dependencies import admin_only
from .admin import _audit

router = APIRouter(prefix="/admin", tags=["admin-extras"])

_START = time.time()


# ── App Banners ───────────────────────────────────────────────────────────────

def _banner_out(b: AppBanner) -> dict:
    return {
        "id": str(b.id), "title": b.title, "subtitle": b.subtitle,
        "cta": b.cta, "cta_link": b.cta_link, "audience": b.audience,
        "placement": b.placement, "active": b.active,
        "start": str(b.start) if b.start else None,
        "end": str(b.end) if b.end else None,
        "impressions": b.impressions, "taps": b.taps,
        "bg_color": b.bg_color, "text_color": b.text_color,
    }


@router.get("/banners")
async def list_banners(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(AppBanner).order_by(AppBanner.created_at.desc()))
    return [_banner_out(b) for b in result.scalars().all()]


@router.post("/banners", status_code=201)
async def create_banner(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    b = AppBanner(
        title=body["title"], subtitle=body.get("subtitle", ""),
        cta=body.get("cta", ""), cta_link=body.get("cta_link", ""),
        audience=body.get("audience", "all"), placement=body.get("placement", "home"),
        start=body.get("start") or None, end=body.get("end") or None,
        bg_color=body.get("bg_color", "#1A3A6E"), text_color=body.get("text_color", "#FFFFFF"),
    )
    db.add(b)
    await _audit(db, "banner_created", admin, f"Banner: {b.title}", {})
    await db.commit()
    await db.refresh(b)
    return _banner_out(b)


@router.patch("/banners/{banner_id}")
async def update_banner(banner_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    b = await db.get(AppBanner, uuid.UUID(banner_id))
    if not b:
        raise HTTPException(404, "Banner not found")
    for f in ("title", "subtitle", "cta", "cta_link", "audience", "placement", "active", "start", "end", "bg_color", "text_color"):
        if f in body:
            setattr(b, f, body[f])
    await db.commit()
    return _banner_out(b)


@router.delete("/banners/{banner_id}", status_code=204)
async def delete_banner(banner_id: str, db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    b = await db.get(AppBanner, uuid.UUID(banner_id))
    if not b:
        raise HTTPException(404, "Banner not found")
    await db.delete(b)
    await db.commit()


# ── App Versions ─────────────────────────────────────────────────────────────

def _version_out(v: AppVersion) -> dict:
    return {
        "id": str(v.id), "platform": v.platform, "user_type": v.user_type,
        "version": v.version, "build": v.build, "min_version": v.min_version,
        "force_update": v.force_update, "latest": v.latest,
        "changelog": v.changelog,
        "released_at": str(v.released_at) if v.released_at else None,
    }


@router.get("/versions")
async def list_versions(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(AppVersion).order_by(AppVersion.created_at.desc()))
    return [_version_out(v) for v in result.scalars().all()]


@router.post("/versions", status_code=201)
async def create_version(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    v = AppVersion(
        platform=body["platform"], user_type=body.get("user_type", "passenger"),
        version=body["version"], build=int(body.get("build", 1)),
        min_version=body.get("min_version", "1.0.0"),
        force_update=body.get("force_update", False),
        changelog=body.get("changelog", ""),
        released_at=body.get("released_at") or None,
    )
    db.add(v)
    await _audit(db, "version_published", admin, f"v{v.version} ({v.platform})", {})
    await db.commit()
    await db.refresh(v)
    return _version_out(v)


@router.patch("/versions/{version_id}")
async def update_version(version_id: str, body: dict, db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    v = await db.get(AppVersion, uuid.UUID(version_id))
    if not v:
        raise HTTPException(404, "Version not found")
    for f in ("force_update", "latest", "changelog", "min_version"):
        if f in body:
            setattr(v, f, body[f])
    await db.commit()
    return _version_out(v)


# ── Feature Flags ─────────────────────────────────────────────────────────────

def _flag_out(f: FeatureFlag) -> dict:
    return {
        "id": str(f.id), "key": f.key, "label": f.label,
        "description": f.description, "category": f.category,
        "enabled": f.enabled, "rollout_pct": f.rollout_pct,
        "changed_by": f.changed_by,
        "last_changed": f.last_changed.isoformat() if f.last_changed else None,
    }


@router.get("/features")
async def list_flags(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(FeatureFlag).order_by(FeatureFlag.created_at))
    return [_flag_out(f) for f in result.scalars().all()]


@router.patch("/features/{flag_id}")
async def update_flag(flag_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    f = await db.get(FeatureFlag, uuid.UUID(flag_id))
    if not f:
        raise HTTPException(404, "Flag not found")
    for field in ("enabled", "rollout_pct", "description"):
        if field in body:
            setattr(f, field, body[field])
    f.changed_by = f"Admin {admin.first_name}"
    f.last_changed = datetime.now(timezone.utc)
    await db.commit()
    return _flag_out(f)


# ── Zones ─────────────────────────────────────────────────────────────────────

def _zone_out(z: Zone) -> dict:
    return {
        "id": str(z.id), "name": z.name, "description": z.description,
        "active": z.active, "area_km2": float(z.area_km2),
        "lat": float(z.lat), "lng": float(z.lng),
        "total_rides": z.total_rides,
        "drivers_online": 0, "active_rides": 0,
    }


@router.get("/zones")
async def list_zones(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(Zone).order_by(Zone.created_at))
    return [_zone_out(z) for z in result.scalars().all()]


@router.post("/zones", status_code=201)
async def create_zone(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    z = Zone(
        name=body["name"], description=body.get("description", ""),
        area_km2=float(body.get("area_km2", 0)),
        lat=float(body.get("lat", -1.6792)), lng=float(body.get("lng", 29.2228)),
    )
    db.add(z)
    await _audit(db, "zone_created", admin, f"Zone {z.name}", {})
    await db.commit()
    await db.refresh(z)
    return _zone_out(z)


@router.patch("/zones/{zone_id}")
async def update_zone(zone_id: str, body: dict, db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    z = await db.get(Zone, uuid.UUID(zone_id))
    if not z:
        raise HTTPException(404, "Zone not found")
    for f in ("name", "description", "active", "area_km2", "lat", "lng"):
        if f in body:
            setattr(z, f, body[f])
    await db.commit()
    return _zone_out(z)


@router.delete("/zones/{zone_id}", status_code=204)
async def delete_zone(zone_id: str, db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    z = await db.get(Zone, uuid.UUID(zone_id))
    if not z:
        raise HTTPException(404, "Zone not found")
    await db.delete(z)
    await db.commit()


# ── Platform Config ───────────────────────────────────────────────────────────

@router.get("/config")
async def get_config(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(PlatformConfig))
    rows = result.scalars().all()
    return {r.key: r.value for r in rows}


@router.patch("/config")
async def update_config(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    for key, value in body.items():
        result = await db.execute(select(PlatformConfig).where(PlatformConfig.key == key))
        cfg = result.scalar_one_or_none()
        if cfg:
            cfg.value = value
            cfg.updated_by = f"Admin {admin.first_name}"
        else:
            db.add(PlatformConfig(key=key, value=value, updated_by=f"Admin {admin.first_name}"))
    await _audit(db, "config_changed", admin, "Platform Config", body)
    await db.commit()
    return {"updated": list(body.keys())}


# ── Support Tickets ───────────────────────────────────────────────────────────

def _ticket_out(t: SupportTicket) -> dict:
    return {
        "id": t.ticket_ref, "user": t.user_name, "user_type": t.user_type,
        "phone": t.phone, "subject": t.subject, "type": t.type,
        "priority": t.priority, "status": t.status,
        "ride_id": t.ride_id, "amount": float(t.amount),
        "messages": t.messages or [],
        "created_at": t.created_at.isoformat(),
        "updated_at": t.updated_at.isoformat(),
    }


@router.get("/support/tickets")
async def list_tickets(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(SupportTicket).order_by(SupportTicket.created_at.desc()))
    return [_ticket_out(t) for t in result.scalars().all()]


@router.patch("/support/tickets/{ticket_ref}")
async def update_ticket(ticket_ref: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    result = await db.execute(select(SupportTicket).where(SupportTicket.ticket_ref == ticket_ref))
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(404, "Ticket not found")
    if "status" in body:
        t.status = body["status"]
    if "reply" in body:
        msgs = list(t.messages or [])
        msgs.append({"from": "admin", "text": body["reply"], "at": datetime.now(timezone.utc).isoformat()})
        t.messages = msgs
    await _audit(db, "ticket_updated", admin, f"Ticket {ticket_ref}", {"status": body.get("status")})
    await db.commit()
    return _ticket_out(t)


# ── Incidents ─────────────────────────────────────────────────────────────────

def _incident_out(i: Incident) -> dict:
    return {
        "id": i.incident_ref, "severity": i.severity, "status": i.status,
        "type": i.type, "reporter_type": i.reporter_type,
        "reporter": i.reporter, "reporter_phone": i.reporter_phone,
        "driver": i.driver, "driver_phone": i.driver_phone,
        "ride_id": i.ride_id, "location": i.location,
        "lat": float(i.lat) if i.lat else None,
        "lng": float(i.lng) if i.lng else None,
        "description": i.description, "notes": i.notes,
        "reported_at": i.reported_at.isoformat(),
        "resolved_at": i.resolved_at.isoformat() if i.resolved_at else None,
    }


@router.get("/incidents")
async def list_incidents(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(Incident).order_by(Incident.reported_at.desc()))
    return [_incident_out(i) for i in result.scalars().all()]


@router.patch("/incidents/{incident_ref}")
async def update_incident(incident_ref: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    result = await db.execute(select(Incident).where(Incident.incident_ref == incident_ref))
    i = result.scalar_one_or_none()
    if not i:
        raise HTTPException(404, "Incident not found")
    for f in ("status", "notes", "severity"):
        if f in body:
            setattr(i, f, body[f])
    if body.get("status") == "resolved":
        i.resolved_at = datetime.now(timezone.utc)
    await _audit(db, "incident_resolved" if body.get("status") == "resolved" else "incident_updated",
                 admin, f"Incident {incident_ref}", {})
    await db.commit()
    return _incident_out(i)


# ── SOS Reports ───────────────────────────────────────────────────────────────

def _sos_out(s: SosReport) -> dict:
    return {
        "id": s.sos_ref, "severity": s.severity, "status": s.status,
        "reporter_type": s.reporter_type, "reporter": s.reporter,
        "reporter_phone": s.reporter_phone,
        "driver": s.driver, "driver_phone": s.driver_phone,
        "ride_id": s.ride_id, "location": s.location,
        "lat": float(s.lat) if s.lat else None,
        "lng": float(s.lng) if s.lng else None,
        "message": s.message,
        "created_at": s.created_at.isoformat(),
        "resolved_at": s.resolved_at.isoformat() if s.resolved_at else None,
    }


@router.get("/sos")
async def list_sos(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(SosReport).order_by(SosReport.created_at.desc()))
    return [_sos_out(s) for s in result.scalars().all()]


@router.patch("/sos/{sos_ref}")
async def update_sos(sos_ref: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    result = await db.execute(select(SosReport).where(SosReport.sos_ref == sos_ref))
    s = result.scalar_one_or_none()
    if not s:
        raise HTTPException(404, "SOS report not found")
    if "status" in body:
        s.status = body["status"]
        if body["status"] == "resolved":
            s.resolved_at = datetime.now(timezone.utc)
    await _audit(db, "sos_resolved", admin, f"SOS {sos_ref}", {})
    await db.commit()
    return _sos_out(s)


# ── Payouts ───────────────────────────────────────────────────────────────────

def _payout_out(p: Payout) -> dict:
    return {
        "id": p.payout_ref, "driver": p.driver_name, "driver_id": p.driver_ref,
        "phone": p.phone, "amount": float(p.amount), "period": p.period,
        "rides": p.rides, "avg_fare": float(p.avg_fare),
        "status": p.status, "method": p.method, "notes": p.notes,
        "created_at": p.created_at.isoformat(),
        "processed_at": p.processed_at.isoformat() if p.processed_at else None,
    }


@router.get("/payouts")
async def list_payouts(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(Payout).order_by(Payout.created_at.desc()))
    return [_payout_out(p) for p in result.scalars().all()]


@router.patch("/payouts/{payout_ref}")
async def update_payout(payout_ref: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    result = await db.execute(select(Payout).where(Payout.payout_ref == payout_ref))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Payout not found")
    for f in ("status", "notes", "method"):
        if f in body:
            setattr(p, f, body[f])
    if body.get("status") == "completed":
        p.processed_at = datetime.now(timezone.utc)
    await _audit(db, "payout_processed", admin, f"Payout {payout_ref} — {p.driver_name}",
                 {"amount": float(p.amount), "status": p.status})
    await db.commit()
    return _payout_out(p)


# ── Staff (admin users) ───────────────────────────────────────────────────────

@router.get("/staff")
async def list_staff(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(User).where(User.role == "admin").order_by(User.created_at))
    users = result.scalars().all()
    out = []
    for u in users:
        # count audit log entries for this user
        cnt = (await db.execute(
            select(func.count(AuditLog.id)).where(AuditLog.admin_id == u.id)
        )).scalar() or 0
        out.append({
            "id": str(u.id),
            "name": f"{u.first_name} {u.last_name}".strip(),
            "email": u.email, "phone": u.phone,
            "role": u.role, "status": "active" if u.is_active else "inactive",
            "actions_count": cnt,
            "last_login": u.updated_at.isoformat() if u.updated_at else None,
        })
    return out


@router.patch("/staff/{user_id}")
async def update_staff(user_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    u = await db.get(User, uuid.UUID(user_id))
    if not u:
        raise HTTPException(404, "Staff member not found")
    for f in ("is_active",):
        if f in body:
            setattr(u, f, body[f])
    await db.commit()
    return {"id": str(u.id), "status": "active" if u.is_active else "inactive"}


# ── Referrals ─────────────────────────────────────────────────────────────────

@router.get("/referrals/stats")
async def referral_stats(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(PlatformConfig).where(PlatformConfig.key == "referral_config"))
    cfg_row = result.scalar_one_or_none()
    cfg = cfg_row.value if cfg_row else {}
    return {
        "total_referrals": 0,
        "active_referrers": 0,
        "reward_given": 0,
        "conversion_rate": 0.0,
        "config": cfg,
    }


@router.get("/referrals/top")
async def top_referrers(_: User = Depends(admin_only)):
    return []


@router.get("/referrals/config")
async def get_referral_config(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(select(PlatformConfig).where(PlatformConfig.key == "referral_config"))
    cfg = result.scalar_one_or_none()
    default = {"referrer_reward": 10000, "referee_reward": 5000, "max_referrals_per_user": 50, "min_rides_to_qualify": 1}
    return cfg.value if cfg else default


@router.patch("/referrals/config")
async def update_referral_config(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    result = await db.execute(select(PlatformConfig).where(PlatformConfig.key == "referral_config"))
    cfg = result.scalar_one_or_none()
    if cfg:
        cfg.value = body
        cfg.updated_by = f"Admin {admin.first_name}"
    else:
        db.add(PlatformConfig(key="referral_config", value=body, updated_by=f"Admin {admin.first_name}"))
    await db.commit()
    return body


# ── Finance / Transactions ────────────────────────────────────────────────────

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
        passenger_name = ""
        if r.passenger_id:
            p = await db.get(User, r.passenger_id)
            if p:
                passenger_name = f"{p.first_name} {p.last_name}"

        driver_name = ""
        if r.driver_id:
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

    if status:
        items = [i for i in items if i["status"] == status]
    if method:
        items = [i for i in items if i["method"] == method]
    if search:
        s = search.lower()
        items = [i for i in items if s in i["rider"].lower() or s in i["driver"].lower() or s in i["id"].lower()]

    per_page = 20
    start = (page - 1) * per_page
    return items[start:start + per_page]


@router.get("/finance/stats")
async def finance_stats(
    period: str = "7d",
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    from datetime import timedelta
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


@router.get("/finance/chart")
async def finance_chart(
    period: str = "7d",
    db: AsyncSession = Depends(get_db),
    _: User = Depends(admin_only),
):
    from datetime import timedelta
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


@router.patch("/payments/{ride_id}/status")
async def override_payment_status(
    ride_id: str,
    body: dict,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(admin_only),
):
    ride = await db.get(Ride, uuid.UUID(ride_id))
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    new_status = body.get("status")
    if new_status not in ("paid", "failed", "pending"):
        raise HTTPException(status_code=422, detail="status must be paid, failed, or pending")

    ride.payment_status = new_status
    await _audit(db, f"payment_status_override:{new_status}", admin, ride_id)
    await db.commit()
    return {"ride_id": ride_id, "payment_status": new_status}


# ── Driver Onboarding ─────────────────────────────────────────────────────────

@router.get("/drivers/onboarding/stats")
async def onboarding_stats(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    total = (await db.execute(select(func.count(Driver.id)))).scalar() or 0
    verified = (await db.execute(select(func.count(Driver.id)).where(Driver.is_verified == True))).scalar() or 0  # noqa
    pending = total - verified
    return {"total": total, "verified": verified, "pending": pending, "rejected": 0}


@router.get("/drivers/onboarding")
async def pending_onboarding(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(
        select(Driver, User)
        .join(User, Driver.user_id == User.id)
        .where(Driver.is_verified == False)  # noqa
        .order_by(Driver.created_at.desc())
    )
    rows = result.all()
    from .drivers import _driver_to_out
    return [_driver_to_out(d, u) for d, u in rows]


@router.patch("/drivers/onboarding/{driver_id}")
async def approve_driver(driver_id: str, body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    d = await db.get(Driver, uuid.UUID(driver_id))
    if not d:
        raise HTTPException(404, "Driver not found")
    action = body.get("action", "approve")
    d.is_verified = (action == "approve")
    from .admin import _audit
    await _audit(db, "driver_approved" if action == "approve" else "driver_rejected",
                 admin, f"Driver {driver_id}", {"action": action})
    await db.commit()
    return {"id": driver_id, "is_verified": d.is_verified}


# ── Ratings Monitor ───────────────────────────────────────────────────────────

@router.get("/ratings/stats")
async def rating_stats(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    avg = (await db.execute(select(func.avg(Driver.rating)))).scalar() or 5.0
    total = (await db.execute(select(func.count(Driver.id)))).scalar() or 0
    low = (await db.execute(select(func.count(Driver.id)).where(Driver.rating < 4.0))).scalar() or 0
    return {"avg_rating": round(float(avg), 2), "total_drivers": total, "low_rated": low}


@router.get("/ratings")
async def list_ratings(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    result = await db.execute(
        select(Driver, User)
        .join(User, Driver.user_id == User.id)
        .order_by(Driver.rating.asc())
        .limit(50)
    )
    rows = result.all()
    return [
        {
            "id": str(d.id),
            "name": f"{u.first_name} {u.last_name}".strip(),
            "phone": u.phone,
            "rating": float(d.rating),
            "rating_count": d.rating_count,
            "total_rides": d.total_rides,
        }
        for d, u in rows
    ]


# ── API Health ────────────────────────────────────────────────────────────────

@router.get("/health")
async def api_health(db: AsyncSession = Depends(get_db), _: User = Depends(admin_only)):
    try:
        await db.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False

    uptime_s = int(time.time() - _START)
    hours, rem = divmod(uptime_s, 3600)
    minutes = rem // 60

    return {
        "status": "healthy" if db_ok else "degraded",
        "uptime": f"{hours}h {minutes}m",
        "database": "connected" if db_ok else "error",
        "services": [
            {"name": "Database", "status": "ok" if db_ok else "error", "latency_ms": 0},
            {"name": "Auth", "status": "ok", "latency_ms": 0},
            {"name": "Rides", "status": "ok", "latency_ms": 0},
        ],
    }


# ── Rides (alias) ─────────────────────────────────────────────────────────────

@router.get("/rides/all")
async def get_all_rides_alias(db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    from .admin import get_all_rides
    return await get_all_rides(db=db, _=admin)


@router.post("/rides/cancel-all")
async def cancel_all_active(db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    result = await db.execute(
        select(Ride).where(Ride.status.in_(["pending", "accepted", "arriving"]))
    )
    rides = result.scalars().all()
    for r in rides:
        r.status = "cancelled"
    await _audit(db, "rides_bulk_cancelled", admin, f"{len(rides)} rides cancelled", {"count": len(rides)})
    await db.commit()
    return {"cancelled": len(rides)}


# ── Driver force-offline ──────────────────────────────────────────────────────

@router.post("/drivers/force-offline")
async def force_driver_offline(body: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(admin_only)):
    driver_id = body.get("driver_id")
    if not driver_id:
        raise HTTPException(400, "driver_id required")
    d = await db.get(Driver, uuid.UUID(driver_id))
    if not d:
        raise HTTPException(404, "Driver not found")
    d.is_online = False
    await _audit(db, "driver_forced_offline", admin, f"Driver {driver_id}", {})
    await db.commit()
    return {"driver_id": driver_id, "is_online": False}
