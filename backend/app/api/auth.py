from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.user import RegisterRequest, LoginRequest, AuthResponse, UserInfo
from app.schemas.common import success, error

router = APIRouter(prefix="/auth", tags=["认证"])


@router.post("/register")
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.username == data.username).first()
    if existing:
        return error(409, "用户名已存在")

    user = User(
        username=data.username,
        password_hash=hash_password(data.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id)
    return success(data=AuthResponse(username=user.username, token=token).model_dump())


@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data.username).first()
    if not user or not verify_password(data.password, user.password_hash):
        return error(401, "用户名或密码错误")

    token = create_access_token(user.id)
    return success(data=AuthResponse(username=user.username, token=token).model_dump())


@router.get("/me")
def get_me(user: User = Depends(get_current_user)):
    return success(data=UserInfo(username=user.username).model_dump())
