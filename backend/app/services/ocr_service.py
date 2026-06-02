"""PaddleOCR 在线免费服务"""
import base64, json, logging
import httpx

logger = logging.getLogger("ocr_service")

# OCR.Space 免费 API（每天 500 次，无需注册）
OCR_URL = "https://api.ocr.space/parse/image"


def _compress_image(image_base64: str) -> str:
    try:
        raw = base64.b64decode(image_base64)
        if len(raw) < 500 * 1024:
            return image_base64
        from io import BytesIO
        from PIL import Image
        img = Image.open(BytesIO(raw))
        if img.width > 1024:
            img = img.resize((1024, int(img.height * 1024 / img.width)), Image.LANCZOS)
        buf = BytesIO()
        img.convert("RGB").save(buf, format="JPEG", quality=70)
        return base64.b64encode(buf.getvalue()).decode()
    except Exception:
        return image_base64


def recognize(image_base64: str) -> tuple:
    """返回 (text, error_msg)"""
    image_base64 = _compress_image(image_base64)

    try:
        resp = httpx.post(
            OCR_URL,
            data={
                "base64Image": f"data:image/jpeg;base64,{image_base64}",
                "language": "chs",
                "isOverlayRequired": "false",
                "OCREngine": "2",
            },
            timeout=30.0,
        )
        result = resp.json()
        logger.info(f"OCR.Space response code={resp.status_code}")

        if result.get("IsErroredOnProcessing", True):
            return "", result.get("ErrorMessage", "OCR error")[0] if isinstance(result.get("ErrorMessage"), list) else result.get("ErrorMessage", "OCR error")

        parsed = result.get("ParsedResults", [])
        if not parsed:
            return "", "no text detected"

        text = parsed[0].get("ParsedText", "")
        return (text.strip(), None) if text.strip() else ("", "no text detected")
    except Exception as e:
        logger.error(f"OCR exception: {e}")
        return "", str(e)[:100]
