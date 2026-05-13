from pydantic import BaseModel


class BillImportRequest(BaseModel):
    content: str
    source: str  # "wechat" or "alipay"


class BillConfirmItem(BaseModel):
    date: str
    type: str
    amount: float
    parent_category: str | None = None
    child_category: str | None = None
    note: str | None = None
    source: str
