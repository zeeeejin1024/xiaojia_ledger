from typing import List, Optional
from sqlalchemy import String, Integer, Boolean, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

import enum


class RecordType(str, enum.Enum):
    income = "income"
    expense = "expense"
    savings = "savings"


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    parent_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("categories.id"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    type: Mapped[RecordType] = mapped_column(
        SAEnum(RecordType, name="record_type"), nullable=False
    )
    emoji: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_system: Mapped[bool] = mapped_column(Boolean, default=True)


# ===== 种子数据 =====
SEED_CATEGORIES: List[dict] = [
    # === 支出 ===
    # 餐饮
    {"id": 1, "parent_id": None, "name": "餐饮", "type": "expense", "emoji": "🍽️", "sort_order": 1},
    {"id": 2, "parent_id": 1, "name": "早餐", "type": "expense", "emoji": "🥐", "sort_order": 1},
    {"id": 3, "parent_id": 1, "name": "午餐", "type": "expense", "emoji": "🍱", "sort_order": 2},
    {"id": 4, "parent_id": 1, "name": "晚餐", "type": "expense", "emoji": "🍛", "sort_order": 3},
    {"id": 5, "parent_id": 1, "name": "宵夜", "type": "expense", "emoji": "🌙", "sort_order": 4},
    {"id": 6, "parent_id": 1, "name": "零食", "type": "expense", "emoji": "🍿", "sort_order": 5},
    {"id": 7, "parent_id": 1, "name": "奶茶咖啡", "type": "expense", "emoji": "🧋", "sort_order": 6},
    {"id": 8, "parent_id": 1, "name": "水果", "type": "expense", "emoji": "🍎", "sort_order": 7},
    {"id": 9, "parent_id": 1, "name": "外卖", "type": "expense", "emoji": "🛵", "sort_order": 8},
    {"id": 10, "parent_id": 1, "name": "烘焙面包", "type": "expense", "emoji": "🍞", "sort_order": 9},
    # 交通
    {"id": 11, "parent_id": None, "name": "交通", "type": "expense", "emoji": "🚇", "sort_order": 2},
    {"id": 12, "parent_id": 11, "name": "地铁公交", "type": "expense", "emoji": "🚇", "sort_order": 1},
    {"id": 13, "parent_id": 11, "name": "打车", "type": "expense", "emoji": "🚕", "sort_order": 2},
    {"id": 14, "parent_id": 11, "name": "加油", "type": "expense", "emoji": "⛽", "sort_order": 3},
    {"id": 15, "parent_id": 11, "name": "停车", "type": "expense", "emoji": "🅿️", "sort_order": 4},
    {"id": 16, "parent_id": 11, "name": "高铁火车", "type": "expense", "emoji": "🚄", "sort_order": 5},
    {"id": 17, "parent_id": 11, "name": "飞机", "type": "expense", "emoji": "✈️", "sort_order": 6},
    {"id": 18, "parent_id": 11, "name": "共享单车", "type": "expense", "emoji": "🚲", "sort_order": 7},
    # 购物
    {"id": 19, "parent_id": None, "name": "购物", "type": "expense", "emoji": "🛒", "sort_order": 3},
    {"id": 20, "parent_id": 19, "name": "衣服鞋帽", "type": "expense", "emoji": "👗", "sort_order": 1},
    {"id": 21, "parent_id": 19, "name": "化妆品护肤", "type": "expense", "emoji": "💄", "sort_order": 2},
    {"id": 22, "parent_id": 19, "name": "电子产品", "type": "expense", "emoji": "📱", "sort_order": 3},
    {"id": 23, "parent_id": 19, "name": "家居日用", "type": "expense", "emoji": "🏠", "sort_order": 4},
    {"id": 24, "parent_id": 19, "name": "书籍文具", "type": "expense", "emoji": "📚", "sort_order": 5},
    {"id": 25, "parent_id": 19, "name": "超市杂货", "type": "expense", "emoji": "🛒", "sort_order": 6},
    # 娱乐
    {"id": 26, "parent_id": None, "name": "娱乐", "type": "expense", "emoji": "🎬", "sort_order": 4},
    {"id": 27, "parent_id": 26, "name": "电影演出", "type": "expense", "emoji": "🎬", "sort_order": 1},
    {"id": 28, "parent_id": 26, "name": "游戏氪金", "type": "expense", "emoji": "🎮", "sort_order": 2},
    {"id": 29, "parent_id": 26, "name": "KTV聚会", "type": "expense", "emoji": "🎤", "sort_order": 3},
    {"id": 30, "parent_id": 26, "name": "旅行旅游", "type": "expense", "emoji": "✈️", "sort_order": 4},
    {"id": 31, "parent_id": 26, "name": "运动健身", "type": "expense", "emoji": "🏋️", "sort_order": 5},
    {"id": 32, "parent_id": 26, "name": "桌游密室", "type": "expense", "emoji": "🎯", "sort_order": 6},
    # 居住
    {"id": 33, "parent_id": None, "name": "居住", "type": "expense", "emoji": "🏠", "sort_order": 5},
    {"id": 34, "parent_id": 33, "name": "房租", "type": "expense", "emoji": "🏠", "sort_order": 1},
    {"id": 35, "parent_id": 33, "name": "水电燃气", "type": "expense", "emoji": "💡", "sort_order": 2},
    {"id": 36, "parent_id": 33, "name": "物业", "type": "expense", "emoji": "🏢", "sort_order": 3},
    {"id": 37, "parent_id": 33, "name": "网费话费", "type": "expense", "emoji": "📶", "sort_order": 4},
    {"id": 38, "parent_id": 33, "name": "维修家装", "type": "expense", "emoji": "🔧", "sort_order": 5},
    {"id": 39, "parent_id": 33, "name": "保洁清洁", "type": "expense", "emoji": "🧹", "sort_order": 6},
    # 学习
    {"id": 40, "parent_id": None, "name": "学习", "type": "expense", "emoji": "📖", "sort_order": 6},
    {"id": 41, "parent_id": 40, "name": "课程培训", "type": "expense", "emoji": "📖", "sort_order": 1},
    {"id": 42, "parent_id": 40, "name": "考试报名", "type": "expense", "emoji": "📝", "sort_order": 2},
    {"id": 43, "parent_id": 40, "name": "资料打印", "type": "expense", "emoji": "🖨️", "sort_order": 3},
    # 医疗
    {"id": 44, "parent_id": None, "name": "医疗", "type": "expense", "emoji": "🏥", "sort_order": 7},
    {"id": 45, "parent_id": 44, "name": "看病门诊", "type": "expense", "emoji": "🏥", "sort_order": 1},
    {"id": 46, "parent_id": 44, "name": "买药", "type": "expense", "emoji": "💊", "sort_order": 2},
    {"id": 47, "parent_id": 44, "name": "体检", "type": "expense", "emoji": "🩺", "sort_order": 3},
    {"id": 48, "parent_id": 44, "name": "牙科眼科", "type": "expense", "emoji": "🦷", "sort_order": 4},
    # 人情
    {"id": 49, "parent_id": None, "name": "人情", "type": "expense", "emoji": "🎁", "sort_order": 8},
    {"id": 50, "parent_id": 49, "name": "送礼红包", "type": "expense", "emoji": "🎁", "sort_order": 1},
    {"id": 51, "parent_id": 49, "name": "婚礼份子", "type": "expense", "emoji": "💒", "sort_order": 2},
    {"id": 52, "parent_id": 49, "name": "聚餐AA", "type": "expense", "emoji": "🍽️", "sort_order": 3},
    # 宠物
    {"id": 53, "parent_id": None, "name": "宠物", "type": "expense", "emoji": "🐱", "sort_order": 9},
    {"id": 54, "parent_id": 53, "name": "宠物粮食", "type": "expense", "emoji": "🐱", "sort_order": 1},
    {"id": 55, "parent_id": 53, "name": "宠物医疗", "type": "expense", "emoji": "🏥", "sort_order": 2},
    {"id": 56, "parent_id": 53, "name": "宠物用品", "type": "expense", "emoji": "🐾", "sort_order": 3},
    # 生活服务
    {"id": 57, "parent_id": None, "name": "生活服务", "type": "expense", "emoji": "✂️", "sort_order": 10},
    {"id": 58, "parent_id": 57, "name": "理发造型", "type": "expense", "emoji": "✂️", "sort_order": 1},
    {"id": 59, "parent_id": 57, "name": "按摩SPA", "type": "expense", "emoji": "💆", "sort_order": 2},
    {"id": 60, "parent_id": 57, "name": "快递物流", "type": "expense", "emoji": "📦", "sort_order": 3},
    {"id": 61, "parent_id": 57, "name": "会员订阅", "type": "expense", "emoji": "🎫", "sort_order": 4},
    # 其他支出
    {"id": 62, "parent_id": None, "name": "其他支出", "type": "expense", "emoji": "💌", "sort_order": 11},

    # === 收入 ===
    {"id": 70, "parent_id": None, "name": "收入来源", "type": "income", "emoji": "💰", "sort_order": 1},
    {"id": 71, "parent_id": 70, "name": "工资", "type": "income", "emoji": "💼", "sort_order": 1},
    {"id": 72, "parent_id": 70, "name": "奖金年终", "type": "income", "emoji": "🎁", "sort_order": 2},
    {"id": 73, "parent_id": 70, "name": "兼职接单", "type": "income", "emoji": "💻", "sort_order": 3},
    {"id": 74, "parent_id": 70, "name": "理财收益", "type": "income", "emoji": "📈", "sort_order": 4},
    {"id": 75, "parent_id": 70, "name": "红包收入", "type": "income", "emoji": "🧧", "sort_order": 5},
    {"id": 76, "parent_id": 70, "name": "退款报销", "type": "income", "emoji": "↩️", "sort_order": 6},
    {"id": 77, "parent_id": 70, "name": "二手出售", "type": "income", "emoji": "🔄", "sort_order": 7},
    {"id": 78, "parent_id": 70, "name": "房租收入", "type": "income", "emoji": "🏠", "sort_order": 8},
    {"id": 79, "parent_id": 70, "name": "其他收入", "type": "income", "emoji": "💌", "sort_order": 9},

    # === 存钱 ===
    {"id": 80, "parent_id": None, "name": "储蓄方式", "type": "savings", "emoji": "💰", "sort_order": 1},
    {"id": 81, "parent_id": 80, "name": "定期存款", "type": "savings", "emoji": "🏦", "sort_order": 1},
    {"id": 82, "parent_id": 80, "name": "活期储蓄", "type": "savings", "emoji": "💰", "sort_order": 2},
    {"id": 83, "parent_id": 80, "name": "基金定投", "type": "savings", "emoji": "📊", "sort_order": 3},
    {"id": 84, "parent_id": 80, "name": "股票投资", "type": "savings", "emoji": "📈", "sort_order": 4},
    {"id": 85, "parent_id": 80, "name": "目标储蓄", "type": "savings", "emoji": "🎯", "sort_order": 5},
    {"id": 86, "parent_id": 80, "name": "应急金", "type": "savings", "emoji": "🚨", "sort_order": 6},
    {"id": 87, "parent_id": 80, "name": "其他存钱", "type": "savings", "emoji": "💌", "sort_order": 7},
]


def seed_categories(db):
    """初始化系统预设分类。如果已存在则跳过。"""
    from app.models.category import Category

    if db.query(Category).count() > 0:
        return

    for item in SEED_CATEGORIES:
        db.add(Category(**item))
    db.commit()
