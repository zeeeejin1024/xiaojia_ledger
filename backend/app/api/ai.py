from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.common import success
from app.services.ai_parser import parse_text

router = APIRouter(prefix="/ai", tags=["AI"])


class VoiceRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=500, description="语音识别后的文字，或用户手打的自然语言")


@router.post("/parse")
def parse_voice(data: VoiceRequest, user: User = Depends(get_current_user)):
    """AI 语义解析：从自然语言中提取类型、金额、分类。"""
    result = parse_text(data.text)
    return success(data=result)
