from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import sqlite3
from datetime import datetime
import os

app = FastAPI()

# 🔥 CORS（Flutter接続用）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🔥 DBパス固定（超重要）
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "data.db")

conn = sqlite3.connect(DB_PATH, check_same_thread=False)
cursor = conn.cursor()

# 🔥 テーブル作成
cursor.execute("""
CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    amount INTEGER,
    date TEXT
)
""")

# 🔥 category追加（安全版）
try:
    cursor.execute("ALTER TABLE expenses ADD COLUMN category TEXT")
    conn.commit()
except:
    pass  # 既にあれば無視

# 🔥 インデックス
cursor.execute("""
CREATE INDEX IF NOT EXISTS idx_date ON expenses(date)
""")

conn.commit()

# モデル
class Expense(BaseModel):
    title: str
    amount: int
    category: str   # 🔥追加

# ルート確認
@app.get("/")
def root():
    return {"message": "API OK"}

# 🟢 追加
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

# 🟢 一覧
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

# 🟢 削除
@app.delete("/expense/{expense_id}")
def delete_expense(expense_id: int):
    cursor.execute("DELETE FROM expenses WHERE id=?", (expense_id,))
    conn.commit()
    return {"status": "deleted"
            }

# 🟢 月集合（指定）
@app.get("/expenses/month-total/{year_month}")
def get_month_total(year_month: str):
    cursor = conn.cursor()

    cursor.execute(
        "SELECT SUM(amount) FROM expenses WHERE date LIKE ?",
        (f"{year_month}%",)
    )

    total = cursor.fetchone()[0] or 0
    return {"total": total}

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/expenses/daily")
def get_daily_expenses(year_month: str):
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
