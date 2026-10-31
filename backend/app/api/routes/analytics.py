"""Analytics endpoints."""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends

from backend.app.database.connection import get_db
from backend.app.services.analytics_service import AnalyticsService

router = APIRouter()


@router.get("/analytics")
def analytics(db: sqlite3.Connection = Depends(get_db)):
    return AnalyticsService.get_summary(db)
