from datetime import datetime, timezone
from sqlalchemy import String, Integer, DateTime, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class Deal(Base):
    __tablename__ = "deals"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(String(255), default="")
    remind_date: Mapped[str] = mapped_column(String(10), nullable=False)  # YYYY-MM-DD
    is_system: Mapped[bool] = mapped_column(Boolean, default=False)  # 系统预置 vs 用户自定义
    is_done: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
