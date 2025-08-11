from fastapi import APIRouter
from pydantic import BaseModel
from ..security import create_access_token

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginRequest(BaseModel):
    device_id: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest):
    # Simple passwordless login using device_id as user_id
    token = create_access_token(req.device_id)
    return TokenResponse(access_token=token)
