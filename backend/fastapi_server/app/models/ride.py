import uuid
from datetime import datetime
from sqlalchemy import String, Integer, Numeric, Text, ForeignKey, DateTime, ARRAY
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID
from ..database import Base


class Ride(Base):
    __tablename__ = "rides"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    passenger_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    driver_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("drivers.id"), nullable=True)

    pickup_address: Mapped[str] = mapped_column(Text)
    pickup_lat: Mapped[float] = mapped_column(Numeric(10, 8))
    pickup_lng: Mapped[float] = mapped_column(Numeric(11, 8))
    destination_address: Mapped[str] = mapped_column(Text)
    destination_lat: Mapped[float] = mapped_column(Numeric(10, 8))
    destination_lng: Mapped[float] = mapped_column(Numeric(11, 8))

    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    price: Mapped[float] = mapped_column(Numeric(10, 2))
    distance: Mapped[float] = mapped_column(Numeric(8, 3))
    estimated_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    ride_type: Mapped[str] = mapped_column(String(20), default="economy")

    payment_method: Mapped[str] = mapped_column(String(20), default="cash")
    payment_status: Mapped[str] = mapped_column(String(20), default="pending")
    payment_phone: Mapped[str | None] = mapped_column(Text, nullable=True)
    payment_reference: Mapped[str | None] = mapped_column(Text, nullable=True)

    cancel_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    cancelled_by: Mapped[str | None] = mapped_column(String(20), nullable=True)

    rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
    rating_comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    rating_tags: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)

    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    arrived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    driver_completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    passenger_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, index=True)
