from fastapi import APIRouter
from app.api.auth import router as auth_router
from app.api.categories import router as categories_router
from app.api.records import router as records_router
from app.api.stats import router as stats_router
from app.api.export import router as export_router
from app.api.savings import router as savings_router
from app.api.sync import router as sync_router
from app.api.ai import router as ai_router
from app.api.ocr import router as ocr_router
from app.api.budget import router as budget_router
from app.api.wallets import router as wallets_router
from app.api.reports import router as reports_router

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router)
api_router.include_router(categories_router)
api_router.include_router(records_router)
api_router.include_router(stats_router)
api_router.include_router(export_router)
api_router.include_router(savings_router)
api_router.include_router(sync_router)
api_router.include_router(ai_router)
api_router.include_router(ocr_router)
api_router.include_router(budget_router)
api_router.include_router(wallets_router)
api_router.include_router(reports_router)
