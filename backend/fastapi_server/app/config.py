import warnings
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://kubochain:password@localhost:5432/kubochain"

    jwt_secret: str = "change_me"
    jwt_access_expires_minutes: int = 15
    jwt_refresh_expires_days: int = 7

    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_phone_number: str = ""

    firebase_credentials_path: str = "firebase-credentials.json"

    upload_dir: str = "uploads"
    max_upload_mb: int = 5

    # Comma-separated allowed CORS origins
    allowed_origins: str = "http://localhost:3000"

    # OTP brute-force: max wrong attempts before 10-min lockout
    otp_max_attempts: int = 5

    # Rate limiting: requests per window
    rate_limit_login: str = "10/minute"
    rate_limit_otp: str = "5/minute"
    rate_limit_register: str = "10/minute"

    @property
    def origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    @property
    def is_dev(self) -> bool:
        return any(
            "localhost" in o or "127.0.0.1" in o or "192.168" in o
            for o in self.origins_list
        )


@lru_cache
def get_settings() -> Settings:
    s = Settings()
    if s.jwt_secret == "change_me":
        if not s.is_dev:
            raise RuntimeError(
                "JWT_SECRET must be set to a strong random value before deploying. "
                "Generate one with: python -c \"import secrets; print(secrets.token_hex(32))\""
            )
        warnings.warn(
            "JWT_SECRET is using the default insecure value — OK for local dev only.",
            stacklevel=2,
        )
    return s
