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
    expenses.append(expense)
    return {"status": "added"}

@app.get("/expenses")
def get_expenses():
    return expenses