from __future__ import annotations

from dataclasses import dataclass
import os


@dataclass(frozen=True)
class Settings:
    app_env: str

    s3_endpoint: str | None
    s3_region: str | None
    s3_bucket: str | None
    s3_access_key_id: str | None
    s3_secret_access_key: str | None
    s3_public_base_url: str | None

    upload_url_ttl_seconds: int


def get_settings() -> Settings:
    return Settings(
        app_env=os.getenv("APP_ENV", "dev"),
        s3_endpoint=os.getenv("S3_ENDPOINT"),
        s3_region=os.getenv("S3_REGION"),
        s3_bucket=os.getenv("S3_BUCKET"),
        s3_access_key_id=os.getenv("S3_ACCESS_KEY_ID"),
        s3_secret_access_key=os.getenv("S3_SECRET_ACCESS_KEY"),
        s3_public_base_url=os.getenv("S3_PUBLIC_BASE_URL"),
        upload_url_ttl_seconds=int(os.getenv("UPLOAD_URL_TTL_SECONDS", "900")),
    )

