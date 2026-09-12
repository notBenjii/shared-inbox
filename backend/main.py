import os
from datetime import datetime, timezone, timedelta
from typing import Annotated

import psycopg2
import hashlib
import hmac
from argon2.exceptions import VerifyMismatchError
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, Header, HTTPException, Depends, Request
from pydantic import BaseModel, EmailStr, AfterValidator
from dotenv import load_dotenv
from argon2 import PasswordHasher
import secrets as secrets_module

load_dotenv()
ph = PasswordHasher()
_DUMMY_HASH = ph.hash("this-value-is-never-a-real-password")
_login_attempts: dict[str, dict] = {}
# structure per IP: {"attempts": int, "blocked_until": datetime, "last_attempt": datetime}

def normalize_email(email: EmailStr) -> str:
    return str(email).strip().lower()

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set.")

SALT_DERIVATION_KEY = os.environ.get("SALT_DERIVATION_KEY")
if not SALT_DERIVATION_KEY:
    raise RuntimeError("SALT_DERIVATION_KEY environment variable is not set.")

class NewItem(BaseModel):
    content: str
    device_name: str

class Credentials(BaseModel):
    email: Annotated[EmailStr, AfterValidator(normalize_email)]
    auth_verifier: str

class RegisterCredentials(BaseModel):
    email: Annotated[EmailStr, AfterValidator(normalize_email)]
    auth_verifier: str
    salt: str

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
        retry_after = int((entry["blocked_until"] - now).total_seconds()) + 1
        raise HTTPException(
            status_code=429,
            detail="Too many attempts. Try again later.",
            headers={"Retry-After": str(retry_after)},
        )

BASE_DELAY_SECONDS = 1
MAX_DELAY_SECONDS = 300  # rate limiting cap
RESET_AFTER_SECONDS = 600  # 10 minutes of no attempts = back to zero
FREE_ATTEMPTS = 4 # first N failures cost nothing

def record_attempt(client_ip: str, multiplier: int = 1):
    now = datetime.now(timezone.utc)
    entry = _login_attempts.get(client_ip)

    if entry is None or (now - entry["last_attempt"]).total_seconds() > RESET_AFTER_SECONDS:
        # first-ever attempt from this IP, or enough quiet time has passed to reset
        attempts = 1
    else:
        attempts = entry["attempts"] + 1

    if attempts <= FREE_ATTEMPTS:
        delay = 0
    else:
        delay = min(
            BASE_DELAY_SECONDS * (2 ** (attempts - FREE_ATTEMPTS - 1)) * multiplier,
            MAX_DELAY_SECONDS,
        )

    _login_attempts[client_ip] = {
        "attempts": attempts,
        "blocked_until": now + timedelta(seconds=delay),
        "last_attempt": now,
    }

def get_connection():
    conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
    return conn

def get_account_scoped_connection(account_id: int):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT set_config('app.current_account_id', %s, false)",
        (str(account_id),),
    )
    cursor.close()
    return conn

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
    conn = get_account_scoped_connection(account_id)
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
    conn = get_account_scoped_connection(account_id)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM items WHERE account_id = %s ORDER BY item_id DESC", (account_id,))
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return rows

@app.delete("/items/{item_id}", status_code=204)
def delete_item(item_id: int, session: dict = Depends(require_account)):
    account_id = session["account_id"]
    conn = get_account_scoped_connection(account_id)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM items WHERE item_id = %s AND account_id = %s", (item_id, account_id))
    conn.commit()
    deleted_count = cursor.rowcount
    cursor.close()
    conn.close()
    if deleted_count == 0:
        raise HTTPException(status_code=404, detail="Item not found")

@app.post("/accounts", status_code=201)
def register(creds: RegisterCredentials, request: Request):
    client_ip = request.client.host
    check_rate_limit(client_ip)
    record_attempt(client_ip, multiplier=2)

    auth_verifier_hash = ph.hash(creds.auth_verifier)
    created_at = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO accounts (email, auth_verifier_hash, salt, created_at) VALUES (%s, %s, %s, %s) RETURNING account_id",
                       (creds.email, auth_verifier_hash, creds.salt, created_at),
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

@app.get("/accounts/salt")
def get_salt(email: EmailStr):
    normalized_email = normalize_email(email)
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT salt FROM accounts WHERE email = %s", (normalized_email,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    fake_salt = hmac.new(
        SALT_DERIVATION_KEY.encode(), normalized_email.encode(), hashlib.sha256
    ).hexdigest()

    if row is not None:
        salt = row["salt"]  # type: ignore
        return {"salt": salt}
    else:
        return {"salt": fake_salt}

@app.post("/logout", status_code=204)
def logout(authorization: str = Header(default=None)):
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.removeprefix("Bearer ").strip()

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM sessions WHERE token = %s", (token,))
    conn.commit()
    cursor.close()
    conn.close()

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