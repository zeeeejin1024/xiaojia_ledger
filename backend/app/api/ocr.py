from typing import Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.category import Category
from app.services.llm_parser import parse_receipt
import base64

router = APIRouter(prefix="/ai", tags=["AI-OCR"])


class OcrRequest(BaseModel):
    image_base64: str


def _resolve_category_id(db: Session, category_name: Optional[str]) -> Optional[int]:
    if not category_name: return None
    cat = db.query(Category).filter(Category.name == category_name, Category.parent_id.isnot(None)).first()
    if cat: return cat.id
    cats = db.query(Category).filter(Category.parent_id.isnot(None)).all()
    for c in cats:
        if c.name and category_name in c.name: return c.id
    return None


@router.post("/ocr", response_model=dict)
def ocr_single(req: OcrRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        base64.b64decode(req.image_base64)
    except Exception:
        return {"code": 1, "message": "图片数据无效"}

    # 通义千问 VL 直接识别截图
    items = parse_receipt(req.image_base64, db)

    if not items:
        return {"code": 1, "message": "未能识别消费信息，请尝试手动输入"}

    for item in items:
        item["category_id"] = _resolve_category_id(db, item.get("category"))

    return {"code": 0, "data": items}
