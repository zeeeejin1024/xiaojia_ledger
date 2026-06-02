import base64
from fastapi import APIRouter, Depends, UploadFile, File
from pydantic import BaseModel, Field

from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.common import success, error
from app.services.ai_parser import parse_text
from app.services.xunfei_service import recognize

router = APIRouter(prefix="/ai", tags=["AI"])


class VoiceRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=500)


@router.post("/parse")
def parse_voice(data: VoiceRequest, user: User = Depends(get_current_user)):
    """AI 语义解析：从自然语言中提取类型、金额、分类。"""
    result = parse_text(data.text)
    return success(data=result)


@router.post("/voice")
async def voice_recognize(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    """语音识别：上传音频文件，返回识别文字 + AI 解析结果。"""
    try:
        audio_bytes = await file.read()
        audio_b64 = base64.b64encode(audio_bytes).decode()

        # 确保音频格式正确：单声道 16kHz 16bit PCM
        text = recognize(audio_b64)

        if not text:
            return error(400, "未识别到语音内容，请重试")

        parsed = parse_text(text)
        return success(data={"text": text, "parsed": parsed})
    except Exception as e:
        return error(500, f"语音识别失败: {str(e)}")
