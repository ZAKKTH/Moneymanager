import sqlite3
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "../data.db")

conn = sqlite3.connect(DB_PATH, check_same_thread=False)

def get_cursor():
    return conn.cursor()

def commit():
    conn.commit()