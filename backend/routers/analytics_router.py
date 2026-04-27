from fastapi import APIRouter
from db.database import get_cursor

router = APIRouter()

@router.get("/expenses/month-total/{year_month}")
def get_month_total(year_month: str):
    cursor = get_cursor()

    cursor.execute(
        "SELECT SUM(amount) FROM expenses WHERE date LIKE ?",
        (f"{year_month}%",)
    )

    total = cursor.fetchone()[0] or 0
    return {"total": total}


@router.get("/expenses/category-total/{year_month}")
def category_total(year_month: str):
    cursor = get_cursor()

    cursor.execute("""
        SELECT category, SUM(amount)
        FROM expenses
        WHERE date LIKE ?
        GROUP BY category
    """, (f"{year_month}%",))

    rows = cursor.fetchall()

    return [{"category": r[0], "total": r[1]} for r in rows]