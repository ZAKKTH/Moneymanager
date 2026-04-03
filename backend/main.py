from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

expenses = []

class Expense(BaseModel):
    title: str
    amount: int

@app.get("/")
def root():
    return {"message": "API OK"}

@app.post("/expense")
def add_expense(expense: Expense):
    cursor.execute(
        "INSERT INTO expenses (title, amount) VALUES (?, ?)",
        (expense.title, expense.amount)
    )
    conn.commit()
    return {"status": "added"}

@app.get("/expenses")
def get_expenses():
    cursor.execute("SELECT title, amount FROM expenses")
    rows = cursor.fetchall()
    return [{"title": r[0], "amount": r[1]} for r in rows]

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
import sqlite3

conn = sqlite3.connect("data.db", check_same_thread=False)
cursor = conn.cursor()

cursor.execute("""
CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    amount INTEGER
)
""")
conn.commit()