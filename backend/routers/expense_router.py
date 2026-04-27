from fastapi import APIRouter
from datetime import datetime
from db.database import get_cursor, commit
from schemas.expense_schema import Expense

router = APIRouter()

@router.post("/expense")
def add_expense(expense: Expense):
    cursor = get_cursor()

    now = datetime.now().strftime("%Y-%m-%d")

    cursor.execute(
        "INSERT INTO expenses (title, amount, date, category) VALUES (?, ?, ?, ?)",
        (expense.title, expense.amount, now, expense.category)
    )
    commit()

    return {"status": "added"}


@router.get("/expenses")
def get_expenses():
    cursor = get_cursor()

    cursor.execute("SELECT id, title, amount, date, category FROM expenses")
    rows = cursor.fetchall()

    return [
        {"id": r[0], "title": r[1], "amount": r[2], "date": r[3], "category": r[4]}
        for r in rows
    ]


@router.delete("/expense/{expense_id}")
def delete_expense(expense_id: int):
    cursor = get_cursor()

    cursor.execute("DELETE FROM expenses WHERE id=?", (expense_id,))
    commit()

    return {"status": "deleted"}