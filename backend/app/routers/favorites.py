from fastapi import APIRouter, Depends, HTTPException
from typing import List

from ..security import get_current_user
from ..redis_client import get_redis
from ..services import load_quotes
from .quotes import QuoteOut

router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.get("/", response_model=List[QuoteOut])
async def list_favorites(user_id: str | None = Depends(get_current_user)):
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")
    redis = await get_redis()
    ids = await redis.smembers(f"fav:{user_id}")
    id_set = set(ids or [])
    quotes = [q for q in load_quotes() if str(q.id) in id_set]
    return [QuoteOut(**q.__dict__) for q in quotes]


@router.post("/{quote_id}")
async def add_favorite(quote_id: str, user_id: str | None = Depends(get_current_user)):
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")
    redis = await get_redis()
    await redis.sadd(f"fav:{user_id}", str(quote_id))
    return {"ok": True}


@router.delete("/{quote_id}")
async def remove_favorite(quote_id: str, user_id: str | None = Depends(get_current_user)):
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")
    redis = await get_redis()
    await redis.srem(f"fav:{user_id}", str(quote_id))
    return {"ok": True}
