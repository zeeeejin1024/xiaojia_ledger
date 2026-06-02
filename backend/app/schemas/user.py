from typing import Optional
from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    username: Optional[str] = None
    phone: Optional[str] = None
    password: str = Field(min_length=6)
    security_question: Optional[str] = None
    security_answer: Optional[str] = None


class LoginRequest(BaseModel):
    username: str
    password: str


class AuthResponse(BaseModel):
    username: str
    token: str


class UserInfo(BaseModel):
    username: str
