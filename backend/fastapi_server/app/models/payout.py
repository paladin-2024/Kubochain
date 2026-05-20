import uuid
from datetime import datetime
from sqlalchemy import String, Numeric, DateTime, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID
from ..database import Base


class Payout(Base):
    __tablename__ = "payouts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payout_ref: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    driver_name: Mapped[str] = mapped_column(String(200))
    driver_ref: Mapped[str] = mapped_column(String(50), default="")
    phone: Mapped[str] = mapped_column(String(30), default="")
    amount: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    period: Mapped[str] = mapped_column(String(100), default="")
    rides: Mapped[int] = mapped_column(Integer, default=0)
    avg_fare: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    method: Mapped[str] = mapped_column(String(50), default="Mobile Money")
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
