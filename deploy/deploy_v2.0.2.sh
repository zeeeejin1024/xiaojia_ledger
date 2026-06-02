#!/bin/bash
# 小满记账 v2.0.2 — 接入讯飞 OCR
# 在宝塔终端中粘贴执行

set -e
cd /www/wwwroot/backend

echo "=== 小满记账 v2.0.2 部署 ==="

# 1. 新建 OCR 服务
echo "创建 OCR 服务..."
cat > app/services/ocr_service.py << 'EOF'
"""讯飞通用文字识别 REST API"""
import hashlib
import hmac
import base64
import json
import time
import httpx

XUNFEI_APP_ID = "bf1acb41"
XUNFEI_API_KEY = "YmI3YzYyOWUzM2Y3YmQ4M2MxNzIwZTRj"
XUNFEI_API_SECRET = "cfc5bb167982ab820c0a49903f5cd7c0"
OCR_URL = "https://api.xfyun.cn/v1/service/v1/ocr/general"


def _build_headers() -> dict:
    cur_time = str(int(time.time()))
    param = json.dumps({"engine_type": "general"})
    param_base64 = base64.b64encode(param.encode()).decode()
    raw = f"{XUNFEI_API_KEY}{cur_time}{param_base64}"
    checksum = hashlib.md5(raw.encode()).hexdigest()
    signature = base64.b64encode(
        hmac.new(XUNFEI_API_SECRET.encode(), checksum.encode(), hashlib.sha256).digest()
    ).decode()
    return {
        "X-Appid": XUNFEI_APP_ID,
        "X-CurTime": cur_time,
        "X-Param": param_base64,
        "X-CheckSum": checksum,
        "X-Signature": signature,
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
    }


def recognize(image_base64: str) -> str:
    headers = _build_headers()
    body = {"image": image_base64}
    try:
        resp = httpx.post(OCR_URL, headers=headers, data=body, timeout=10.0)
        result = resp.json()
        if result.get("code") != 0:
            return ""
        blocks = result.get("data", {}).get("block", [])
        words = []
        for block in blocks:
            for line in block.get("line", []):
                for word in line.get("word", []):
                    content = word.get("content", "")
                    if content:
                        words.append(content)
        return " ".join(words)
    except Exception:
        return ""
EOF

# 2. 更新 OCR API
echo "更新 OCR API..."
cat > app/api/ocr.py << 'EOF'
from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.services.ai_parser import parse_text
from app.services.ocr_service import recognize as ocr_recognize
import base64

router = APIRouter(prefix="/ai", tags=["AI-OCR"])

class OcrRequest(BaseModel):
    image_base64: str

@router.post("/ocr", response_model=dict)
def ocr_single(req: OcrRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        base64.b64decode(req.image_base64)
    except Exception:
        return {"code": 1, "message": "图片数据无效"}
    text = ocr_recognize(req.image_base64)
    if not text or not text.strip():
        return {"code": 1, "message": "未识别到文字，请确认截图包含消费信息"}
    parsed = parse_text(text)
    return {"code": 0, "data": parsed}

@router.post("/ocr/batch", response_model=dict)
def ocr_batch(req_list: List[OcrRequest], user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    results = []
    for req in req_list:
        try:
            base64.b64decode(req.image_base64)
            text = ocr_recognize(req.image_base64)
            parsed = parse_text(text) if text and text.strip() else {"amount": None, "category": None}
            results.append({"success": True, "data": parsed})
        except Exception:
            results.append({"success": False, "data": None})
    return {"code": 0, "data": {"items": results}}
EOF

# 3. 安装依赖
echo "安装 httpx（如未安装）..."
pip3 install httpx -q 2>/dev/null || pip install httpx -q

# 4. 重启服务
echo "重启服务..."
systemctl restart xiaojia
sleep 3
systemctl status xiaojia --no-pager -l

echo ""
echo "=== v2.0.2 部署完成 ==="
echo "测试 OCR: curl -X POST http://114.55.138.55/api/v1/ai/ocr -H 'Content-Type: application/json' -d '{\"image_base64\":\"\"}'"
