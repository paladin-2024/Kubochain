import uuid
from datetime import datetime, date
from sqlalchemy import String, Boolean, Integer, Numeric, DateTime, Date, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID
from ..database import Base


class AppBanner(Base):
    __tablename__ = "app_banners"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(200))
    subtitle: Mapped[str] = mapped_column(String(400), default="")
    cta: Mapped[str] = mapped_column(String(100), default="")
    cta_link: Mapped[str] = mapped_column(String(500), default="")
    audience: Mapped[str] = mapped_column(String(20), default="all")
    placement: Mapped[str] = mapped_column(String(50), default="home")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    start: Mapped[date | None] = mapped_column(Date, nullable=True)
    end: Mapped[date | None] = mapped_column(Date, nullable=True)
    impressions: Mapped[int] = mapped_column(Integer, default=0)
    taps: Mapped[int] = mapped_column(Integer, default=0)
    bg_color: Mapped[str] = mapped_column(String(20), default="#1A3A6E")
    text_color: Mapped[str] = mapped_column(String(20), default="#FFFFFF")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class AppVersion(Base):
    __tablename__ = "app_versions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    platform: Mapped[str] = mapped_column(String(20))
    user_type: Mapped[str] = mapped_column(String(20), default="passenger")
    version: Mapped[str] = mapped_column(String(20))
    build: Mapped[int] = mapped_column(Integer, default=1)
    min_version: Mapped[str] = mapped_column(String(20), default="1.0.0")
    force_update: Mapped[bool] = mapped_column(Boolean, default=False)
    latest: Mapped[bool] = mapped_column(Boolean, default=True)
    changelog: Mapped[str] = mapped_column(Text, default="")
    released_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class FeatureFlag(Base):
    __tablename__ = "feature_flags"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    key: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    label: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text, default="")
    category: Mapped[str] = mapped_column(String(50), default="general")
    enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    rollout_pct: Mapped[int] = mapped_column(Integer, default=0)
    changed_by: Mapped[str] = mapped_column(String(200), default="")
    last_changed: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class Zone(Base):
    __tablename__ = "zones"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(Text, default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    area_km2: Mapped[float] = mapped_column(Numeric(8, 2), default=0)
    lat: Mapped[float] = mapped_column(Numeric(10, 8), default=0)
    lng: Mapped[float] = mapped_column(Numeric(11, 8), default=0)
    total_rides: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
