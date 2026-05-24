import uuid
from pydantic import BaseModel, field_validator
from typing import Optional


class PaymentInitiateIn(BaseModel):
    ride_id: uuid.UUID
    phone_number: str
    payment_method: str = "airtel_money"

    @field_validator("payment_method")
    @classmethod
    def valid_method(cls, v: str) -> str:
        if v not in ("airtel_money", "cash"):
            raise ValueError("payment_method must be airtel_money or cash")
        return v

    @field_validator("phone_number")
    @classmethod
    def valid_phone(cls, v: str) -> str:
        v = v.strip()
        if not v.startswith("+") or len(v) < 10:
            raise ValueError("phone_number must be in E.164 format e.g. +243812345678")
        return v


class PaymentStatusOut(BaseModel):
    payment_status: str
    payment_reference: Optional[str] = None


class PaymentHistoryItem(BaseModel):
    ride_id: str
    amount: float
    payment_method: str
    payment_status: str
    payment_reference: Optional[str] = None
    payment_phone: Optional[str] = None
    pickup_address: str
    destination_address: str
    driver_name: Optional[str] = None
    created_at: Optional[str] = None


class PaymentInitiateOut(BaseModel):
    status: str
    reference: Optional[str] = None
    amount: float
