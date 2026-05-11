from typing import Any
from pydantic import BaseModel


class ApiResponse(BaseModel):
    code: int = 0
    message: str = "ok"
    data: Any = None


def success(data: Any = None, message: str = "ok") -> ApiResponse:
    return ApiResponse(code=0, message=message, data=data)


def error(code: int, message: str) -> ApiResponse:
    return ApiResponse(code=code, message=message, data=None)
