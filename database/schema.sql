-- UPI Scam Shield - canonical SQLite schema.
-- Foreign keys are NOT enforced by SQLite unless PRAGMA foreign_keys=ON is set
-- on every connection (connection.py does this).
-- All statements are idempotent so init_db() can be run repeatedly.

CREATE TABLE IF NOT EXISTS users (
    user_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT NOT NULL UNIQUE CHECK (length(username) BETWEEN 3 AND 50),
    name          TEXT NOT NULL CHECK (length(name) BETWEEN 1 AND 100),
    email         TEXT NOT NULL UNIQUE COLLATE NOCASE CHECK (length(email) <= 254),
    password_hash TEXT NOT NULL,
    created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

-- Added beyond the original 5 tables: needed for login/logout/"me" with
-- revocable bearer tokens. Only a hash of the token is stored.
CREATE TABLE IF NOT EXISTS sessions (
    session_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    expires_at TEXT NOT NULL,
    revoked_at TEXT
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          INTEGER NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    account_number   TEXT NOT NULL UNIQUE,
    upi_id           TEXT NOT NULL UNIQUE,
    balance_in_paise INTEGER NOT NULL DEFAULT 0 CHECK (balance_in_paise >= 0),
    created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_user_id          INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    receiver_user_id        INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    amount_in_paise         INTEGER NOT NULL CHECK (amount_in_paise > 0),
    currency                TEXT NOT NULL DEFAULT 'INR',
    status                  TEXT NOT NULL CHECK (status IN ('pending', 'success', 'failed', 'reversed')),
    note                    TEXT,
    created_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

-- user_id is NULL for failed attempts against unknown accounts, and
-- becomes NULL if the user is later deleted (audit rows are kept).
CREATE TABLE IF NOT EXISTS login_history (
    login_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    login_time TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    status     TEXT NOT NULL CHECK (status IN ('success', 'failed')),
    ip_address TEXT
);

-- Retention policy: deleting a user keeps anonymised rows (user_id -> NULL).
-- The original message/URL/screenshot is NOT stored; only a SHA-256
-- fingerprint (useful for de-duplication) plus the structured result.
CREATE TABLE IF NOT EXISTS analysis_history (
    analysis_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id           INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    input_type        TEXT NOT NULL CHECK (input_type IN ('text', 'url', 'upi_id', 'qr', 'image')),
    input_fingerprint TEXT,
    risk_score        INTEGER NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
    risk_level        TEXT NOT NULL CHECK (risk_level IN ('low', 'medium', 'high')),
    explanation       TEXT NOT NULL CHECK (json_valid(explanation)),  -- JSON array of strings
    recommendation    TEXT NOT NULL,
    created_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS activity_logs (
    event_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    platform   TEXT NOT NULL CHECK (platform IN ('web', 'android')),
    event_type TEXT NOT NULL,
    page_name  TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS reports (
    report_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    report_type TEXT NOT NULL CHECK (report_type IN ('text', 'url', 'upi_id', 'qr', 'other')),
    description TEXT NOT NULL CHECK (length(description) BETWEEN 1 AND 2000),
    status      TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'reviewed', 'dismissed')),
    created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_sessions_user      ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_user      ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_upi       ON accounts(upi_id);
CREATE INDEX IF NOT EXISTS idx_login_user         ON login_history(user_id);
CREATE INDEX IF NOT EXISTS idx_analysis_user_time ON analysis_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_user      ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_user       ON reports(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_sender ON transactions(sender_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver ON transactions(receiver_user_id, created_at DESC);
