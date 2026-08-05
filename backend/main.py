import os
import sqlite3
from datetime import datetime, timezone

from fastapi import FastAPI, Header, HTTPException, Depends
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

APP_TOKEN = os.environ.get("APP_TOKEN")
if not APP_TOKEN:
    raise RuntimeError("APP_TOKEN environment variable is not set.")

class NewItem(BaseModel):
    content: str
    device_name: str

app = FastAPI()
DB_PATH = "inbox.db"

def require_token(authorization: str = Header(default=None)):
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")

    provided = authorization.removeprefix("Bearer ").strip()
    if provided != APP_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # lets us access columns by name, e.g. row["content"]
    return conn

def init_db():
    conn = get_connection()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            device_name TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()

init_db()

@app.get("/")
def health_check():
    return {"status": "ok"}

@app.post("/items", dependencies=[Depends(require_token)])
def create_item(new_item: NewItem):
    created_at = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    cursor = conn.execute(
        "INSERT INTO items (content, device_name, created_at) VALUES (?, ?, ?)",
        (new_item.content, new_item.device_name, created_at),
    )
    conn.commit()
    item_id = cursor.lastrowid
    conn.close()
    return {"id": item_id, "content": new_item.content, "device_name": new_item.device_name, "created_at": created_at}

@app.get("/items", dependencies=[Depends(require_token)])
def list_items():
    conn = get_connection()
    rows = conn.execute("SELECT * FROM items ORDER BY id DESC").fetchall()
    conn.close()
    return [dict(row) for row in rows]