from __future__ import annotations

from datetime import datetime, timezone
from typing import Literal

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query
from pydantic import BaseModel, Field

from .auth import get_current_user
from .config import get_settings
from .db import db_conn, init_db
from .s3_uploads import create_presigned_put


load_dotenv()  # optional local dev
init_db()

app = FastAPI(title="GoGoMarket backend module", version="0.1.0")


@app.get("/healthz")
def healthz():
    return {"ok": True}


class UploadRequest(BaseModel):
    kind: Literal["reel_video", "story_video", "story_image", "product_image"]
    filename: str = Field(min_length=1, max_length=255)
    content_type: str = Field(min_length=3, max_length=255)
    size_bytes: int = Field(ge=1, le=200 * 1024 * 1024)  # safety max 200MB


@app.post("/api/uploads")
def api_uploads(req: UploadRequest, user=Depends(get_current_user)):
    settings = get_settings()

    # Per-kind size limits (match frontend defaults where possible)
    if req.kind in ("reel_video", "story_video") and req.size_bytes > 50 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large for video")
    if req.kind in ("story_image", "product_image") and req.size_bytes > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large for image")

    try:
        session = create_presigned_put(
            settings,
            user_id=str(user["id"]),
            kind=req.kind,
            filename=req.filename,
            content_type=req.content_type,
        )
    except ValueError as e:
        raise HTTPException(status_code=501, detail=str(e))

    return {
        "upload_url": session.upload_url,
        "file_url": session.file_url,
        "headers": session.headers,
        "expires_in": session.expires_in,
    }


class CreateReviewRequest(BaseModel):
    rating: int = Field(ge=1, le=5)
    text: str | None = Field(default=None, max_length=1000)


@app.get("/api/products/{product_id}/reviews")
def get_reviews(
    product_id: str,
    limit: int = Query(default=50, ge=1, le=200),
    cursor: int | None = Query(default=None, ge=1),
):
    init_db()
    with db_conn() as conn:
        if cursor is None:
            rows = conn.execute(
                "SELECT * FROM product_reviews WHERE product_id = ? ORDER BY id DESC LIMIT ?",
                (product_id, limit),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM product_reviews WHERE product_id = ? AND id < ? ORDER BY id DESC LIMIT ?",
                (product_id, cursor, limit),
            ).fetchall()

        items = [dict(r) for r in rows]
        next_cursor = items[-1]["id"] if len(items) == limit else None

        agg = conn.execute(
            "SELECT COUNT(*) as c, AVG(rating) as a FROM product_reviews WHERE product_id = ?",
            (product_id,),
        ).fetchone()

    return {
        "items": items,
        "next_cursor": next_cursor,
        "summary": {"count": int(agg["c"] or 0), "avg_rating": float(agg["a"] or 0.0)},
    }


@app.post("/api/products/{product_id}/reviews")
def create_review(product_id: str, req: CreateReviewRequest, user=Depends(get_current_user)):
    init_db()
    now = datetime.now(timezone.utc).isoformat()
    with db_conn() as conn:
        conn.execute(
            "INSERT INTO product_reviews(product_id, author_id, author_name, rating, text, created_at) VALUES (?,?,?,?,?,?)",
            (
                product_id,
                str(user["id"]),
                str(user.get("name") or "User"),
                int(req.rating),
                (req.text or None),
                now,
            ),
        )
        rid = conn.execute("SELECT last_insert_rowid() as id").fetchone()["id"]
        row = conn.execute("SELECT * FROM product_reviews WHERE id = ?", (rid,)).fetchone()
        agg = conn.execute(
            "SELECT COUNT(*) as c, AVG(rating) as a FROM product_reviews WHERE product_id = ?",
            (product_id,),
        ).fetchone()

    return {
        "review": dict(row),
        "summary": {"count": int(agg["c"] or 0), "avg_rating": float(agg["a"] or 0.0)},
    }

