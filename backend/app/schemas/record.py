from typing import Optional, Union
from datetime import date
from pydantic import BaseModel, Field
from app.models.category import RecordType


class RecordCreate(BaseModel):
    type: RecordType
    amount: float = Field(gt=0)
    category_id: int
    date: str
    note: Optional[str] = None


class RecordUpdate(BaseModel):
    field: str
    value: Union[str, float, None] = None


class RecordOut(BaseModel):
    id: int
    type: str
    amount: float
    category_id: int
    category_name: str = ""
    category_emoji: Optional[str] = None
    date: str
    note: Optional[str] = None

    class Config:
        from_attributes = True
