# Backend setup

The backend uses the repository's root `requirements.txt` so the FastAPI
service and the scam-analysis agent share one Python environment.

## Install

From the repository root, create and activate a virtual environment, then
install dependencies:

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item backend\.env.example .env
```

Set `SECRET_KEY` in `.env` to a unique random value before using the service
outside local development. `DATABASE_PATH` defaults to the ignored SQLite
database under `backend\data`.

## Initialize and run

Run the schema migration and start the API from the repository root:

```powershell
alembic -c alembic.ini upgrade head
python -m uvicorn backend.app.main:app --reload
```

The bootstrap migration initializes the canonical SQLite schema. Alembic
autogeneration is intentionally deferred until the existing ORM declarations
are aligned with that schema.

The interactive API reference is available at `http://127.0.0.1:8000/docs`;
the health endpoint is `http://127.0.0.1:8000/health`.

## Tests

```powershell
python -m pytest backend\tests -q
```