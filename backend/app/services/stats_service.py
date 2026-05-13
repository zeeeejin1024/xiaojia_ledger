from sqlalchemy.orm import Session, joinedload
from app.models.record import Record


def get_monthly_stats(db: Session, user_id: int, month: str) -> dict:
    records = (
        db.query(Record)
        .options(joinedload(Record.category))
        .filter(Record.user_id == user_id)
        .filter(Record.date.startswith(month))
        .all()
    )
    return _aggregate(records)


def get_yearly_stats(db: Session, user_id: int, year: str) -> dict:
    records = (
        db.query(Record)
        .options(joinedload(Record.category))
        .filter(Record.user_id == user_id)
        .filter(Record.date.startswith(year))
        .all()
    )

    # 按月分组
    months_data: dict[str, dict] = {}
    for r in records:
        m = r.date[:7]
        if m not in months_data:
            months_data[m] = {"income": 0.0, "expense": 0.0, "savings": 0.0}
        type_name = r.type.value if hasattr(r.type, 'value') else r.type
        if type_name in months_data[m]:
            months_data[m][type_name] += r.amount

    months_list = []
    for m in sorted(months_data.keys()):
        d = months_data[m]
        months_list.append({
            "month": m,
            "income": round(d["income"], 2),
            "expense": round(d["expense"], 2),
            "savings": round(d["savings"], 2),
            "balance": round(d["income"] - d["expense"] - d["savings"], 2),
        })

    total_income = sum(x["income"] for x in months_list)
    total_expense = sum(x["expense"] for x in months_list)
    total_savings = sum(x["savings"] for x in months_list)

    return {
        "year": year,
        "months": months_list,
        "total_income": round(total_income, 2),
        "total_expense": round(total_expense, 2),
        "total_savings": round(total_savings, 2),
        "total_balance": round(total_income - total_expense - total_savings, 2),
    }


def _aggregate(records: list[Record]) -> dict:
    income = 0.0
    expense = 0.0
    savings = 0.0
    income_cats: dict[str, float] = {}
    expense_cats: dict[str, float] = {}
    savings_cats: dict[str, float] = {}

    for r in records:
        type_name = r.type.value if hasattr(r.type, 'value') else r.type
        cat_name = r.category.name if r.category else ""
        if type_name == "income":
            income += r.amount
            income_cats[cat_name] = income_cats.get(cat_name, 0) + r.amount
        elif type_name == "savings":
            savings += r.amount
            savings_cats[cat_name] = savings_cats.get(cat_name, 0) + r.amount
        else:
            expense += r.amount
            expense_cats[cat_name] = expense_cats.get(cat_name, 0) + r.amount

    return {
        "income": round(income, 2),
        "expense": round(expense, 2),
        "savings": round(savings, 2),
        "balance": round(income - expense - savings, 2),
        "net_balance": round(income - expense, 2),
        "count": len(records),
        "income_cats": income_cats,
        "expense_cats": expense_cats,
        "savings_cats": savings_cats,
    }
