from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.sync import BillImportRequest, BillConfirmItem
from app.schemas.common import success, error
from app.services import bill_parser

router = APIRouter(prefix="/sync", tags=["账单同步"])


@router.post("/parse")
def parse_bill(data: BillImportRequest, user: User = Depends(get_current_user)):
    """解析上传的 CSV 内容，返回预览列表（不写入数据库）。"""
    items = bill_parser.parse_csv(data.content, data.source)
    if not items:
        return error(400, "无法解析账单，请确认 CSV 格式正确")

    return success(data={"items": items, "total": len(items)})
