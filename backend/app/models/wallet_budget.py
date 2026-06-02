from sqlalchemy import String, Float, Integer
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class WalletBudget(Base):
    __tablename__ = "wallet_budgets"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, nullable=False)
    wallet_type: Mapped[str] = mapped_column(String(20), nullable=False)  # food/fun/gaming/saving
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    amount: Mapped[float] = mapped_column(Float, default=0)
    color: Mapped[str] = mapped_column(String(20), default="")  # hex color
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
