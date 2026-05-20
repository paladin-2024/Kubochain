import uuid
from datetime import datetime
from sqlalchemy import String, Numeric, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
from ..database import Base


class SupportTicket(Base):
    __tablename__ = "support_tickets"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ticket_ref: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    user_name: Mapped[str] = mapped_column(String(200))
    user_type: Mapped[str] = mapped_column(String(20), default="passenger")
    phone: Mapped[str] = mapped_column(String(30), default="")
    subject: Mapped[str] = mapped_column(String(500))
    type: Mapped[str] = mapped_column(String(50), default="general")
    priority: Mapped[str] = mapped_column(String(20), default="normal")
    status: Mapped[str] = mapped_column(String(20), default="open")
    ride_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
    amount: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    messages: Mapped[list] = mapped_column(JSONB, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)


class Incident(Base):
    __tablename__ = "incidents"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    incident_ref: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    severity: Mapped[str] = mapped_column(String(20), default="medium")
    status: Mapped[str] = mapped_column(String(20), default="open")
    type: Mapped[str] = mapped_column(String(50), default="complaint")
    reporter_type: Mapped[str] = mapped_column(String(20), default="passenger")
    reporter: Mapped[str] = mapped_column(String(200), default="")
    reporter_phone: Mapped[str] = mapped_column(String(30), default="")
    driver: Mapped[str | None] = mapped_column(String(200), nullable=True)
    driver_phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    ride_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
    location: Mapped[str] = mapped_column(String(300), default="")
    lat: Mapped[float | None] = mapped_column(Numeric(10, 8), nullable=True)
    lng: Mapped[float | None] = mapped_column(Numeric(11, 8), nullable=True)
    description: Mapped[str] = mapped_column(Text, default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    reported_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class SosReport(Base):
    __tablename__ = "sos_reports"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sos_ref: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    severity: Mapped[str] = mapped_column(String(20), default="critical")
    status: Mapped[str] = mapped_column(String(20), default="active")
    reporter_type: Mapped[str] = mapped_column(String(20), default="passenger")
    reporter: Mapped[str] = mapped_column(String(200))
    reporter_phone: Mapped[str] = mapped_column(String(30), default="")
    driver: Mapped[str | None] = mapped_column(String(200), nullable=True)
    driver_phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    ride_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
    location: Mapped[str] = mapped_column(String(300), default="")
    lat: Mapped[float | None] = mapped_column(Numeric(10, 8), nullable=True)
    lng: Mapped[float | None] = mapped_column(Numeric(11, 8), nullable=True)
    message: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
