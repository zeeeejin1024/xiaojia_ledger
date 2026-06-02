from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.user_setting import UserSetting

router = APIRouter(prefix="/settings", tags=["设置"])


class BudgetUpdate(BaseModel):
    monthly_budget: float
    payday: int = 1
    cycle: str = "monthly"


@router.get("/budget", response_model=dict)
def get_budget(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    setting = db.query(UserSetting).filter(UserSetting.user_id == user.id).first()
    if not setting:
        setting = UserSetting(user_id=user.id, monthly_budget=3000, payday=1, cycle="monthly")
        db.add(setting)
        db.commit()
        db.refresh(setting)
    return {
        "code": 0,
        "data": {
            "monthly_budget": setting.monthly_budget,
            "payday": setting.payday,
            "cycle": setting.cycle,
        }
    }


@router.put("/budget", response_model=dict)
def update_budget(req: BudgetUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    setting = db.query(UserSetting).filter(UserSetting.user_id == user.id).first()
    if not setting:
        setting = UserSetting(user_id=user.id)
        db.add(setting)
    setting.monthly_budget = req.monthly_budget
    setting.payday = req.payday
    setting.cycle = req.cycle
    db.commit()
    return {"code": 0, "message": "已更新"}
