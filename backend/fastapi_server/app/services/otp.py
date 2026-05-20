import secrets
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func
from ..models.otp import OtpCode
from ..config import get_settings

settings = get_settings()

_OTP_TTL_MINUTES = 10
_RESEND_COOLDOWN_SECONDS = 60


def _generate_code() -> str:
    """Cryptographically secure 6-digit OTP."""
    return str(secrets.randbelow(900000) + 100000)


async def send_otp(phone: str, db: AsyncSession) -> None:
    # Enforce resend cooldown: reject if a non-expired, unused OTP was created within the last minute
    recent = await db.execute(
        select(OtpCode)
        .where(
            OtpCode.phone == phone,
            OtpCode.used == False,  # noqa: E712
            OtpCode.expires_at > datetime.now(timezone.utc),
            OtpCode.created_at > datetime.now(timezone.utc) - timedelta(seconds=_RESEND_COOLDOWN_SECONDS),
        )
        .limit(1)
    )
    if recent.scalar_one_or_none():
        raise HTTPException(status_code=429, detail="Please wait before requesting another OTP")

    code = _generate_code()
    expires = datetime.now(timezone.utc) + timedelta(minutes=_OTP_TTL_MINUTES)

    otp = OtpCode(phone=phone, code=code, expires_at=expires)
    db.add(otp)
    await db.commit()

    if settings.twilio_account_sid and settings.twilio_auth_token:
        try:
            from twilio.rest import Client
            client = Client(settings.twilio_account_sid, settings.twilio_auth_token)
            client.messages.create(
                body=f"Your KuboChain verification code is: {code}. Valid for {_OTP_TTL_MINUTES} minutes.",
                from_=settings.twilio_phone_number,
                to=phone,
            )
        except Exception as e:
            print(f"[OTP] Twilio error: {e}")
    else:
        print(f"[OTP DEV] {phone} → {code}")


async def verify_otp(phone: str, code: str, db: AsyncSession) -> bool:
    window_start = datetime.now(timezone.utc) - timedelta(minutes=_OTP_TTL_MINUTES)
    total_recent = (await db.execute(
        select(func.count(OtpCode.id)).where(
            OtpCode.phone == phone,
            OtpCode.created_at > window_start,
        )
    )).scalar() or 0

    if total_recent > settings.otp_max_attempts * 2:
        raise HTTPException(status_code=429, detail="Too many OTP attempts. Please try again later.")

    # Dev bypass: accept "000000" when Twilio is not configured
    if not settings.twilio_account_sid and code == "000000":
        return True

    result = await db.execute(
        select(OtpCode)
        .where(
            OtpCode.phone == phone,
            OtpCode.code == code,
            OtpCode.used == False,  # noqa: E712
            OtpCode.expires_at > datetime.now(timezone.utc),
        )
        .order_by(OtpCode.created_at.desc())
        .limit(1)
    )
    otp = result.scalar_one_or_none()
    if not otp:
        return False

    await db.execute(update(OtpCode).where(OtpCode.id == otp.id).values(used=True))
    await db.commit()
    return True
