from __future__ import annotations

import uuid
from dataclasses import dataclass

import boto3

from .config import Settings


@dataclass(frozen=True)
class UploadSession:
    upload_url: str
    file_url: str
    headers: dict[str, str]
    expires_in: int


def _client(settings: Settings):
    if not (settings.s3_endpoint and settings.s3_region and settings.s3_access_key_id and settings.s3_secret_access_key):
        raise ValueError("S3 settings are not configured")
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint,
        region_name=settings.s3_region,
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_secret_access_key,
    )


def create_presigned_put(
    settings: Settings,
    *,
    user_id: str,
    kind: str,
    filename: str,
    content_type: str,
) -> UploadSession:
    if not settings.s3_bucket:
        raise ValueError("S3_BUCKET is not configured")
    if not settings.s3_public_base_url:
        raise ValueError("S3_PUBLIC_BASE_URL is not configured")

    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"
    key = f"uploads/{user_id}/{kind}/{uuid.uuid4().hex}.{ext}"

    s3 = _client(settings)
    upload_url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": settings.s3_bucket,
            "Key": key,
            "ContentType": content_type,
            # Uncomment if you want the object publicly readable by default.
            # "ACL": "public-read",
        },
        ExpiresIn=settings.upload_url_ttl_seconds,
    )

    file_url = f"{settings.s3_public_base_url.rstrip('/')}/{key}"
    return UploadSession(
        upload_url=upload_url,
        file_url=file_url,
        headers={"Content-Type": content_type},
        expires_in=settings.upload_url_ttl_seconds,
    )

