from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.category import Category
from app.schemas.common import success

router = APIRouter(prefix="/categories", tags=["分类"])


def _build_tree(categories: list[Category]) -> list[dict]:
    """将扁平分类列表转为树形结构。"""
    by_id: dict[int, dict] = {}
    roots: list[dict] = []

    for c in categories:
        node = {
            "id": c.id,
            "name": c.name,
            "type": c.type.value if hasattr(c.type, 'value') else c.type,
            "emoji": c.emoji,
            "children": [],
        }
        by_id[c.id] = node

    for c in categories:
        node = by_id[c.id]
        if c.parent_id and c.parent_id in by_id:
            by_id[c.parent_id]["children"].append(node)
        else:
            roots.append(node)

    return roots


@router.get("")
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(Category).order_by(Category.sort_order).all()
    tree = _build_tree(categories)
    return success(data=tree)
