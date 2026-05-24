from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from .config import get_settings
from .database import engine, Base
from .routers import auth, rides, drivers, chat, admin, ws
from .routers import admin_extras
from .routers import payments

settings = get_settings()

# ── Rate limiter (shared across routers via app.state) ─────────────────────────
limiter = Limiter(key_func=get_remote_address, default_limits=["200/minute"])


# ── Security headers middleware ────────────────────────────────────────────────
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
        response.headers["Cache-Control"] = "no-store"
        # Only send HSTS in production (non-localhost origins)
        if not any("localhost" in o for o in settings.origins_list):
            response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
        return response


# ── Request body size limit ────────────────────────────────────────────────────
class MaxBodySizeMiddleware(BaseHTTPMiddleware):
    _MAX_BYTES = 2 * 1024 * 1024  # 2 MB (uploads handled separately with their own limit)

    async def dispatch(self, request: Request, call_next):
        if request.method in ("POST", "PUT", "PATCH"):
            content_type = request.headers.get("content-type", "")
            # Skip for multipart uploads — they enforce size in the storage service
            if "multipart/form-data" not in content_type:
                body = await request.body()
                if len(body) > self._MAX_BYTES:
                    from fastapi.responses import JSONResponse
                    return JSONResponse(status_code=413, content={"detail": "Request body too large"})
        return await call_next(request)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(
    title="KuboChain API",
    version="2.0.0",
    description="Boda-boda ride-hailing backend — FastAPI + PostgreSQL",
    lifespan=lifespan,
    # Hide internal error details in production
    docs_url="/docs",
    redoc_url="/redoc",
)

# Attach limiter to app state so routers can import and use it
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Middleware order matters — outermost first
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(MaxBodySizeMiddleware)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
    max_age=600,
)

# Only enforce trusted hosts outside local dev
_is_dev = any("localhost" in o or "127.0.0.1" in o for o in settings.origins_list)
if not _is_dev:
    allowed_hosts = [o.removeprefix("https://").removeprefix("http://").split("/")[0] for o in settings.origins_list]
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=allowed_hosts + ["localhost"])

# Static uploads
upload_path = Path(settings.upload_dir)
upload_path.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(upload_path)), name="uploads")

# Routers
app.include_router(auth.router, prefix="/api")
app.include_router(rides.router, prefix="/api")
app.include_router(drivers.router, prefix="/api")
app.include_router(chat.router, prefix="/api")
app.include_router(admin.router, prefix="/api")
app.include_router(admin_extras.router, prefix="/api")
app.include_router(payments.router, prefix="/api")
app.include_router(ws.router)


@app.get("/health", include_in_schema=False)
async def health():
    return {"status": "ok", "service": "KuboChain API v2"}
