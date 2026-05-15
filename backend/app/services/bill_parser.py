from typing import Dict, List, Optional, Tuple
"""微信/支付宝账单CSV解析 + 智能分类匹配"""

import re
import csv
import io
from datetime import datetime

# ===== 商户名 → 分类映射规则 =====
MERCHANT_RULES: Dict[str, Tuple[str, str]] = {
    # 餐饮
    "美团": ("餐饮", "外卖"),
    "饿了么": ("餐饮", "外卖"),
    "星巴克": ("餐饮", "奶茶咖啡"),
    "瑞幸": ("餐饮", "奶茶咖啡"),
    "蜜雪冰城": ("餐饮", "奶茶咖啡"),
    "喜茶": ("餐饮", "奶茶咖啡"),
    "奈雪": ("餐饮", "奶茶咖啡"),
    "麦当劳": ("餐饮", "午餐"),
    "肯德基": ("餐饮", "午餐"),
    "汉堡王": ("餐饮", "午餐"),
    "海底捞": ("餐饮", "晚餐"),
    "西贝": ("餐饮", "晚餐"),
    "必胜客": ("餐饮", "午餐"),
    "一点点": ("餐饮", "奶茶咖啡"),
    "茶百道": ("餐饮", "奶茶咖啡"),
    "古茗": ("餐饮", "奶茶咖啡"),
    "coco": ("餐饮", "奶茶咖啡"),
    "CoCo": ("餐饮", "奶茶咖啡"),
    # 交通
    "滴滴": ("交通", "打车"),
    "T3出行": ("交通", "打车"),
    "曹操出行": ("交通", "打车"),
    "哈啰": ("交通", "共享单车"),
    "青桔": ("交通", "共享单车"),
    "美团单车": ("交通", "共享单车"),
    "12306": ("交通", "高铁火车"),
    "中国铁路": ("交通", "高铁火车"),
    "航旅纵横": ("交通", "飞机"),
    "中石油": ("交通", "加油"),
    "中石化": ("交通", "加油"),
    # 购物
    "淘宝": ("购物", "衣服鞋帽"),
    "天猫": ("购物", "衣服鞋帽"),
    "京东": ("购物", "电子产品"),
    "拼多多": ("购物", "超市杂货"),
    "唯品会": ("购物", "衣服鞋帽"),
    "得物": ("购物", "衣服鞋帽"),
    "闲鱼": ("购物", "家居日用"),
    "当当": ("购物", "书籍文具"),
    "网易严选": ("购物", "家居日用"),
    # 娱乐
    "猫眼": ("娱乐", "电影演出"),
    "淘票票": ("娱乐", "电影演出"),
    "bilibili": ("娱乐", "游戏氪金"),
    "B站": ("娱乐", "游戏氪金"),
    "哔哩哔哩": ("娱乐", "游戏氪金"),
    "steam": ("娱乐", "游戏氪金"),
    "Steam": ("娱乐", "游戏氪金"),
    "王者荣耀": ("娱乐", "游戏氪金"),
    "原神": ("娱乐", "游戏氪金"),
    "携程": ("娱乐", "旅行旅游"),
    "去哪儿": ("娱乐", "旅行旅游"),
    "飞猪": ("娱乐", "旅行旅游"),
    # 居住
    "国家电网": ("居住", "水电燃气"),
    "中国移动": ("居住", "网费话费"),
    "中国联通": ("居住", "网费话费"),
    "中国电信": ("居住", "网费话费"),
    "自如": ("居住", "房租"),
    "贝壳": ("居住", "房租"),
    "链家": ("居住", "房租"),
    "顺丰": ("生活服务", "快递物流"),
    "中通": ("生活服务", "快递物流"),
    "圆通": ("生活服务", "快递物流"),
    "韵达": ("生活服务", "快递物流"),
    "EMS": ("生活服务", "快递物流"),
    "爱奇艺": ("生活服务", "会员订阅"),
    "腾讯视频": ("生活服务", "会员订阅"),
    "优酷": ("生活服务", "会员订阅"),
    "网易云音乐": ("生活服务", "会员订阅"),
    "QQ音乐": ("生活服务", "会员订阅"),
    "Apple": ("生活服务", "会员订阅"),
    "微信红包": ("人情", "送礼红包"),
    # 收入
    "工资": ("收入来源", "工资"),
    "奖金": ("收入来源", "奖金年终"),
    "公积金": ("收入来源", "其他收入"),
    "理财": ("收入来源", "理财收益"),
    "余额宝": ("收入来源", "理财收益"),
}


