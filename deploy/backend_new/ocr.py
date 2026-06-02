from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.services.ai_parser import parse_text
import base64
import json

router = APIRouter(prefix="/ai", tags=["AI-OCR"])


class OcrRequest(BaseModel):
    image_base64: str


class OcrResult(BaseModel):
    amount: float | None = None
    merchant: str | None = None
    category: str | None = None
    time: str | None = None
    type: str = "expense"
    confidence: float = 0.0


@router.post("/ocr", response_model=dict)
def ocr_single(req: OcrRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """单张截图 OCR 识别"""
    try:
        img_data = base64.b64decode(req.image_base64)
    except Exception:
        return {"code": 1, "message": "图片数据无效"}

    # 尝试调用百度 OCR（如果配置了），否则用占位逻辑
    text = _mock_ocr(img_data)

    if not text.strip():
        return {"code": 1, "message": "未识别到文字"}

    parsed = parse_text(text)
    return {"code": 0, "data": parsed}


@router.post("/ocr/batch", response_model=dict)
def ocr_batch(req_list: List[OcrRequest], user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """批量截图 OCR 识别"""
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
    """
    模拟 OCR —— 正式环境替换为真实 OCR 调用。
    当前返回空字符串，提示接入真实 OCR。
    """
    # TODO: 接入百度OCR / PaddleOCR
    # import requests
    # resp = requests.post(BAIDU_OCR_URL, data=img_data, headers=...)
    # return resp.json()["words_result"]
    return ""
