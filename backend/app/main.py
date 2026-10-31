"""FastAPI entry point for the Numpe Scam Shield backend."""

from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.app.api.routes.analytics import router as analytics_router
from backend.app.api.routes.analyze import router as analyze_router
from backend.app.api.routes.auth import router as auth_router
from backend.app.api.routes.history import router as history_router
from backend.app.api.routes.payments import router as payments_router
from backend.app.api.routes.reports import router as reports_router
from backend.app.api.routes.security import router as security_router
from backend.app.api.routes.voice import router as voice_router
from backend.app.database.connection import init_db
from backend.app.config import settings

app = FastAPI(title="UPI Scam Shield API")
init_db()
frontend_origins = {
    "http://127.0.0.1:5501",
    "http://localhost:5501",
}
if settings.frontend_origin != "*":
    frontend_origins.update(
        origin.strip()
        for origin in settings.frontend_origin.split(",")
        if origin.strip()
    )
app.add_middleware(
    CORSMiddleware,
    allow_origins=sorted(frontend_origins),
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup_event() -> None:
    init_db()


app.include_router(auth_router, prefix="/api")
app.include_router(analyze_router, prefix="/api")
app.include_router(reports_router, prefix="/api")
app.include_router(payments_router, prefix="/api")
app.include_router(security_router, prefix="/api")
app.include_router(analytics_router, prefix="/api")
app.include_router(history_router, prefix="/api")
app.include_router(voice_router, prefix="/api")


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
