import os
from datetime import datetime, timezone, timedelta

import psycopg2
from argon2.exceptions import VerifyMismatchError
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, Header, HTTPException, Depends, Request
from pydantic import BaseModel, EmailStr, field_validator
from dotenv import load_dotenv
from argon2 import PasswordHasher
import secrets as secrets_module

from starlette.middleware.sessions import Session

load_dotenv()
ph = PasswordHasher()
_DUMMY_HASH = ph.hash("this-value-is-never-a-real-password")
_login_attempts: dict[str, dict] = {}
# structure per IP: {"attempts": int, "blocked_until": datetime, "last_attempt": datetime}

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set.")

class NewItem(BaseModel):
    content: str
    device_name: str

class Credentials(BaseModel):
    email: EmailStr
    auth_verifier: str

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return value.strip().lower()

app = FastAPI()

def require_account(authorization: str = Header(default=None)):
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")

    provided = authorization.removeprefix("Bearer ").strip()
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT token, account_id FROM sessions WHERE token = %s",
                   (provided,),
    )
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    if row is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    token = row["token"] # type: ignore
    account_id = row["account_id"] # type: ignore
    return {"token": token,"account_id": account_id}

def check_rate_limit(client_ip: str):
    entry = _login_attempts.get(client_ip)
    if entry is None:
        return  # never seen this IP before, nothing to check

    now = datetime.now(timezone.utc)

    if entry["blocked_until"] is not None and now < entry["blocked_until"]:
        raise HTTPException(status_code=429, detail="Too many attempts. Try again later.")

BASE_DELAY_SECONDS = 1
MAX_DELAY_SECONDS = 300  # rate limiting cap
RESET_AFTER_SECONDS = 600  # 10 minutes of no attempts = back to zero

def record_attempt(client_ip: str, multiplier: int = 1):
    now = datetime.now(timezone.utc)
    entry = _login_attempts.get(client_ip)

    if entry is None or (now - entry["last_attempt"]).total_seconds() > RESET_AFTER_SECONDS:
        # first-ever attempt from this IP, or enough quiet time has passed to reset
        attempts = 1
    else:
        attempts = entry["attempts"] + 1

    delay = min(BASE_DELAY_SECONDS * (2 ** (attempts - 1)) * multiplier, MAX_DELAY_SECONDS)

    _login_attempts[client_ip] = {
        "attempts": attempts,
        "blocked_until": now + timedelta(seconds=delay),
        "last_attempt": now,
    }

def get_connection():
    conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS accounts (
	        account_id SERIAL PRIMARY KEY,
	        email TEXT NOT NULL UNIQUE,
	        auth_verifier_hash TEXT NOT NULL,
	        created_at TEXT NOT NULL
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS items (
            item_id SERIAL PRIMARY KEY,
            account_id INT NOT NULL,
            content TEXT NOT NULL,
            device_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            CONSTRAINT fk_account_id
                FOREIGN KEY(account_id)
                REFERENCES accounts(account_id)
                ON DELETE CASCADE
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            token TEXT PRIMARY KEY,
            account_id INT NOT NULL,
            created_at TEXT NOT NULL,
            CONSTRAINT fk_account_id
                FOREIGN KEY(account_id)
                REFERENCES accounts(account_id)
                ON DELETE CASCADE
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS pairing_codes (
            code TEXT PRIMARY KEY,
            account_id INT NOT NULL,
            created_at TEXT NOT NULL,
            used BOOLEAN NOT NULL DEFAULT FALSE,
            CONSTRAINT fk_account_id
                FOREIGN KEY(account_id)
                REFERENCES accounts(account_id)
                ON DELETE CASCADE
        )
    """)
    conn.commit()
    cursor.close()
    conn.close()

init_db()

def create_session(account_id: int) -> str:
    token = secrets_module.token_urlsafe(32)
    created_at = datetime.now(timezone.utc).isoformat()

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO sessions (token, account_id, created_at) VALUES (%s, %s, %s)",
                   (token, account_id, created_at),
                   )
    conn.commit()
    cursor.close()
    conn.close()

    return token

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

@app.post("/items", status_code=201)
def create_item(new_item: NewItem, session: dict = Depends(require_account)):
    account_id = session["account_id"]
    created_at = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO items (account_id, content, device_name, created_at) VALUES (%s, %s, %s, %s) RETURNING item_id",
        (account_id, new_item.content, new_item.device_name, created_at),
    )
    result = cursor.fetchone()
    item_id = result["item_id"]  # type: ignore
    conn.commit()
    cursor.close()
    conn.close()
    return {"item_id": item_id, "account_id": account_id, "content": new_item.content, "device_name": new_item.device_name, "created_at": created_at}

@app.get("/items")
def list_items(session: dict = Depends(require_account)):
    account_id = session["account_id"]
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM items WHERE account_id = %s ORDER BY item_id DESC", (account_id,))
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return rows

@app.delete("/items/{item_id}", status_code=204)
def delete_item(item_id: int, session: dict = Depends(require_account)):
    account_id = session["account_id"]
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM items WHERE item_id = %s AND account_id = %s", (item_id, account_id))
    conn.commit()
    deleted_count = cursor.rowcount
    cursor.close()
    conn.close()
    if deleted_count == 0:
        raise HTTPException(status_code=404, detail="Item not found")

@app.post("/accounts", status_code=201)
def register(creds: Credentials, request: Request):
    client_ip = request.client.host
    check_rate_limit(client_ip)
    record_attempt(client_ip, multiplier=2)

    auth_verifier_hash = ph.hash(creds.auth_verifier)
    created_at = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO accounts (email, auth_verifier_hash, created_at) VALUES (%s, %s, %s) RETURNING account_id",
                       (creds.email, auth_verifier_hash, created_at),
        )
        result = cursor.fetchone()
        account_id = result["account_id"]  # type: ignore
        conn.commit()
        cursor.close()
        conn.close()
    except psycopg2.IntegrityError:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=409, detail="Email already registered")

    token = create_session(account_id)
    return {"token": token}

@app.post("/sessions")
def login(creds: Credentials, request: Request):
    client_ip = request.client.host
    check_rate_limit(client_ip)

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT account_id, email, auth_verifier_hash FROM accounts WHERE email = %s",
        (creds.email,),
    )
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    if row is None:
        try:
            ph.verify(_DUMMY_HASH, creds.auth_verifier)
        except VerifyMismatchError:
            pass
        record_attempt(client_ip)
        raise HTTPException(status_code=404, detail="Account not found") # Email not found

    stored_hash = row["auth_verifier_hash"] # type: ignore
    try:
        ph.verify(stored_hash, creds.auth_verifier)
    except VerifyMismatchError:
        record_attempt(client_ip)
        raise HTTPException(status_code=404, detail="Account not found") # Passwords do not match

    account_id = row["account_id"] # type: ignore

    if ph.check_needs_rehash(stored_hash):
        new_hash = ph.hash(creds.auth_verifier)
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE accounts SET auth_verifier_hash = %s WHERE account_id = %s",
            (new_hash, account_id),
        )
        conn.commit()
        cursor.close()
        conn.close()

    token = create_session(account_id)

    return {"token": token}

@app.post("/pairing-codes")
def create_pairing_code(session: dict = Depends(require_account)):
    raise HTTPException(status_code=503)
    cleanup_old_pairing_codes()
    code = secrets_module.token_urlsafe(16)
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
    raise HTTPException(status_code=503)
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