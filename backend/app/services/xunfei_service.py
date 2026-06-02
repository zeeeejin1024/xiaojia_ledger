"""讯飞语音听写 REST API"""
import hashlib
import hmac
import base64
import json
import os
import time
from urllib.parse import urlencode
import httpx

XUNFEI_APP_ID = os.environ.get("XUNFEI_APPID", "")
XUNFEI_API_KEY = os.environ.get("XUNFEI_API_KEY", "")
XUNFEI_API_SECRET = os.environ.get("XUNFEI_API_SECRET", "")
XUNFEI_HOST = "iat-api.xfyun.cn"
XUNFEI_URL = f"https://{XUNFEI_HOST}/v2/iat"
XUNFEI_URI = "/v2/iat"


def _build_auth_url() -> str:
    """构建带鉴权签名的 WebSocket URL"""
    date = time.strftime("%a, %d %b %Y %H:%M:%S GMT", time.gmtime())
    tmp = f"host: {XUNFEI_HOST}\ndate: {date}\nGET {XUNFEI_URI} HTTP/1.1"
    signature = base64.b64encode(
        hmac.new(
            XUNFEI_API_SECRET.encode(),
            tmp.encode(),
            hashlib.sha256,
        ).digest()
    ).decode()
    authorization = (
        f'api_key="{XUNFEI_API_KEY}", algorithm="hmac-sha256", '
        f'headers="host date request-line", signature="{signature}"'
    )
    params = {
        "host": XUNFEI_HOST,
        "date": date,
        "authorization": base64.b64encode(authorization.encode()).decode(),
    }
    return f"{XUNFEI_URL}?{urlencode(params)}"


def recognize(audio_base64: str, audio_format: str = "audio/L16;rate=16000") -> str:
    """调用讯飞语音听写，返回识别文字"""
    import websocket

    result_text = ""

    def on_open(ws):
        # 发送开始帧
        frame = json.dumps({
            "common": {"app_id": XUNFEI_APP_ID},
            "business": {
                "language": "zh_cn",
                "domain": "iat",
                "accent": "mandarin",
                "vad_eos": 10000,  # 10秒静音自动结束
            },
            "data": {
                "status": 0,
                "format": audio_format,
                "encoding": "raw",
                "audio": audio_base64,
            },
        })
        ws.send(frame)

    def on_message(ws, message):
        nonlocal result_text
        try:
            msg = json.loads(message)
            if msg.get("code") != 0:
                return
            data = msg.get("data", {})
            if data.get("status") == 2:  # 最后一帧
                ws.close()
            result = data.get("result", {})
            if result:
                text = "".join(
                    w.get("cw", [{}])[0].get("w", "")
                    for w in result.get("ws", [])
                )
                result_text += text
        except Exception:
            pass

    def on_error(ws, error):
        pass

    def on_close(ws, close_status_code, close_msg):
        pass

    ws_url = _build_auth_url()
    ws = websocket.WebSocketApp(
        ws_url,
        on_open=on_open,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close,
    )
    ws.run_forever()
    return result_text