def match_merchant(merchant: str) -> Tuple[Optional[str], Optional[str]]:
    """根据商户名匹配一级分类和二级分类。"""
    for keyword, (parent, child) in MERCHANT_RULES.items():
        if keyword.lower() in merchant.lower():
            return parent, child
    return None, None


def parse_csv(content: str, source: str) -> List[dict]:
    """解析微信/支付宝导出的 CSV 账单。

    返回: [{"date": "2026-05-11", "type": "expense",
             "amount": 22.5, "merchant": "美团-黄焖鸡",
             "category": "外卖", "note": "..."}, ...]
    """
    try:
        content_stripped = content.strip()
        if not content_stripped:
            return []

        reader = csv.DictReader(io.StringIO(content_stripped))
        rows = list(reader)
        if not rows:
            return []

        headers = [h.strip() for h in rows[0].keys()]

        # 微信账单格式
        if "交易时间" in headers or "交易对方" in headers:
            return _parse_wechat(rows, source)
        # 支付宝账单格式
        if "交易时间" in headers or "交易对方" in headers or "收入金额" in headers:
            return _parse_alipay(rows, source)
        # 尝试微信格式
        if "交易类型" in headers:
            return _parse_wechat(rows, source)

        # 通用解析
        return _parse_generic(rows, source)
    except Exception:
        return []


def _parse_wechat(rows: List[dict], source: str) -> List[dict]:
    """解析微信账单 CSV"""
    results = []
    for row in rows:
        time_str = row.get("交易时间", "") or row.get("交易时间 ", "")
        merchant = row.get("交易对方", "") or row.get("交易对方 ", "")
        product = row.get("商品", "") or row.get("商品 ", "")
        amount_str = row.get("金额(元)", "") or row.get("金额（元）", "")
        tx_type = row.get("收/支", "") or row.get("收/支 ", "")

        if not time_str or not amount_str:
            continue

        try:
            date = time_str.strip()[:10]
            amount = abs(float(amount_str.replace(",", "")))
            tx_type_clean = tx_type.strip()
            rectype = "income" if ("收入" in tx_type_clean or amount_str.strip().startswith("+")) else "expense"

            parent, child = match_merchant(merchant)
            note = f"{merchant} {product}".strip()

            results.append({
                "date": date, "type": rectype, "amount": amount,
                "merchant": merchant, "product": product,
                "parent_category": parent, "child_category": child,
                "note": note[:200], "source": source,
            })
        except (ValueError, IndexError):
            continue

    return results


def _parse_alipay(rows: List[dict], source: str) -> List[dict]:
    """解析支付宝账单 CSV"""
    results = []
    for row in rows:
        time_str = row.get("交易时间", "")
        merchant = row.get("交易对方", "")
        product = row.get("商品说明", "") or row.get("商品", "")
        amount_str = row.get("金额", "")
        tx_type = row.get("收/支", "")

        if not time_str or not amount_str:
            continue

        try:
            date = time_str.strip()[:10]
            amount = abs(float(amount_str.replace(",", "")))
            rectype = "income" if "收入" in tx_type else "expense"

            parent, child = match_merchant(merchant)
            note = f"{merchant} {product}".strip()

            results.append({
                "date": date, "type": rectype, "amount": amount,
                "merchant": merchant, "product": product,
                "parent_category": parent, "child_category": child,
                "note": note[:200], "source": source,
            })
        except (ValueError, IndexError):
            continue

    return results


def _parse_generic(rows: List[dict], source: str) -> List[dict]:
    """通用账单解析"""
    results = []
    for row in rows:
        date = None
        amount = None
        merchant = ""
        for key, val in row.items():
            kl = key.lower()
            v = str(val).strip()
            if "时间" in kl or "date" in kl:
                if v:
                    try:
                        date = v[:10]
                    except Exception:
                        date = v
            if "金额" in kl or "amount" in kl or "钱" in kl:
                try:
                    amount = abs(float(v.replace(",", "").replace("¥", "")))
                except ValueError:
                    pass
            if "商户" in kl or "merchant" in kl or "对方" in kl or "备注" in kl:
                merchant = v

        if date and amount and amount > 0:
            results.append({
                "date": date, "type": "expense", "amount": amount,
                "merchant": merchant, "product": "",
                "parent_category": None, "child_category": None,
                "note": merchant[:200], "source": source,
            })

    return results
