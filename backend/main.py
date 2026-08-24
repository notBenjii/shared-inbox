import os
from datetime import datetime, timezone, timedelta

import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, Header, HTTPException, Depends
from pydantic import BaseModel
from dotenv import load_dotenv
import secrets as secrets_module

load_dotenv()

APP_TOKEN = os.environ.get("APP_TOKEN")
if not APP_TOKEN:
    raise RuntimeError("APP_TOKEN environment variable is not set.")

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set.")

class NewItem(BaseModel):
    content: str
    device_name: str

app = FastAPI()

def require_token(authorization: str = Header(default=None)):
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")

    provided = authorization.removeprefix("Bearer ").strip()
    if provided != APP_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_connection():
    conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id SERIAL PRIMARY KEY,
            content TEXT NOT NULL,
            device_name TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS pairing_codes (
            code TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            used BOOLEAN NOT NULL DEFAULT FALSE
        )
    """)
    conn.commit()
    cursor.close()
    conn.close()

init_db()

def cleanup_old_pairing_codes():
    conn = get_connection()
    cursor = conn.cursor()
    cutoff = (datetime.now(timezone.utc) - timedelta(minutes=10)).isoformat()
    cursor.execute(
        "DELETE FROM pairing_codes WHERE used = TRUE OR created_at < %s",
        (cutoff,),
    )
    conn.commit()
    cursor.close()
    conn.close()

@app.get("/")
def health_check():
    return {"status": "ok"}

@app.post("/items", status_code=201, dependencies=[Depends(require_token)])
def create_item(new_item: NewItem):
    created_at = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO items (content, device_name, created_at) VALUES (%s, %s, %s) RETURNING id",
        (new_item.content, new_item.device_name, created_at),
    )
    result = cursor.fetchone()
    item_id = result["id"]  # type: ignore
    conn.commit()
    cursor.close()
    conn.close()
    return {"id": item_id, "content": new_item.content, "device_name": new_item.device_name, "created_at": created_at}

@app.get("/items", dependencies=[Depends(require_token)])
def list_items():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM items ORDER BY id DESC")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return rows

@app.delete("/items/{item_id}", status_code=204, dependencies=[Depends(require_token)])
def delete_item(item_id: int):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM items WHERE id = %s", (item_id,))
    conn.commit()
    deleted_count = cursor.rowcount
    cursor.close()
    conn.close()
    if deleted_count == 0:
        raise HTTPException(status_code=404, detail="Item not found")

@app.post("/pairing-codes", dependencies=[Depends(require_token)])
def create_pairing_code():
    cleanup_old_pairing_codes()
    code = secrets_module.token_urlsafe(12)
    created_at = datetime.now(timezone.utc).isoformat()

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO pairing_codes (code, created_at, used) VALUES (%s, %s, FALSE)",
        (code, created_at),
    )
    conn.commit()
    cursor.close()
    conn.close()

    return {"code": code}

@app.post("/pairing-codes/{code}/redeem")
def redeem_pairing_code(code: str):
    cleanup_old_pairing_codes()
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT created_at, used FROM pairing_codes WHERE code = %s", (code,))
    row = cursor.fetchone()

    if row is None:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Invalid code")

    if row["used"]:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=410, detail="Code already used")

    created_at = datetime.fromisoformat(row["created_at"])
    if datetime.now(timezone.utc) - created_at > timedelta(minutes=2):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=410, detail="Code expired")

    cursor.execute("UPDATE pairing_codes SET used = TRUE WHERE code = %s", (code,))
    conn.commit()
    cursor.close()
    conn.close()

    return {"token": APP_TOKEN, "server_url": "https://shared-inbox.onrender.com"}