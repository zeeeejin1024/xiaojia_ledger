from datetime import date
from pydantic import BaseModel, Field
from app.models.category import RecordType


class RecordCreate(BaseModel):
    type: RecordType
    amount: float = Field(gt=0)
    category_id: int
    date: str
    note: str | None = None


class RecordUpdate(BaseModel):
    field: str
    value: str | float | None


class RecordOut(BaseModel):
    id: int
    type: str
    amount: float
    category_id: int
    category_name: str = ""
    category_emoji: str | None = None
    date: str
    note: str | None = None

    class Config:
        from_attributes = True
