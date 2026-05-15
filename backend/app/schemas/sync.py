from typing import Optional
from pydantic import BaseModel


class BillImportRequest(BaseModel):
    content: str
    source: str  # "wechat" or "alipay"


class BillConfirmItem(BaseModel):
    date: str
    type: str
    amount: float
    parent_category: Optional[str] = None
    child_category: Optional[str] = None
    note: Optional[str] = None
    source: str
