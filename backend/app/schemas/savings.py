from pydantic import BaseModel, Field
from app.models.savings_goal import AutoRuleType


class GoalCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    target_amount: float = Field(gt=0)
    deadline: str | None = None
    emoji: str | None = "💰"


class GoalUpdate(BaseModel):
    name: str | None = None
    target_amount: float | None = None
    deadline: str | None = None
    emoji: str | None = None
    is_completed: bool | None = None


class DepositRequest(BaseModel):
    goal_id: int
    amount: float = Field(gt=0)


class RuleCreate(BaseModel):
    goal_id: int
    rule_type: AutoRuleType
    amount: float | None = None
