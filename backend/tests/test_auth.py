from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

from fastapi import FastAPI
from fastapi.testclient import TestClient

from backend.app.api.routes.auth import router
from backend.app.config import Settings, settings
from backend.app.database.connection import get_connection, get_db, init_db


class AuthApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.database_path = Path(self.temp_dir.name) / "auth-test.sqlite"
        init_db(self.database_path)

        app = FastAPI()
        app.include_router(router, prefix="/api")

        def override_get_db():
            conn = get_connection(self.database_path)
            try:
                yield conn
            finally:
                conn.close()

        app.dependency_overrides[get_db] = override_get_db
        self.client = TestClient(app)

    def tearDown(self) -> None:
        self.client.close()
        self.temp_dir.cleanup()

    def register(self, *, name: str = "Demo User", email: str = "demo@example.com"):
        return self.client.post(
            "/api/auth/register",
            json={"name": name, "email": email, "password": "safe-demo-passphrase"},
        )

    def test_registration_hashes_password_and_login_returns_session_user(self) -> None:
        registered = self.register()
        self.assertEqual(registered.status_code, 200)
        user = registered.json()["user"]
        self.assertEqual(user["name"], "Demo User")
        self.assertEqual(user["email"], "demo@example.com")

        conn = get_connection(self.database_path)
        try:
            row = conn.execute(
                "SELECT password_hash FROM users WHERE email = ?",
                ("demo@example.com",),
            ).fetchone()
        finally:
            conn.close()
        self.assertTrue(row["password_hash"].startswith("$2"))
        self.assertNotEqual(row["password_hash"], "safe-demo-passphrase")

        login = self.client.post(
            "/api/auth/login",
            json={"email": "DEMO@example.com", "password": "safe-demo-passphrase"},
        )
        self.assertEqual(login.status_code, 200)
        session = login.json()
        self.assertTrue(session["token"])
        self.assertEqual(session["user"]["name"], "Demo User")
        self.assertEqual(session["user"]["user_id"], user["user_id"])

        authorization = {"Authorization": f"Bearer {session['token']}"}
        self.assertEqual(self.client.get("/api/auth/me", headers=authorization).status_code, 200)
        self.assertEqual(self.client.post("/api/auth/logout", headers=authorization).status_code, 200)
        self.assertEqual(self.client.get("/api/auth/me", headers=authorization).status_code, 401)

    def test_duplicate_email_and_invalid_password_are_rejected(self) -> None:
        self.assertEqual(self.register().status_code, 200)
        duplicate = self.register(email="DEMO@example.com")
        self.assertEqual(duplicate.status_code, 409)
        self.assertIn("email", duplicate.json()["detail"])

        invalid_login = self.client.post(
            "/api/auth/login",
            json={"email": "demo@example.com", "password": "incorrect-password"},
        )
        self.assertEqual(invalid_login.status_code, 401)

    def test_cors_preflight_allows_local_website_origin(self) -> None:
        app = FastAPI()
        from fastapi.middleware.cors import CORSMiddleware

        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.allowed_frontend_origins,
            allow_methods=["*"],
            allow_headers=["*"],
        )
        app.include_router(router, prefix="/api")

        response = TestClient(app).options(
            "/api/auth/login",
            headers={
                "Origin": "http://127.0.0.1:5501",
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "content-type",
            },
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.headers["access-control-allow-origin"],
            "http://127.0.0.1:5501",
        )
        deployment_settings = Settings()
        deployment_settings.frontend_origin = "https://numpe.example, https://admin.example"
        self.assertIn("https://numpe.example", deployment_settings.allowed_frontend_origins)
        self.assertIn("https://admin.example", deployment_settings.allowed_frontend_origins)

    def test_existing_users_table_is_migrated_with_a_display_name(self) -> None:
        legacy_path = Path(self.temp_dir.name) / "legacy.sqlite"
        conn = sqlite3.connect(legacy_path)
        try:
            conn.execute(
                """
                CREATE TABLE users (
                    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT NOT NULL UNIQUE,
                    email TEXT NOT NULL UNIQUE COLLATE NOCASE,
                    password_hash TEXT NOT NULL,
                    created_at TEXT NOT NULL DEFAULT '2025-01-01T00:00:00Z'
                )
                """
            )
            conn.execute(
                "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
                ("legacy-user", "legacy@example.com", "existing-hash"),
            )
            conn.commit()
        finally:
            conn.close()

        init_db(legacy_path)
        conn = sqlite3.connect(legacy_path)
        try:
            row = conn.execute(
                "SELECT name FROM users WHERE email = ?",
                ("legacy@example.com",),
            ).fetchone()
        finally:
            conn.close()
        self.assertEqual(row[0], "legacy-user")


if __name__ == "__main__":
    unittest.main()
