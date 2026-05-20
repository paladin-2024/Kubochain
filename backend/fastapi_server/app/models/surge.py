import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, Numeric, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID
from ..database import Base


class SurgeZone(Base):
    __tablename__ = "surge_zones"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100))
    active: Mapped[bool] = mapped_column(Boolean, default=False)
    multiplier: Mapped[float] = mapped_column(Numeric(4, 2), default=1.0)
    trigger: Mapped[str] = mapped_column(String(20), default="manual")
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class SurgeRule(Base):
    __tablename__ = "surge_rules"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100))
    schedule: Mapped[str] = mapped_column(String(200))
    multiplier: Mapped[float] = mapped_column(Numeric(4, 2), default=1.5)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    zones: Mapped[str] = mapped_column(Text, default="[]")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
