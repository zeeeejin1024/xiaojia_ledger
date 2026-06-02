#!/bin/bash
# 小满记账 v3.0 后端部署脚本
# 在宝塔终端中粘贴执行

set -e
cd /www/wwwroot/backend

echo "=== 小满记账 v3.0 部署开始 ==="

# --- 1. 新模型文件 ---
echo "创建模型文件..."

cat > app/models/user_setting.py << 'EOF'
from datetime import datetime, timezone
from sqlalchemy import String, Float, Integer, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class UserSetting(Base):
    __tablename__ = "user_settings"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False)
    monthly_budget: Mapped[float] = mapped_column(Float, default=3000)
    payday: Mapped[int] = mapped_column(Integer, default=1)
    cycle: Mapped[str] = mapped_column(String(20), default="monthly")
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
EOF

cat > app/models/wallet_budget.py << 'EOF'
from sqlalchemy import String, Float, Integer
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class WalletBudget(Base):
    __tablename__ = "wallet_budgets"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, nullable=False)
    wallet_type: Mapped[str] = mapped_column(String(20), nullable=False)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    amount: Mapped[float] = mapped_column(Float, default=0)
    color: Mapped[str] = mapped_column(String(20), default="")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
EOF

cat > app/models/deal.py << 'EOF'
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
    remind_date: Mapped[str] = mapped_column(String(10), nullable=False)
    is_system: Mapped[bool] = mapped_column(Boolean, default=False)
    is_done: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
EOF

echo "模型文件创建完成"

# --- 2. 新 API 端点 ---
echo "创建 API 文件..."

cat > app/api/ocr.py << 'EOF'
from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.services.ai_parser import parse_text
import base64

router = APIRouter(prefix="/ai", tags=["AI-OCR"])

class OcrRequest(BaseModel):
    image_base64: str

