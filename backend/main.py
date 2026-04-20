from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import sqlite3
from datetime import datetime
import os

app = FastAPI()

# 🔥 CORS（1回だけ！）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🔥 DBパス
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "data.db")

conn = sqlite3.connect(DB_PATH, check_same_thread=False)
cursor = conn.cursor()

# =========================
# 🔥 テーブル作成
# =========================

# 🟢 支出
cursor.execute("""
CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    amount INTEGER,
    date TEXT
)
""")

# 🟢 category追加（安全）
try:
    cursor.execute("ALTER TABLE expenses ADD COLUMN category TEXT")
    conn.commit()
except:
    pass

# 🟢 インデックス
cursor.execute("""
CREATE INDEX IF NOT EXISTS idx_date ON expenses(date)
""")

# 🟢 カテゴリ
cursor.execute("""
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE
)
""")

# 🟢 budgetカラム追加（安全）
try:
    cursor.execute("ALTER TABLE categories ADD COLUMN budget INTEGER")
    conn.commit()
except:
    pass

# 🟢 予算（別管理用）
cursor.execute("""
CREATE TABLE IF NOT EXISTS budget (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT,
    limit_amount INTEGER
)
""")

# 🟢 設定
cursor.execute("""
CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY,
    income INTEGER,
    fixed_cost INTEGER,
    saving INTEGER
)
""")

conn.commit()

# =========================
# 🔥 モデル
# =========================

class Expense(BaseModel):
    title: str
    amount: int
    category: str

class Category(BaseModel):
    name: str
    budget: int

# =========================
# 🔥 API
# =========================

@app.get("/")
def root():
    return {"message": "API OK"}

# =========================
# 🟢 支出
# =========================

@app.post("/expense")
def add_expense(expense: Expense):
    now = datetime.now().strftime("%Y-%m-%d")
    cursor = conn.cursor()

    cursor.execute(
        "INSERT INTO expenses (title, amount, date, category) VALUES (?, ?, ?, ?)",
        (expense.title, expense.amount, now, expense.category)
    )
    conn.commit()

    return {"status": "added"}

@app.get("/expenses")
def get_expenses():
    cursor = conn.cursor()

    cursor.execute("SELECT id, title, amount, date, category FROM expenses")
    rows = cursor.fetchall()

    return [
        {
            "id": r[0],
            "title": r[1],
            "amount": r[2],
            "date": r[3],
            "category": r[4]
        }
        for r in rows
    ]

@app.delete("/expense/{expense_id}")
def delete_expense(expense_id: int):
    cursor = conn.cursor()

    cursor.execute("DELETE FROM expenses WHERE id=?", (expense_id,))
    conn.commit()

    return {"status": "deleted"}

# =========================
# 🟢 集計
# =========================

@app.get("/expenses/month-total/{year_month}")
def get_month_total(year_month: str):
    cursor = conn.cursor()

    cursor.execute(
        "SELECT SUM(amount) FROM expenses WHERE date LIKE ?",
        (f"{year_month}%",)
    )

    total = cursor.fetchone()[0] or 0
    return {"total": total}

@app.get("/expenses/daily")
def get_daily_expenses(year_month: str):
    cursor = conn.cursor()

    cursor.execute("""
        SELECT date, SUM(amount)
        FROM expenses
        WHERE date LIKE ?
        GROUP BY date
        ORDER BY date
    """, (f"{year_month}%",))

    rows = cursor.fetchall()

    return [
        {"date": r[0], "total": r[1]}
        for r in rows
    ]

@app.get("/expenses/category-total/{year_month}")
def category_total(year_month: str):
    cursor = conn.cursor()

    cursor.execute("""
        SELECT category, SUM(amount)
        FROM expenses
        WHERE date LIKE ?
        GROUP BY category
    """, (f"{year_month}%",))

    rows = cursor.fetchall()

    return [
        {"category": r[0], "total": r[1]}
        for r in rows
    ]

# =========================
# 🟢 カテゴリ
# =========================

@app.get("/categories")
def get_categories():
    cursor = conn.cursor()

    cursor.execute("SELECT id, name, budget FROM categories")
    rows = cursor.fetchall()

    return [
        {
            "id": r[0],
            "name": r[1],
            "budget": r[2]
        }
        for r in rows
    ]

@app.post("/categories")
def add_category(category: Category):
    cursor = conn.cursor()

    try:
        cursor.execute(
            "INSERT INTO categories (name, budget) VALUES (?, ?)",
            (category.name, category.budget)
        )
        conn.commit()
    except:
        return {"status": "exists"}

    return {"status": "ok"}

@app.delete("/categories/{category_id}")
def delete_category(category_id: int):
    cursor = conn.cursor()

    cursor.execute(
        "DELETE FROM categories WHERE id=?",
        (category_id,)
    )
    conn.commit()

    return {"status": "deleted"}

# =========================
# 🟢 カテゴリ予算
# =========================

@app.put("/categories/{category_id}")
def update_category_budget(category_id: int, budget: int):
    cursor = conn.cursor()

    cursor.execute(
        "UPDATE categories SET budget=? WHERE id=?",
        (budget, category_id)
    )
    conn.commit()

    return {"status": "updated"}
