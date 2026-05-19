from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uuid


class LocationIn(BaseModel):
    address: str
    lat: float
    lng: float


class CreateRideIn(BaseModel):
    pickup: LocationIn
    destination: LocationIn
    ride_type: str = "economy"
    price: float
    distance: float


class CancelRideIn(BaseModel):
    reason: Optional[str] = "No reason provided"


class RateRideIn(BaseModel):
    rating: int
    comment: Optional[str] = None
    tags: Optional[list[str]] = None


class DriverInfo(BaseModel):
    id: Optional[uuid.UUID] = None
    user_id: Optional[uuid.UUID] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image: Optional[str] = None
    rating: Optional[float] = None
    vehicle_make: Optional[str] = None
    vehicle_model: Optional[str] = None
    vehicle_color: Optional[str] = None
    vehicle_plate: Optional[str] = None
    vehicle_type: Optional[str] = None


class PassengerInfo(BaseModel):
    id: Optional[uuid.UUID] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image: Optional[str] = None
    rating: Optional[float] = None


class RideOut(BaseModel):
    id: uuid.UUID
    status: str
    price: float
    distance: float
    estimated_minutes: Optional[int] = None
    ride_type: str
    pickup: LocationIn
    destination: LocationIn
    driver: Optional[DriverInfo] = None
    passenger: Optional[PassengerInfo] = None
    rating: Optional[int] = None
    rating_comment: Optional[str] = None
    rating_tags: Optional[list[str]] = None
    cancel_reason: Optional[str] = None
    cancelled_by: Optional[str] = None
    accepted_at: Optional[datetime] = None
    arrived_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime
