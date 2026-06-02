from typing import Dict, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.category import Category
from app.schemas.common import success

router = APIRouter(prefix="/categories", tags=["分类"])


def _build_tree(categories: List[Category]) -> List[dict]:
    """将扁平分类列表转为树形结构。"""
    by_id: Dict[int, dict] = {}
    roots: List[dict] = []

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


@router.post("")
def create_category(data: dict, db: Session = Depends(get_db)):
    """创建自定义分类"""
    name = data.get('name', '').strip()
    cat_type = data.get('type', 'expense')
    emoji = data.get('emoji', '📌')
    parent_id = data.get('parent_id', None)

    if not name:
        return {"code": 1, "message": "分类名称不能为空"}

    cat = Category(
        name=name, type=cat_type, emoji=emoji,
        parent_id=parent_id, is_system=False, sort_order=999
    )
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return success(data={"id": cat.id, "name": cat.name, "emoji": cat.emoji})
