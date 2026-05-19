import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Request, status
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..database import get_db
from ..models.user import User
from ..models.driver import Driver
from ..schemas.auth import (
    RegisterIn, LoginIn, UpdateProfileIn, FcmTokenIn,
    SendOtpIn, VerifyOtpIn, RefreshIn, UserOut, AuthOut,
)
from ..core.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_refresh_token,
)
from ..core.dependencies import get_current_user
from ..services.otp import send_otp, verify_otp
from ..services.storage import save_upload

router = APIRouter(prefix="/auth", tags=["auth"])
limiter = Limiter(key_func=get_remote_address)


def _auth_out(user: User) -> AuthOut:
    return AuthOut(
        access_token=create_access_token(str(user.id), user.role),
        refresh_token=create_refresh_token(str(user.id), user.role),
        user=UserOut.model_validate(user),
    )


# ── OTP ───────────────────────────────────────────────────────────────────────

@router.post("/send-otp")
@limiter.limit("5/minute")
async def send_otp_endpoint(request: Request, body: SendOtpIn, db: AsyncSession = Depends(get_db)):
    await send_otp(body.phone, db)
    return {"message": "OTP sent"}


@router.post("/verify-otp")
@limiter.limit("10/minute")
async def verify_otp_endpoint(request: Request, body: VerifyOtpIn, db: AsyncSession = Depends(get_db)):
    ok = await verify_otp(body.phone, body.code, db)
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    return {"message": "OTP verified"}


# ── Registration / Login ───────────────────────────────────────────────────────

@router.post("/register", status_code=status.HTTP_201_CREATED, response_model=AuthOut)
@limiter.limit("10/minute")
async def register(request: Request, body: RegisterIn, db: AsyncSession = Depends(get_db)):
    ok = await verify_otp(body.phone, body.otp_code, db)
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email already in use")

    user = User(
        first_name=body.first_name,
        last_name=body.last_name,
        email=body.email,
        phone=body.phone,
        password=hash_password(body.password),
        role=body.role,
    )
    db.add(user)
    await db.flush()

    if user.role == "rider":
        v = body.vehicle
        plate = (v.plate_number if v else "") or f"TMP-{uuid.uuid4().hex[:6].upper()}"
        db.add(Driver(
            user_id=user.id,
            vehicle_make=v.make if v else "Unknown",
            vehicle_model=v.model if v else "Unknown",
            vehicle_color=v.color if v else "Black",
            vehicle_plate=plate,
            vehicle_type=v.type if v else "motorcycle",
        ))

    await db.commit()
    await db.refresh(user)
    return _auth_out(user)


@router.post("/login", response_model=AuthOut)
@limiter.limit("10/minute")
async def login(request: Request, body: LoginIn, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()
    # Always run bcrypt even when user not found — prevents timing-based user enumeration
    dummy_hash = "$2b$12$eImiTXuWVxfM37uY4JANjQuu1WTgP8I9yBLKDFAGHI7tQDq6jZKJy"
    valid = verify_password(body.password, user.password if user else dummy_hash)
    if not user or not valid:
        raise HTTPException(status_code=401, detail="Numéro de téléphone ou mot de passe incorrect")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")
    return _auth_out(user)


@router.post("/refresh", response_model=AuthOut)
@limiter.limit("30/minute")
async def refresh_token(request: Request, body: RefreshIn, db: AsyncSession = Depends(get_db)):
    payload = decode_refresh_token(body.refresh_token)
    user_id = payload.get("sub")
    user = await db.get(User, uuid.UUID(user_id))
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or disabled")
    return _auth_out(user)


# ── Authenticated endpoints ────────────────────────────────────────────────────

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)


@router.put("/profile", response_model=UserOut)
async def update_profile(
    body: UpdateProfileIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if body.first_name is not None:
        current_user.first_name = body.first_name
    if body.last_name is not None:
        current_user.last_name = body.last_name
    if body.email is not None:
        current_user.email = body.email
    if body.phone is not None:
        current_user.phone = body.phone
    await db.commit()
    await db.refresh(current_user)
    return UserOut.model_validate(current_user)


@router.put("/fcm-token")
async def update_fcm_token(
    body: FcmTokenIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.fcm_token = body.fcm_token
    await db.commit()
    return {"message": "FCM token updated"}


@router.put("/profile-image", response_model=UserOut)
async def update_profile_image(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    url = await save_upload(file, subfolder="profile")
    current_user.profile_image = url
    await db.commit()
    await db.refresh(current_user)
    return UserOut.model_validate(current_user)
