import uuid
from datetime import datetime, date
from sqlalchemy import String, Boolean, Integer, Numeric, ForeignKey, Date, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from ..database import Base


class Driver(Base):
    __tablename__ = "drivers"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    vehicle_make: Mapped[str] = mapped_column(String(100), default="Unknown")
    vehicle_model: Mapped[str] = mapped_column(String(100), default="Unknown")
    vehicle_color: Mapped[str] = mapped_column(String(50), default="Black")
    vehicle_plate: Mapped[str] = mapped_column(String(20), default="", unique=True)
    vehicle_type: Mapped[str] = mapped_column(String(20), default="motorcycle")
    license: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False)
    lat: Mapped[float | None] = mapped_column(Numeric(10, 8), nullable=True)
    lng: Mapped[float | None] = mapped_column(Numeric(11, 8), nullable=True)
    rating: Mapped[float] = mapped_column(Numeric(3, 2), default=5.00)
    rating_count: Mapped[int] = mapped_column(Integer, default=0)
    total_rides: Mapped[int] = mapped_column(Integer, default=0)
    total_earnings: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    today_earnings: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    last_earnings_reset: Mapped[date] = mapped_column(Date, default=date.today)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user: Mapped["User"] = relationship("User", back_populates="driver")
