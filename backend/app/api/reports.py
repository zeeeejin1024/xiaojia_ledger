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


# ============================================================
# 省钱周报
# ============================================================
@router.get("/ai/report/weekly", response_model=dict)
def weekly_report(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """生成本周省钱报告"""
    today = datetime.now().date()
    start = today - timedelta(days=7)
    start_str = start.strftime("%Y-%m-%d")
    end_str = today.strftime("%Y-%m-%d")

    records = (
        db.query(Record)
        .options(joinedload(Record.category))
        .filter(Record.user_id == user.id, Record.date >= start_str, Record.date <= end_str)
        .order_by(Record.date.desc())
        .all()
    )

    if not records:
        return {"code": 0, "data": {"has_data": False, "message": "本周还没有记账哦~"}}

    # 按分类聚合
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

    # 排序取 Top 3 消费分类
    top_cats = sorted(cat_totals.items(), key=lambda x: x[1]["total"], reverse=True)[:3]
    suggestions = _generate_suggestions(top_cats)

    return {
        "code": 0,
        "data": {
            "has_data": True,
            "period": f"{start_str} - {end_str}",
            "total_expense": total_expense,
            "top_categories": [{"name": k, "count": v["count"], "total": v["total"], "emoji": v["emoji"]} for k, v in top_cats],
            "suggestions": suggestions,
        }
    }


def _generate_suggestions(top_cats):
    """用模板生成小满语气的建议"""
    suggestions = []
    templates = {
        "奶茶": "如果你每周少喝 2 杯，一个月就能省 ¥60 哦～攒下来可以买一个小满手办！🎁",
        "外卖": "外卖虽然方便，但自己做饭更省钱哦～试试每周自己做 2 顿饭？",
        "游戏": "游戏充值要适度哦～小满提醒你把游戏预算控制在 ¥100 以内！",
        "饮料": "少喝饮料多喝水，省钱又健康！💪",
        "零食": "零食虽好吃，但吃多了对身体不好哦～",
        "交通": "短距离可以走路或骑车，既省钱又锻炼身体！",
        "购物": "买买买之前先问自己：我真的需要吗？",
        "娱乐": "快乐很重要，但要量力而行哦～",
    }
    for cat_name, data in top_cats:
        for keyword, msg in templates.items():
            if keyword in cat_name:
                suggestions.append({
                    "category": cat_name,
                    "emoji": data["emoji"],
                    "total": data["total"],
                    "count": data["count"],
                    "message": msg,
                    "potential_save": round(data["total"] * 0.3, 0),
                })
                break
        else:
            suggestions.append({
                "category": cat_name,
                "emoji": data["emoji"],
                "total": data["total"],
                "count": data["count"],
                "message": f"小满发现你在'{cat_name}'上花了 ¥{data['total']:.0f}，看看能不能减少一点呢～",
                "potential_save": round(data["total"] * 0.2, 0),
            })
    return suggestions[:3]


# ============================================================
# 无用会员检测
# ============================================================
@router.get("/ai/subscriptions", response_model=dict)
def detect_subscriptions(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """扫描固定支出，识别疑似会员/订阅"""
    records = (
        db.query(Record)
        .options(joinedload(Record.category))
        .filter(Record.user_id == user.id, Record.type == "expense")
        .order_by(Record.date.desc())
        .all()
    )

    # 查找相同金额、相同分类且在不同月份出现的记录
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
            # 检查是否包含已知会员关键词
            is_member = any(kw in (recs[0].note or "") or kw in cat_name for kw in member_keywords)
            if is_member or len(recs) >= 3:
                last_date = max(r.date for r in recs)
                days_ago = (datetime.now().date() - datetime.strptime(last_date, "%Y-%m-%d").date()).days
                subscriptions.append({
                    "name": cat_name,
                    "amount": float(amount),
                    "last_use_days_ago": days_ago,
                    "occurrences": len(recs),
                    "note": recs[0].note or "",
                    "likely_unused": days_ago > 30,
                    "yearly_cost": float(amount) * 12,
                })

    return {"code": 0, "data": subscriptions}


# ============================================================
# 薅羊毛提醒
# ============================================================
class DealCreate(BaseModel):
    title: str
    description: str = ""
    remind_date: str

@router.get("/deals", response_model=dict)
def get_deals(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """获取近期优惠提醒"""
    # 系统预置 + 用户自定义
    today = datetime.now().strftime("%m-%d")
    system_deals = _get_system_deals(today)
    user_deals = db.query(Deal).filter(Deal.user_id == user.id, Deal.is_done == False).all()
    result = system_deals + [{"title": d.title, "description": d.description, "remind_date": d.remind_date, "id": d.id} for d in user_deals]
    return {"code": 0, "data": sorted(result, key=lambda x: x["remind_date"])}


@router.post("/deals", response_model=dict)
def create_deal(req: DealCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """添加自定义薅羊毛提醒"""
    deal = Deal(user_id=user.id, title=req.title, description=req.description, remind_date=req.remind_date)
    db.add(deal)
    db.commit()
    return {"code": 0, "message": "已添加提醒"}


@router.delete("/deals/{deal_id}", response_model=dict)
def delete_deal(deal_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    deal = db.query(Deal).filter(Deal.id == deal_id, Deal.user_id == user.id).first()
    if deal: db.delete(deal); db.commit()
    return {"code": 0, "message": "已删除"}


MONTHLY_DEALS = {
    "01-01": "元旦特惠：各平台有新年红包活动！",
    "01-20": "支付宝集五福活动即将开始～",
    "02-14": "情人节：各大商家有折扣哦！",
    "03-08": "女神节：化妆品、服饰大促！",
    "04-01": "愚人节：小心被商家套路～",
    "06-18": "618年中大促！别错过！",
    "08-08": "支付宝会员日：积分兑换特权",
    "10-01": "国庆大促：各大平台全面降价",
    "11-11": "双十一！但别冲动消费哦～",
    "12-12": "双十二年终大促最后一波",
    "每月20日": "支付宝会员日：肯德基有半价活动，不要错过哦～",
}


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
