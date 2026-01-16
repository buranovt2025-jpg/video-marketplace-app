from __future__ import annotations

from fastapi import Header, HTTPException


def get_current_user(authorization: str | None = Header(default=None)):
    """
    Minimal auth stub for this module.

    Integration target:
    - Replace with your real JWT auth (same contract as your existing backend).
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Unauthorized")

    # For demo purposes we treat any token as a user id.
    return {"id": token[:12], "name": "User"}

