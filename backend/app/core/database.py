from sqlalchemy import create_engine
from sqlalchemy.orm import Session, DeclarativeBase

from app.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {},
    echo=settings.DEBUG,
)


class Base(DeclarativeBase):
    pass


def get_db():
    """FastAPI 依赖注入：每个请求一个数据库会话。"""
    db = Session(engine)
    try:
        yield db
    finally:
        db.close()


def init_db():
    """创建所有表 + 种子数据。在主进程启动时调用一次。"""
    Base.metadata.create_all(bind=engine)
