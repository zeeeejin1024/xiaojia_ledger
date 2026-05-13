"""AI 语义解析引擎 — 从用户语音/文字中提取记账信息"""

import re

# 金额模式：匹配口语金额表达
_AMOUNT_PATTERNS = [
    (r"(\d+)块(\d)毛?", lambda m: float(m[0]) + float(m[1]) / 10),
    (r"(\d+)块(\d)?", lambda m: float(m[0]) + float(m[1]) / 10 if len(m) > 1 and m[1] else float(m[0])),
    (r"(\d+)块\s*半", lambda m: float(m[0]) + 0.5),
    (r"(\d+\.?\d*)元?", lambda m: float(m[0])),
    (r"¥\s*(\d+\.?\d*)", lambda m: float(m[0])),
]

# 类型判断关键词
_TYPE_KEYWORDS = {
    "income": ["发工资", "到账", "赚钱", "收入", "领钱", "报销", "退款", "卖了", "收红包", "奖金", "兼职", "稿费"],
    "savings": ["存了", "存入", "攒了", "储蓄", "定期", "基金买入", "定投"],
    "expense": ["花了", "买", "买了", "吃", "吃了", "喝", "喝了", "打车", "坐车", "付", "给了", "交", "交了", "扣", "扣了",
                "缴费", "转账", "支付", "消费", "用掉", "花了钱", "用钱"],
}

# 分类关键词匹配
_CATEGORY_KEYWORDS = {
    "早餐": ["早饭", "早晨", "早餐", "包子", "豆浆", "油条", "煎饼", "豆腐脑", "粥", "馒头"],
    "午餐": ["午饭", "中午", "午餐", "盒饭", "拉面", "盖饭", "黄焖鸡", "麻辣烫", "米线", "面"],
    "晚餐": ["晚饭", "晚上", "晚餐", "聚餐", "涮肉", "火锅", "串串", "烤肉", "大餐"],
    "宵夜": ["宵夜", "夜宵", "半夜", "烧烤", "深夜"],
    "零食": ["零食", "薯片", "辣条", "饼干", "巧克力", "坚果"],
    "奶茶咖啡": ["奶茶", "咖啡", "奶盖", "可可", "星巴克", "瑞幸", "喜茶", "奈雪", "茶百道", "古茗",
                  "蜜雪冰城", "拿铁", "美式", "抹茶", "柠檬茶", "喝奶茶", "喝杯", "饮料"],
    "外卖": ["外卖"],
    "地铁公交": ["地铁", "公交", "坐车", "乘车", "通勤卡"],
    "打车": ["打车", "滴滴", "出租车", "叫车"],
    "电影演出": ["电影", "电影院", "演出", "话剧", "演唱会"],
    "游戏氪金": ["游戏", "氪金", "抽卡", "皮肤", "王者", "原神", "崩坏", "b站", "steam"],
    "旅行旅游": ["旅游", "旅行", "出游", "机票", "酒店", "民宿", "景区", "门票"],
    "运动健身": ["健身", "运动", "跑步", "游泳", "羽毛球", "篮球", "瑜伽", "跳舞", "Keep"],
    "衣服鞋帽": ["衣服", "鞋", "裤子", "裙子", "帽子", "T恤", "袜子", "内衣", "外套", "羽绒服"],
    "电子产品": ["手机", "电脑", "耳机", "平板", "手表", "充电", "数据线", "键盘", "鼠标"],
    "房租": ["房租", "租金", "租房子"],
    "水电燃气": ["电费", "水费", "燃气", "煤气"],
    "医疗": ["看病", "挂号", "药", "诊所", "医院", "体检", "牙医", "拔牙"],
    "快递物流": ["快递", "寄送", "运费", "邮政"],
    "会员订阅": ["会员", "订阅", "充值会员"],
    "理发造型": ["理发", "剪发", "做头发", "美发", "染发"],
    "工资": ["工资", "月薪", "发薪"],
    "奖金年终": ["奖金", "年终", "分红"],
    "兼职接单": ["兼职", "散活", "接单", "外包", "公众号", "写稿", "设计费"],
    "理财收益": ["理财", "利息", "收益", "基金", "股票涨", "分红", "余额宝"],
    "红包收入": ["红包", "压岁钱", "抢红包", "生日红包"],
    "二手出售": ["卖掉", "转转", "卖了", "二手"],
}

# 预编译（性能）
_CAT_COMPILED = {cat: re.compile("|".join(map(re.escape, kws))) for cat, kws in _CATEGORY_KEYWORDS.items()}


def parse_text(text: str) -> dict:
    """从中文自然语言中提取记账信息。

    返回: {type, amount, category, note, confidence}
    """
    text = text.strip()
    if not text:
        return {"type": None, "amount": 0, "category": None, "note": None, "confidence": 0}

    # 1. 提取金额
    amount = 0.0
    for pattern, extractor in _AMOUNT_PATTERNS:
        match = re.search(pattern, text)
        if match:
            amount = extractor(match.groups())
            break

    # 2. 判断类型
    rectype = "expense"  # 默认支出
    type_score = 0
    for t, keywords in _TYPE_KEYWORDS.items():
        for kw in keywords:
            if kw in text:
                if t == "income":
                    rectype = "income"
                    type_score = 10
                elif t == "savings" and rectype != "income":
                    rectype = "savings"
                    type_score = 8

    # 3. 匹配分类
    category = None
    best_score = 0
    for cat, regex in _CAT_COMPILED.items():
        matches = regex.findall(text)
        if len(matches) > best_score:
            best_score = len(matches)
            category = cat

    # 4. 备注 = 原文（精简）
    note = text[:200]

    # 5. 计算置信度
    confidence = 0.3  # 基线
    if amount > 0:
        confidence += 0.4
    if category:
        confidence += 0.2
    if type_score > 0:
        confidence += type_score / 50

    return {
        "type": rectype,
        "amount": round(amount, 2),
        "category": category,
        "note": note,
        "confidence": min(round(confidence, 2), 1.0),
    }
