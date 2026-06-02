from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.common import success
from app.services.stats_service import get_monthly_stats, get_yearly_stats, get_weekly_stats

router = APIRouter(prefix="/stats", tags=["统计"])


@router.get("/monthly")
def monthly_stats(
    month: str = Query(..., description="格式: YYYY-MM"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    data = get_monthly_stats(db, user.id, month)
    return success(data=data)


@router.get("/yearly")
def yearly_stats(
    year: str = Query(..., description="格式: YYYY"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    data = get_yearly_stats(db, user.id, year)
    return success(data=data)


@router.get("/weekly")
def weekly_stats(
    start: str = Query(..., description="格式: YYYY-MM-DD"),
    end: str = Query(..., description="格式: YYYY-MM-DD"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    data = get_weekly_stats(db, user.id, start, end)
    return success(data=data)
