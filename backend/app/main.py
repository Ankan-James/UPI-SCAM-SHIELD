"""FastAPI entry point for the Numpe Scam Shield backend."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from backend.app.api.routes.analytics import router as analytics_router
from backend.app.api.routes.analyze import router as analyze_router
from backend.app.api.routes.auth import router as auth_router
from backend.app.api.routes.history import router as history_router
from backend.app.api.routes.payments import router as payments_router
from backend.app.api.routes.reports import router as reports_router
from backend.app.api.routes.security import router as security_router
from backend.app.api.routes.voice import router as voice_router
from backend.app.config import settings
from backend.app.database.connection import engine, init_db

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    init_db()
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_frontend_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


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
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        logger.exception("Database health check failed")
        raise HTTPException(
            status_code=503,
            detail="Database unavailable",
        ) from exc
    return {"status": "ok"}
