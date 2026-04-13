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
conn.commit()

# モデル
class Expense(BaseModel):
    title: str
    amount: int

# ルート確認
@app.get("/")
def root():
    return {"message": "API OK"}

# 🟢 追加
@app.post("/expense")
def add_expense(expense: Expense):
    now = datetime.now().strftime("%Y-%m-%d")

    cursor.execute(
        "INSERT INTO expenses (title, amount, date) VALUES (?, ?, ?)",
        (expense.title, expense.amount, now)
    )
    conn.commit()
    return {"status": "added"}

# 🟢 一覧
@app.get("/expenses")
def get_expenses():
    cursor.execute("SELECT id, title, amount, date FROM expenses")
    rows = cursor.fetchall()

    return [
        {"id": r[0], "title": r[1], "amount": r[2], "date": r[3]}
        for r in rows
    ]

# 🟢 削除
@app.delete("/expense/{expense_id}")
def delete_expense(expense_id: int):
    cursor.execute("DELETE FROM expenses WHERE id=?", (expense_id,))
    conn.commit()
    return {"status": "deleted"}

# 🟢 月合計（指定）
@app.get("/expenses/month-total/{year_month}")
def get_month_total(year_month: str):
    cursor.execute(
        "SELECT SUM(amount) FROM expenses WHERE date LIKE ?",
        (f"{year_month}%",)
    )

    total = cursor.fetchone()[0] or 0
    return {"total": total}