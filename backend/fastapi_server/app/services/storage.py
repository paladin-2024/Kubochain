import uuid
import os
import re
from pathlib import Path
from fastapi import UploadFile, HTTPException
from ..config import get_settings

settings = get_settings()

# Magic bytes for allowed image formats
_MAGIC = {
    b"\xff\xd8\xff": "jpg",
    b"\x89PNG\r\n\x1a\n": "png",
    b"RIFF": "webp",  # RIFF????WEBP — checked further below
}

_SAFE_EXT_RE = re.compile(r"^[a-zA-Z0-9]{1,5}$")


def _detect_image_type(header: bytes) -> str | None:
    if header[:3] == b"\xff\xd8\xff":
        return "jpg"
    if header[:8] == b"\x89PNG\r\n\x1a\n":
        return "png"
    if header[:4] == b"RIFF" and header[8:12] == b"WEBP":
        return "webp"
    return None


async def save_upload(file: UploadFile, subfolder: str = "profiles") -> str:
    max_bytes = settings.max_upload_mb * 1024 * 1024
    contents = await file.read()

    if len(contents) > max_bytes:
        raise HTTPException(status_code=400, detail=f"File too large (max {settings.max_upload_mb} MB)")

    if len(contents) < 12:
        raise HTTPException(status_code=400, detail="File too small to be a valid image")

    # Magic-byte check — ignore whatever the client claims in Content-Type
    detected = _detect_image_type(contents[:12])
    if detected is None:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, and WEBP images are allowed")

    filename = f"{subfolder}_{uuid.uuid4().hex}.{detected}"
    upload_path = Path(settings.upload_dir) / filename
    upload_path.parent.mkdir(parents=True, exist_ok=True)

    with open(upload_path, "wb") as f:
        f.write(contents)

    return f"/uploads/{filename}"
