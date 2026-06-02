from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.wallet_budget import WalletBudget
from app.models.record import Record
from datetime import datetime

router = APIRouter(prefix="/wallets", tags=["钱包"])


class WalletUpdate(BaseModel):
    wallets: List[dict]


@router.get("", response_model=dict)
def get_wallets(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """获取所有钱包分区及当月余额"""
    wallets = db.query(WalletBudget).filter(WalletBudget.user_id == user.id).order_by(WalletBudget.sort_order).all()
    if not wallets:
        # 首次自动创建默认四个钱包
        defaults = [
            {"wallet_type": "food", "name": "吃饭钱包", "amount": 1500, "color": "#7BAF8A", "sort_order": 0},
            {"wallet_type": "fun", "name": "快乐钱包", "amount": 800, "color": "#7BAED4", "sort_order": 1},
            {"wallet_type": "gaming", "name": "游戏钱包", "amount": 300, "color": "#E8806A", "sort_order": 2},
            {"wallet_type": "saving", "name": "攒钱钱包", "amount": 400, "color": "#F5C542", "sort_order": 3},
        ]
        for d in defaults:
            w = WalletBudget(user_id=user.id, **d)
            db.add(w)
        db.commit()
        wallets = db.query(WalletBudget).filter(WalletBudget.user_id == user.id).order_by(WalletBudget.sort_order).all()

    # 计算本月已花
    now = datetime.now()
    month_prefix = f"{now.year}-{now.month:02d}"
    records = db.query(Record).filter(Record.user_id == user.id, Record.date.startswith(month_prefix), Record.type == "expense").all()

    # 简单按钱包类型聚合（通过分类映射）
    cat_map = {"餐饮": "food", "交通": "fun", "购物": "fun", "娱乐": "fun", "游戏": "gaming", "医疗": "food", "教育": "food"}
    spent = {"food": 0.0, "fun": 0.0, "gaming": 0.0, "saving": 0.0}
    for r in records:
        cat_name = r.category.name if r.category else ""
        wtype = cat_map.get(cat_name, "food")
        spent[wtype] = spent.get(wtype, 0) + r.amount

    result = []
    for w in wallets:
        used = spent.get(w.wallet_type, 0)
        result.append({
            "id": w.id, "wallet_type": w.wallet_type, "name": w.name,
            "amount": w.amount, "color": w.color,
            "spent": used, "remaining": w.amount - used,
            "pct": min(used / w.amount, 1.0) if w.amount > 0 else 0,
            "exhausted": used >= w.amount,
        })

    return {"code": 0, "data": result}


@router.put("", response_model=dict)
def update_wallets(req: WalletUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """批量更新钱包分区"""
    for item in req.wallets:
        wid = item.get("id")
        if wid:
            w = db.query(WalletBudget).filter(WalletBudget.id == wid, WalletBudget.user_id == user.id).first()
            if w:
                w.amount = item.get("amount", w.amount)
                w.name = item.get("name", w.name)
                w.color = item.get("color", w.color)
    db.commit()
    return {"code": 0, "message": "已更新"}
