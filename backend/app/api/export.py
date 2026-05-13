from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session, joinedload
import io

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.record import Record

router = APIRouter(prefix="/export", tags=["导出"])


@router.get("/csv")
def export_csv(
    month: str | None = Query(None),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    q = (
        db.query(Record)
        .options(joinedload(Record.category))
        .filter(Record.user_id == user.id)
        .order_by(Record.date.desc())
    )
    if month:
        q = q.filter(Record.date.startswith(month))

    records = q.all()

    output = io.StringIO()
    output.write("﻿日期,类型,分类,金额,备注\n")  # BOM for Excel
    for r in records:
        type_name = r.type.value if hasattr(r.type, 'value') else r.type
        cat_name = r.category.name if r.category else ""
        note = r.note or ""
        output.write(f"{r.date},{type_name},{cat_name},{r.amount},{note}\n")

    csv_content = output.getvalue()
    output.close()

    return StreamingResponse(
        iter([csv_content]),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": "attachment; filename=records.csv"},
    )