@router.post("/ocr", response_model=dict)
def ocr_single(req: OcrRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        img_data = base64.b64decode(req.image_base64)
    except Exception:
        return {"code": 1, "message": "图片数据无效"}
    text = _mock_ocr(img_data)
    if not text.strip():
        return {"code": 1, "message": "未识别到文字"}
    parsed = parse_text(text)
    return {"code": 0, "data": parsed}

@router.post("/ocr/batch", response_model=dict)
def ocr_batch(req_list: List[OcrRequest], user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    results = []
    for req in req_list:
        try:
            img_data = base64.b64decode(req.image_base64)
            text = _mock_ocr(img_data)
            parsed = parse_text(text) if text.strip() else {"amount": None, "category": None}
            results.append({"success": True, "data": parsed})
        except Exception:
            results.append({"success": False, "data": None})
    return {"code": 0, "data": {"items": results}}

def _mock_ocr(img_data: bytes) -> str:
    return ""
EOF

cat > app/api/budget.py << 'EOF'
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
        db.add(setting); db.commit(); db.refresh(setting)
    return {"code": 0, "data": {"monthly_budget": setting.monthly_budget, "payday": setting.payday, "cycle": setting.cycle}}

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
EOF

cat > app/api/wallets.py << 'EOF'
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
    wallets = db.query(WalletBudget).filter(WalletBudget.user_id == user.id).order_by(WalletBudget.sort_order).all()
    if not wallets:
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

    now = datetime.now()
    month_prefix = f"{now.year}-{now.month:02d}"
    records = db.query(Record).filter(Record.user_id == user.id, Record.date.startswith(month_prefix), Record.type == "expense").all()
    cat_map = {"餐饮": "food", "交通": "fun", "购物": "fun", "娱乐": "fun", "游戏": "gaming", "医疗": "food", "教育": "food"}
    spent = {"food": 0.0, "fun": 0.0, "gaming": 0.0, "saving": 0.0}
    for r in records:
        cat_name = r.category.name if r.category else ""
        wtype = cat_map.get(cat_name, "food")
        spent[wtype] = spent.get(wtype, 0) + r.amount

    result = []
    for w in wallets:
        used = spent.get(w.wallet_type, 0)
        result.append({"id": w.id, "wallet_type": w.wallet_type, "name": w.name, "amount": w.amount, "color": w.color, "spent": used, "remaining": w.amount - used, "pct": min(used / w.amount, 1.0) if w.amount > 0 else 0, "exhausted": used >= w.amount})
    return {"code": 0, "data": result}

@router.put("", response_model=dict)
def update_wallets(req: WalletUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
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
EOF

cat > app/api/reports.py << 'EOF'
from datetime import datetime, timedelta
from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session, joinedload
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.record import Record
from app.models.deal import Deal
from collections import defaultdict

router = APIRouter(tags=["AI助手"])

@router.get("/ai/report/weekly", response_model=dict)
def weekly_report(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    today = datetime.now().date()
    start = today - timedelta(days=7)
    start_str = start.strftime("%Y-%m-%d")
    end_str = today.strftime("%Y-%m-%d")
    records = db.query(Record).options(joinedload(Record.category)).filter(Record.user_id == user.id, Record.date >= start_str, Record.date <= end_str).order_by(Record.date.desc()).all()
    if not records:
        return {"code": 0, "data": {"has_data": False, "message": "本周还没有记账哦~"}}
    cat_totals = defaultdict(lambda: {"count": 0, "total": 0.0, "emoji": ""})
    total_expense = 0.0
    for r in records:
        if r.type == "expense":
            cn = r.category.name if r.category else "其他"
            ce = r.category.emoji if r.category else ""
            cat_totals[cn]["count"] += 1
            cat_totals[cn]["total"] += r.amount
            cat_totals[cn]["emoji"] = ce
            total_expense += r.amount
    if total_expense == 0:
        return {"code": 0, "data": {"has_data": False, "message": "本周只有收入没有支出，太棒啦！"}}
    top_cats = sorted(cat_totals.items(), key=lambda x: x[1]["total"], reverse=True)[:3]
    suggestions = _generate_suggestions(top_cats)
    return {"code": 0, "data": {"has_data": True, "period": f"{start_str} - {end_str}", "total_expense": total_expense, "top_categories": [{"name": k, "count": v["count"], "total": v["total"], "emoji": v["emoji"]} for k, v in top_cats], "suggestions": suggestions}}

def _generate_suggestions(top_cats):
    suggestions = []
    templates = {"奶茶": "如果你每周少喝 2 杯，一个月就能省 ¥60 哦～攒下来可以买一个小满定制手办！🎁", "外卖": "外卖虽然方便，但自己做饭更省钱哦～试试每周自己做 2 顿饭？", "游戏": "游戏充值要适度哦～小满提醒你把游戏预算控制在 ¥100 以内！", "饮料": "少喝饮料多喝水，省钱又健康！💪", "零食": "零食虽好吃，但吃多了对身体不好哦～", "交通": "短距离可以走路或骑车，既省钱又锻炼身体！", "购物": "买买买之前先问自己：我真的需要吗？", "娱乐": "快乐很重要，但要量力而行哦～"}
    for cat_name, data in top_cats:
        for keyword, msg in templates.items():
            if keyword in cat_name:
                suggestions.append({"category": cat_name, "emoji": data["emoji"], "total": data["total"], "count": data["count"], "message": msg, "potential_save": round(data["total"] * 0.3, 0)})
                break
        else:
            suggestions.append({"category": cat_name, "emoji": data["emoji"], "total": data["total"], "count": data["count"], "message": f"小满发现你在'{cat_name}'上花了 ¥{data['total']:.0f}，看看能不能减少一点呢～", "potential_save": round(data["total"] * 0.2, 0)})
    return suggestions[:3]

@router.get("/ai/subscriptions", response_model=dict)
def detect_subscriptions(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    records = db.query(Record).options(joinedload(Record.category)).filter(Record.user_id == user.id, Record.type == "expense").order_by(Record.date.desc()).all()
    pattern_map = defaultdict(list)
    for r in records:
        if r.note and any(kw in (r.note or "") for kw in ["会员", "VIP", "订阅", "月卡", "季卡", "年卡", "自动续费"]):
            key = f"{r.category.name}|{r.amount}"
            pattern_map[key].append(r)
    subscriptions = []
    member_keywords = ["视频", "音乐", "云盘", "阅读", "加速", "工具", "网盘", "会员", "VIP", "订阅"]
    for key, recs in pattern_map.items():
        if len(recs) >= 2:
            cat_name, amount = key.split("|")
            is_member = any(kw in (recs[0].note or "") or kw in cat_name for kw in member_keywords)
            if is_member or len(recs) >= 3:
                last_date = max(r.date for r in recs)
                days_ago = (datetime.now().date() - datetime.strptime(last_date, "%Y-%m-%d").date()).days
                subscriptions.append({"name": cat_name, "amount": float(amount), "last_use_days_ago": days_ago, "occurrences": len(recs), "note": recs[0].note or "", "likely_unused": days_ago > 30, "yearly_cost": float(amount) * 12})
    return {"code": 0, "data": subscriptions}

class DealCreate(BaseModel):
    title: str
    description: str = ""
    remind_date: str

MONTHLY_DEALS = {"01-01": "元旦特惠：各平台有新年红包活动！", "01-20": "支付宝集五福活动即将开始～", "02-14": "情人节：各大商家有折扣哦！", "03-08": "女神节：化妆品、服饰大促！", "06-18": "618年中大促！别错过！", "08-08": "支付宝会员日：积分兑换特权", "10-01": "国庆大促：各大平台全面降价", "11-11": "双十一！但别冲动消费哦～", "12-12": "双十二年终大促最后一波", "每月20日": "支付宝会员日：肯德基有半价活动，不要错过哦～"}

def _get_system_deals(today_mmdd):
    result = []
    for key, msg in MONTHLY_DEALS.items():
        if "每月" in key:
            day = key.replace("每月", "").replace("日", "")
            if today_mmdd.endswith(f"-{day}"):
                result.append({"title": key, "description": msg, "remind_date": datetime.now().strftime("%Y-%m-%d"), "id": -1})
        elif key == today_mmdd:
            result.append({"title": key, "description": msg, "remind_date": datetime.now().strftime("%Y-%m-%d"), "id": -1})
    return result

@router.get("/deals", response_model=dict)
def get_deals(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    today = datetime.now().strftime("%m-%d")
    system_deals = _get_system_deals(today)
    user_deals = db.query(Deal).filter(Deal.user_id == user.id, Deal.is_done == False).all()
    result = system_deals + [{"title": d.title, "description": d.description, "remind_date": d.remind_date, "id": d.id} for d in user_deals]
    return {"code": 0, "data": sorted(result, key=lambda x: x["remind_date"])}

@router.post("/deals", response_model=dict)
def create_deal(req: DealCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    deal = Deal(user_id=user.id, title=req.title, description=req.description, remind_date=req.remind_date)
    db.add(deal); db.commit()
    return {"code": 0, "message": "已添加提醒"}

@router.delete("/deals/{deal_id}", response_model=dict)
def delete_deal(deal_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    deal = db.query(Deal).filter(Deal.id == deal_id, Deal.user_id == user.id).first()
    if deal: db.delete(deal); db.commit()
    return {"code": 0, "message": "已删除"}
EOF

echo "API 文件创建完成"

# --- 3. 更新已有文件 ---
echo "更新 router.py 和 main.py..."

cat > app/api/router.py << 'EOF'
from fastapi import APIRouter
from app.api.auth import router as auth_router
from app.api.categories import router as categories_router
from app.api.records import router as records_router
from app.api.stats import router as stats_router
from app.api.export import router as export_router
from app.api.savings import router as savings_router
from app.api.sync import router as sync_router
from app.api.ai import router as ai_router
from app.api.ocr import router as ocr_router
from app.api.budget import router as budget_router
from app.api.wallets import router as wallets_router
from app.api.reports import router as reports_router

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router)
api_router.include_router(categories_router)
api_router.include_router(records_router)
api_router.include_router(stats_router)
api_router.include_router(export_router)
api_router.include_router(savings_router)
api_router.include_router(sync_router)
api_router.include_router(ai_router)
api_router.include_router(ocr_router)
api_router.include_router(budget_router)
api_router.include_router(wallets_router)
api_router.include_router(reports_router)
EOF

cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.core.database import init_db
from app.api.router import api_router
from app.models.category import seed_categories
from app.models.user_setting import UserSetting
from app.models.wallet_budget import WalletBudget
from app.models.deal import Deal
from app.core.database import Session, engine


def _setup():
    init_db()
    db = Session(engine)
    try:
        seed_categories(db)
    finally:
        db.close()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
)
app.add_event_handler("startup", _setup)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/")
def root():
    return {"name": settings.APP_NAME, "version": settings.VERSION}
EOF

echo "已更新 router.py 和 main.py"

# --- 4. 重启服务 ---
echo "重启服务..."
systemctl restart xiaojia
sleep 3
systemctl status xiaojia --no-pager -l

echo ""
echo "=== 部署完成！==="
echo "测试: curl http://114.55.138.55/api/v1/"
