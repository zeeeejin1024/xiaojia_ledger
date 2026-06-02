from datetime import datetime, timezone
from sqlalchemy import String, DateTime, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from typing import Optional

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    username: Mapped[Optional[str]] = mapped_column(String(24), unique=True, nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String(20), unique=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    security_question: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    security_answer_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    migrated: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc)
    )
