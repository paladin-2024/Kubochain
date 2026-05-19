from pydantic import BaseModel
from typing import Optional
import uuid


class UpdateLocationIn(BaseModel):
    lat: float
    lng: float


class ToggleAvailabilityIn(BaseModel):
    is_online: bool


class UpdateVehicleIn(BaseModel):
    vehicle_make: Optional[str] = None
    vehicle_model: Optional[str] = None
    vehicle_plate: Optional[str] = None
    vehicle_color: Optional[str] = None
    vehicle_type: Optional[str] = None


class DriverOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    first_name: str
    last_name: str
    phone: str
    profile_image: Optional[str] = None
    vehicle_make: str
    vehicle_model: str
    vehicle_color: str
    vehicle_plate: str
    vehicle_type: str
    is_online: bool
    is_verified: bool
    rating: float
    rating_count: int
    total_rides: int
    lat: Optional[float] = None
    lng: Optional[float] = None


class EarningsOut(BaseModel):
    today_earnings: float
    total_earnings: float
    total_rides: int
    recent_rides: list


class TopRiderOut(BaseModel):
    rank: int
    id: uuid.UUID
    name: str
    profile_image: Optional[str] = None
    rating: float
    rating_count: int
    total_rides: int
    total_earnings: float
    five_star_count: int
    top_tags: list[str]
    vehicle: str
    vehicle_plate: str
    is_online: bool
