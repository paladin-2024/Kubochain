import re
import uuid
from typing import Optional
from pydantic import BaseModel, EmailStr, field_validator


_PHONE_RE = re.compile(r"^\+?[0-9]{7,15}$")


class VehicleIn(BaseModel):
    make: str = "Unknown"
    model: str = "Unknown"
    color: str = "Black"
    plate_number: str = ""
    type: str = "motorcycle"

    @field_validator("type")
    @classmethod
    def _vehicle_type(cls, v: str) -> str:
        if v not in ("motorcycle", "car"):
            raise ValueError("vehicle type must be 'motorcycle' or 'car'")
        return v


class RegisterIn(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    phone: str
    password: str
    role: str = "passenger"
    otp_code: str
    vehicle: Optional[VehicleIn] = None

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: str) -> str:
        cleaned = v.strip()
        if not _PHONE_RE.match(cleaned):
            raise ValueError("Invalid phone number format")
        return cleaned

    @field_validator("password")
    @classmethod
    def _validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        if not any(c.isalpha() for c in v):
            raise ValueError("Password must contain at least one letter")
        return v

    @field_validator("role")
    @classmethod
    def _validate_role(cls, v: str) -> str:
        if v not in ("passenger", "rider"):
            raise ValueError("role must be 'passenger' or 'rider'")
        return v

    @field_validator("first_name", "last_name")
    @classmethod
    def _strip_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Name cannot be blank")
        if len(v) > 100:
            raise ValueError("Name too long")
        return v


class LoginIn(BaseModel):
    phone: str
    password: str

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: str) -> str:
        cleaned = v.strip()
        if not _PHONE_RE.match(cleaned):
            raise ValueError("Invalid phone number format")
        return cleaned


class UpdateProfileIn(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = v.strip()
        if not _PHONE_RE.match(cleaned):
            raise ValueError("Invalid phone number format")
        return cleaned


class FcmTokenIn(BaseModel):
    fcm_token: str

    @field_validator("fcm_token")
    @classmethod
    def _not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("FCM token cannot be empty")
        return v.strip()


class SendOtpIn(BaseModel):
    phone: str

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: str) -> str:
        cleaned = v.strip()
        if not _PHONE_RE.match(cleaned):
            raise ValueError("Invalid phone number format")
        return cleaned


class VerifyOtpIn(BaseModel):
    phone: str
    code: str

    @field_validator("code")
    @classmethod
    def _digits_only(cls, v: str) -> str:
        v = v.strip()
        if not v.isdigit() or len(v) != 6:
            raise ValueError("OTP must be exactly 6 digits")
        return v


class RefreshIn(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    first_name: str
    last_name: str
    email: str
    phone: str
    role: str
    profile_image: Optional[str] = None
    rating: float
    total_rides: int
    is_active: bool


class AuthOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut
