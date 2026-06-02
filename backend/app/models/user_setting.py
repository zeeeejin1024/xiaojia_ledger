from datetime import datetime, timezone
from sqlalchemy import String, Float, Integer, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class UserSetting(Base):
    __tablename__ = "user_settings"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False)
    monthly_budget: Mapped[float] = mapped_column(Float, default=3000)
    payday: Mapped[int] = mapped_column(Integer, default=1)  # 每月几号发生活费
    cycle: Mapped[str] = mapped_column(String(20), default="monthly")  # monthly / semester
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
