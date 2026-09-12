-- schema.sql
-- Run manually in Neon's SQL editor (connected as the owner role,
-- e.g. neondb_owner), NOT automatically by the app.
-- Safe to re-run: every statement here is idempotent.

CREATE TABLE IF NOT EXISTS accounts (
    account_id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    auth_verifier_hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    created_at TEXT NOT NULL
);

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
);

CREATE TABLE IF NOT EXISTS sessions (
    token TEXT PRIMARY KEY,
    account_id INT NOT NULL,
    created_at TEXT NOT NULL,
    CONSTRAINT fk_account_id
        FOREIGN KEY(account_id)
        REFERENCES accounts(account_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pairing_codes (
    code TEXT PRIMARY KEY,
    account_id INT NOT NULL,
    created_at TEXT NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_account_id
        FOREIGN KEY(account_id)
        REFERENCES accounts(account_id)
        ON DELETE CASCADE
);

-- Row-Level Security on items
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE items FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS items_account_isolation ON items;
CREATE POLICY items_account_isolation ON items
    USING (account_id = current_setting('app.current_account_id')::int);

-- Privileges for the runtime app role.
-- Re-run this section too if you ever add a new table/sequence.
GRANT SELECT, INSERT, UPDATE, DELETE ON accounts, items, sessions, pairing_codes TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;