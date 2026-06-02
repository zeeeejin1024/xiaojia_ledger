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


# ===== 种子数据 v4.0 — 20 支出主类 + 10 收入 + 储蓄 =====
SEED_CATEGORIES: List[dict] = [
    # ================================================================
    # 支出（按使用频率排序: ★★★★★ → ★）
    # ================================================================

    # 1. 餐饮 ★★★★★
    {"id": 1, "parent_id": None, "name": "餐饮", "type": "expense", "emoji": "🍜", "sort_order": 1},
    {"id": 2, "parent_id": 1, "name": "早餐", "type": "expense", "emoji": "🥐", "sort_order": 1},
    {"id": 3, "parent_id": 1, "name": "午餐", "type": "expense", "emoji": "🍱", "sort_order": 2},
    {"id": 4, "parent_id": 1, "name": "晚餐", "type": "expense", "emoji": "🍛", "sort_order": 3},
    {"id": 5, "parent_id": 1, "name": "宵夜", "type": "expense", "emoji": "🌙", "sort_order": 4},
    {"id": 6, "parent_id": 1, "name": "零食", "type": "expense", "emoji": "🍿", "sort_order": 5},
    {"id": 7, "parent_id": 1, "name": "奶茶咖啡", "type": "expense", "emoji": "🧋", "sort_order": 6},
    {"id": 8, "parent_id": 1, "name": "水果", "type": "expense", "emoji": "🍎", "sort_order": 7},
    {"id": 9, "parent_id": 1, "name": "外卖", "type": "expense", "emoji": "🛵", "sort_order": 8},
    {"id": 10, "parent_id": 1, "name": "烘焙面包", "type": "expense", "emoji": "🍞", "sort_order": 9},

    # 2. 交通 ★★★★★
    {"id": 11, "parent_id": None, "name": "交通", "type": "expense", "emoji": "🚇", "sort_order": 2},
    {"id": 12, "parent_id": 11, "name": "地铁公交", "type": "expense", "emoji": "🚌", "sort_order": 1},
    {"id": 13, "parent_id": 11, "name": "打车", "type": "expense", "emoji": "🚕", "sort_order": 2},
    {"id": 14, "parent_id": 11, "name": "加油充电", "type": "expense", "emoji": "⛽", "sort_order": 3},
    {"id": 15, "parent_id": 11, "name": "停车", "type": "expense", "emoji": "🅿️", "sort_order": 4},
    {"id": 16, "parent_id": 11, "name": "高铁火车", "type": "expense", "emoji": "🚄", "sort_order": 5},
    {"id": 17, "parent_id": 11, "name": "飞机", "type": "expense", "emoji": "✈️", "sort_order": 6},
    {"id": 18, "parent_id": 11, "name": "共享单车", "type": "expense", "emoji": "🚲", "sort_order": 7},

    # 3. 购物 ★★★★★
    {"id": 19, "parent_id": None, "name": "购物", "type": "expense", "emoji": "🛒", "sort_order": 3},
    {"id": 20, "parent_id": 19, "name": "服饰鞋包", "type": "expense", "emoji": "👗", "sort_order": 1},
    {"id": 21, "parent_id": 19, "name": "化妆品护肤", "type": "expense", "emoji": "💄", "sort_order": 2},
    {"id": 22, "parent_id": 19, "name": "数码电器", "type": "expense", "emoji": "📱", "sort_order": 3},
    {"id": 23, "parent_id": 19, "name": "家居日用", "type": "expense", "emoji": "🪴", "sort_order": 4},
    {"id": 24, "parent_id": 19, "name": "超市便利", "type": "expense", "emoji": "🏪", "sort_order": 5},
    {"id": 25, "parent_id": 19, "name": "网购", "type": "expense", "emoji": "📦", "sort_order": 6},

    # 4. 居住 ★★★★
    {"id": 33, "parent_id": None, "name": "居住", "type": "expense", "emoji": "🏠", "sort_order": 4},
    {"id": 34, "parent_id": 33, "name": "房租月供", "type": "expense", "emoji": "🏠", "sort_order": 1},
    {"id": 35, "parent_id": 33, "name": "水电燃气", "type": "expense", "emoji": "💡", "sort_order": 2},
    {"id": 36, "parent_id": 33, "name": "物业费", "type": "expense", "emoji": "🏢", "sort_order": 3},
    {"id": 38, "parent_id": 33, "name": "维修家装", "type": "expense", "emoji": "🔧", "sort_order": 4},
    {"id": 39, "parent_id": 33, "name": "保洁清洁", "type": "expense", "emoji": "🧹", "sort_order": 5},

    # 5. 通讯 ★★★★
    {"id": 90, "parent_id": None, "name": "通讯", "type": "expense", "emoji": "📱", "sort_order": 5},
    {"id": 91, "parent_id": 90, "name": "手机话费", "type": "expense", "emoji": "📞", "sort_order": 1},
    {"id": 92, "parent_id": 90, "name": "宽带网络", "type": "expense", "emoji": "🌐", "sort_order": 2},
    {"id": 93, "parent_id": 90, "name": "APP会员", "type": "expense", "emoji": "🎫", "sort_order": 3},

    # 6. 娱乐 ★★★★
    {"id": 26, "parent_id": None, "name": "娱乐", "type": "expense", "emoji": "🎮", "sort_order": 6},
    {"id": 27, "parent_id": 26, "name": "电影演出", "type": "expense", "emoji": "🎬", "sort_order": 1},
    {"id": 28, "parent_id": 26, "name": "游戏氪金", "type": "expense", "emoji": "🎮", "sort_order": 2},
    {"id": 29, "parent_id": 26, "name": "KTV聚会", "type": "expense", "emoji": "🎤", "sort_order": 3},
    {"id": 31, "parent_id": 26, "name": "运动健身", "type": "expense", "emoji": "🏋️", "sort_order": 4},
    {"id": 32, "parent_id": 26, "name": "桌游密室", "type": "expense", "emoji": "🎯", "sort_order": 5},

    # 7. 学习 ★★★
    {"id": 40, "parent_id": None, "name": "学习", "type": "expense", "emoji": "📚", "sort_order": 7},
    {"id": 41, "parent_id": 40, "name": "课程培训", "type": "expense", "emoji": "🎓", "sort_order": 1},
    {"id": 42, "parent_id": 40, "name": "考试报名", "type": "expense", "emoji": "📝", "sort_order": 2},
    {"id": 43, "parent_id": 40, "name": "书籍资料", "type": "expense", "emoji": "📖", "sort_order": 3},
    {"id": 94, "parent_id": 40, "name": "文具打印", "type": "expense", "emoji": "🖨️", "sort_order": 4},

    # 8. 医疗 ★★★
    {"id": 44, "parent_id": None, "name": "医疗", "type": "expense", "emoji": "🏥", "sort_order": 8},
    {"id": 45, "parent_id": 44, "name": "门诊药费", "type": "expense", "emoji": "💊", "sort_order": 1},
    {"id": 47, "parent_id": 44, "name": "体检", "type": "expense", "emoji": "🩺", "sort_order": 2},
    {"id": 48, "parent_id": 44, "name": "牙科眼科", "type": "expense", "emoji": "🦷", "sort_order": 3},

    # 9. 人情 ★★★
    {"id": 49, "parent_id": None, "name": "人情", "type": "expense", "emoji": "🎁", "sort_order": 9},
    {"id": 50, "parent_id": 49, "name": "红包礼物", "type": "expense", "emoji": "🧧", "sort_order": 1},
    {"id": 51, "parent_id": 49, "name": "婚礼份子", "type": "expense", "emoji": "💒", "sort_order": 2},
    {"id": 52, "parent_id": 49, "name": "聚餐AA", "type": "expense", "emoji": "🍽️", "sort_order": 3},

    # 10. 宠物 ★★★
    {"id": 53, "parent_id": None, "name": "宠物", "type": "expense", "emoji": "🐱", "sort_order": 10},
    {"id": 54, "parent_id": 53, "name": "宠物粮食", "type": "expense", "emoji": "🦴", "sort_order": 1},
    {"id": 55, "parent_id": 53, "name": "宠物医疗", "type": "expense", "emoji": "💉", "sort_order": 2},
    {"id": 56, "parent_id": 53, "name": "宠物用品", "type": "expense", "emoji": "🐾", "sort_order": 3},

    # 11. 美容 ★★★
    {"id": 95, "parent_id": None, "name": "美容", "type": "expense", "emoji": "💄", "sort_order": 11},
    {"id": 96, "parent_id": 95, "name": "理发造型", "type": "expense", "emoji": "💇", "sort_order": 1},
    {"id": 97, "parent_id": 95, "name": "按摩SPA", "type": "expense", "emoji": "💆", "sort_order": 2},
    {"id": 98, "parent_id": 95, "name": "护肤美甲", "type": "expense", "emoji": "💅", "sort_order": 3},

    # 12. 旅行 ★★
    {"id": 99, "parent_id": None, "name": "旅行", "type": "expense", "emoji": "✈️", "sort_order": 12},
    {"id": 100, "parent_id": 99, "name": "机票酒店", "type": "expense", "emoji": "🏨", "sort_order": 1},
    {"id": 101, "parent_id": 99, "name": "景点门票", "type": "expense", "emoji": "🎫", "sort_order": 2},
    {"id": 102, "parent_id": 99, "name": "纪念品", "type": "expense", "emoji": "🎀", "sort_order": 3},

    # 13. 烟酒 ★★
    {"id": 103, "parent_id": None, "name": "烟酒", "type": "expense", "emoji": "🍺", "sort_order": 13},
    {"id": 104, "parent_id": 103, "name": "烟草", "type": "expense", "emoji": "🚬", "sort_order": 1},
    {"id": 105, "parent_id": 103, "name": "酒水", "type": "expense", "emoji": "🍷", "sort_order": 2},

    # 14. 保险 ★★
    {"id": 106, "parent_id": None, "name": "保险", "type": "expense", "emoji": "🛡️", "sort_order": 14},
    {"id": 107, "parent_id": 106, "name": "社会保险", "type": "expense", "emoji": "📋", "sort_order": 1},
    {"id": 108, "parent_id": 106, "name": "商业保险", "type": "expense", "emoji": "📄", "sort_order": 2},
    {"id": 109, "parent_id": 106, "name": "车险", "type": "expense", "emoji": "🚗", "sort_order": 3},

    # 15. 理财 ★★
    {"id": 110, "parent_id": None, "name": "理财", "type": "expense", "emoji": "💰", "sort_order": 15},
    {"id": 111, "parent_id": 110, "name": "基金股票", "type": "expense", "emoji": "📈", "sort_order": 1},
    {"id": 112, "parent_id": 110, "name": "定期储蓄", "type": "expense", "emoji": "🏦", "sort_order": 2},

    # 16. 育儿 ★
    {"id": 113, "parent_id": None, "name": "育儿", "type": "expense", "emoji": "👶", "sort_order": 16},
    {"id": 114, "parent_id": 113, "name": "奶粉尿布", "type": "expense", "emoji": "🍼", "sort_order": 1},
    {"id": 115, "parent_id": 113, "name": "玩具", "type": "expense", "emoji": "🧸", "sort_order": 2},
    {"id": 116, "parent_id": 113, "name": "教育", "type": "expense", "emoji": "📚", "sort_order": 3},

    # 17. 养车 ★
    {"id": 117, "parent_id": None, "name": "养车", "type": "expense", "emoji": "🚗", "sort_order": 17},
    {"id": 118, "parent_id": 117, "name": "保养维修", "type": "expense", "emoji": "🔧", "sort_order": 1},
    {"id": 119, "parent_id": 117, "name": "洗车", "type": "expense", "emoji": "🧽", "sort_order": 2},

    # 18. 快递 ★
    {"id": 120, "parent_id": None, "name": "快递", "type": "expense", "emoji": "📦", "sort_order": 18},
    {"id": 121, "parent_id": 120, "name": "快递物流", "type": "expense", "emoji": "🚚", "sort_order": 1},
    {"id": 122, "parent_id": 120, "name": "跑腿", "type": "expense", "emoji": "🏃", "sort_order": 2},

    # 19. 捐赠 ★
    {"id": 123, "parent_id": None, "name": "捐赠", "type": "expense", "emoji": "💌", "sort_order": 19},
    {"id": 124, "parent_id": 123, "name": "公益捐款", "type": "expense", "emoji": "🤝", "sort_order": 1},

    # 20. 其他支出
    {"id": 62, "parent_id": None, "name": "其他支出", "type": "expense", "emoji": "📌", "sort_order": 20},

    # ================================================================
    # 收入（按使用频率排序: ★★★★★ → ★）
    # ================================================================
    {"id": 70, "parent_id": None, "name": "收入来源", "type": "income", "emoji": "💰", "sort_order": 1},
    {"id": 71, "parent_id": 70, "name": "工资薪水", "type": "income", "emoji": "💼", "sort_order": 1},
    {"id": 72, "parent_id": 70, "name": "奖金年终", "type": "income", "emoji": "🎉", "sort_order": 2},
    {"id": 73, "parent_id": 70, "name": "兼职接单", "type": "income", "emoji": "💻", "sort_order": 3},
    {"id": 74, "parent_id": 70, "name": "理财收益", "type": "income", "emoji": "📈", "sort_order": 4},
    {"id": 75, "parent_id": 70, "name": "红包收入", "type": "income", "emoji": "🧧", "sort_order": 5},
    {"id": 76, "parent_id": 70, "name": "退款报销", "type": "income", "emoji": "↩️", "sort_order": 6},
    {"id": 77, "parent_id": 70, "name": "二手出售", "type": "income", "emoji": "🔄", "sort_order": 7},
    {"id": 78, "parent_id": 70, "name": "房租收入", "type": "income", "emoji": "🏠", "sort_order": 8},
    {"id": 125, "parent_id": 70, "name": "他人转账", "type": "income", "emoji": "💳", "sort_order": 9},
    {"id": 79, "parent_id": 70, "name": "其他收入", "type": "income", "emoji": "📌", "sort_order": 10},

    # ================================================================
    # 存钱
    # ================================================================
    {"id": 80, "parent_id": None, "name": "储蓄方式", "type": "savings", "emoji": "💰", "sort_order": 1},
    {"id": 81, "parent_id": 80, "name": "定期存款", "type": "savings", "emoji": "🏦", "sort_order": 1},
    {"id": 82, "parent_id": 80, "name": "活期储蓄", "type": "savings", "emoji": "💰", "sort_order": 2},
    {"id": 83, "parent_id": 80, "name": "基金定投", "type": "savings", "emoji": "📊", "sort_order": 3},
    {"id": 84, "parent_id": 80, "name": "股票投资", "type": "savings", "emoji": "📈", "sort_order": 4},
    {"id": 85, "parent_id": 80, "name": "目标储蓄", "type": "savings", "emoji": "🎯", "sort_order": 5},
    {"id": 86, "parent_id": 80, "name": "应急金", "type": "savings", "emoji": "🚨", "sort_order": 6},
    {"id": 87, "parent_id": 80, "name": "其他存钱", "type": "savings", "emoji": "📌", "sort_order": 7},
]


def seed_categories(db):
    """初始化系统预设分类。如果已存在则跳过。"""
    from app.models.category import Category

    if db.query(Category).count() > 0:
        return

    for item in SEED_CATEGORIES:
        db.add(Category(**item))
    db.commit()
