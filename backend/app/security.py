from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import jwt, JWTError
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from .config import settings

security_scheme = HTTPBearer(auto_error=False)


def create_access_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = {"sub": user_id, "iat": datetime.now(timezone.utc).timestamp()}
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire.timestamp()})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALG)
    return encoded_jwt


def get_current_user(credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme)) -> Optional[str]:
    if not credentials:
        return None
    try:
        payload = jwt.decode(credentials.credentials, settings.JWT_SECRET, algorithms=[settings.JWT_ALG])
        return str(payload.get("sub"))
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
