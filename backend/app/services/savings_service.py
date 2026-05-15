from typing import Optional
from sqlalchemy.orm import Session
from app.models.savings_goal import SavingsGoal, AutoSaveRule
from app.schemas.savings import GoalCreate, GoalUpdate, DepositRequest, RuleCreate


def create_goal(db: Session, user_id: int, data: GoalCreate) -> SavingsGoal:
    goal = SavingsGoal(
        user_id=user_id,
        name=data.name,
        target_amount=data.target_amount,
        deadline=data.deadline,
        emoji=data.emoji or "💰",
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal


def update_goal(db: Session, goal_id: int, user_id: int, data: GoalUpdate) -> Optional[SavingsGoal]:
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == goal_id, SavingsGoal.user_id == user_id
    ).first()
    if not goal:
        return None

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(goal, field, value)
    db.commit()
    db.refresh(goal)
    return goal


def delete_goal(db: Session, goal_id: int, user_id: int) -> bool:
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == goal_id, SavingsGoal.user_id == user_id
    ).first()
    if not goal:
        return False
    db.query(AutoSaveRule).filter(AutoSaveRule.goal_id == goal_id).delete()
    db.delete(goal)
    db.commit()
    return True


def deposit(db: Session, user_id: int, data: DepositRequest) -> Optional[SavingsGoal]:
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == data.goal_id, SavingsGoal.user_id == user_id
    ).first()
    if not goal:
        return None

    goal.current_amount += data.amount
    if goal.current_amount >= goal.target_amount and not goal.is_completed:
        goal.is_completed = True
    db.commit()
    db.refresh(goal)
    return goal


def create_rule(db: Session, user_id: int, data: RuleCreate) -> AutoSaveRule:
    rule = AutoSaveRule(
        user_id=user_id,
        goal_id=data.goal_id,
        rule_type=data.rule_type,
        amount=data.amount,
    )
    db.add(rule)
    db.commit()
    db.refresh(rule)
    return rule


def delete_rule(db: Session, rule_id: int, user_id: int) -> bool:
    rule = db.query(AutoSaveRule).filter(
        AutoSaveRule.id == rule_id, AutoSaveRule.user_id == user_id
    ).first()
    if rule:
        db.delete(rule)
        db.commit()
        return True
    return False
