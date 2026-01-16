from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager


DB_PATH = os.getenv("DB_PATH", os.path.join(os.path.dirname(__file__), "app.db"))


def init_db() -> None:
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS product_reviews (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              product_id TEXT NOT NULL,
              author_id TEXT NOT NULL,
              author_name TEXT NOT NULL,
              rating INTEGER NOT NULL,
              text TEXT,
              created_at TEXT NOT NULL
            )
            """
        )
        conn.execute("CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id ON product_reviews(product_id, id)")


@contextmanager
def db_conn():
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.row_factory = sqlite3.Row
        yield conn
        conn.commit()
    finally:
        conn.close()

