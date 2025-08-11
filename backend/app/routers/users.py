from fastapi import APIRouter, Depends, HTTPException

from ..redis_client import get_redis
from ..security import get_current_user

router = APIRouter(prefix="/users", tags=["users"])


@router.delete("/me")
async def gdpr_delete(user_id: str | None = Depends(get_current_user)):
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")
    redis = await get_redis()
    # Remove favorites set and any other user-scoped keys (prefix cleanup)
    await redis.delete(f"fav:{user_id}")
    # In real app: also scrub PII and DB rows.
    return {"deleted": True}
