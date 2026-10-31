-- Add a display name while preserving user_id/username for existing clients.
ALTER TABLE users ADD COLUMN name TEXT NOT NULL DEFAULT '';
UPDATE users SET name = username WHERE name = '';
