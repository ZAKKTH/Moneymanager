from fastapi import APIRouter
from db.database import get_cursor, commit
from schemas.category_schema import Category

router = APIRouter()

@router.get("/categories")
def get_categories():
    cursor = get_cursor()

    cursor.execute("SELECT id, name, budget FROM categories")
    rows = cursor.fetchall()

    return [
        {"id": r[0], "name": r[1], "budget": r[2]}
        for r in rows
    ]


@router.post("/categories")
def add_category(category: Category):
    cursor = get_cursor()

    try:
        cursor.execute(
            "INSERT INTO categories (name, budget) VALUES (?, ?)",
            (category.name, category.budget)
        )
        commit()
    except:
        return {"status": "exists"}

    return {"status": "ok"}


@router.delete("/categories/{category_id}")
def delete_category(category_id: int):
    cursor = get_cursor()

    cursor.execute("DELETE FROM categories WHERE id=?", (category_id,))
    commit()

    return {"status": "deleted"}