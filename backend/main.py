import sys
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import expense_router, category_router, analytics_router
from db.init_db import init_db

init_db()  # ← 🔥これ入れる


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(expense_router.router)
app.include_router(category_router.router)
app.include_router(analytics_router.router)

@app.get("/")
def root():
    return {"message": "API OK"}