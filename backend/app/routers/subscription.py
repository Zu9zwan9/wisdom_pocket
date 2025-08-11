from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel
from typing import Optional

from ..config import settings
from ..redis_client import get_redis
from ..security import get_current_user

router = APIRouter(prefix="/subscription", tags=["subscription"])


class ValidateResponse(BaseModel):
    active: bool
    plan: Optional[str] = None


@router.post("/webhook")
async def revenuecat_webhook(authorization: str | None = Header(default=None)):
    # Simple signature check placeholder
    if authorization != settings.REVENUECAT_SECRET:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return {"ok": True}


@router.get("/validate", response_model=ValidateResponse)
async def validate_subscription(user_id: str | None = Depends(get_current_user)):
    if not user_id:
        return ValidateResponse(active=False)
    redis = await get_redis()
    active = bool(await redis.get(f"sub:{user_id}") or False)
    return ValidateResponse(active=active, plan="pro" if active else None)


@router.post("/mock_purchase")
async def mock_purchase(user_id: str | None = Depends(get_current_user)):
    if not settings.USE_REVENUECAT_MOCK:
        raise HTTPException(status_code=403, detail="Mock disabled")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")
    redis = await get_redis()
    await redis.set(f"sub:{user_id}", 1, ex=60 * 60 * 24 * 30)
    return {"active": True}
