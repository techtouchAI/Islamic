"""Check the bundled SQLite search contract before compiling the app."""

from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parents[1] / "assets" / "data"


def verify_quran() -> None:
    with sqlite3.connect(ROOT / "quran_db.db") as db:
        columns = {row[1] for row in db.execute("PRAGMA table_info(ayah)")}
        assert {"sid", "anum", "text", "ar_text"} <= columns
        rows = db.execute(
            "SELECT a.sid, a.anum FROM ayah a JOIN surah s ON a.sid = s.id "
            "WHERE a.ar_text LIKE ? ESCAPE '\\' OR s.name LIKE ? ESCAPE '\\' "
            "ORDER BY a.sid, a.anum",
            ("%الرحمن%", "%الرحمن%"),
        ).fetchall()
        assert len(rows) > 50, "Search must not truncate results to 50"
        assert rows == sorted(rows)


def verify_mafatih() -> None:
    with sqlite3.connect(ROOT / "maftiha.ar2.db") as db:
        columns = {row[1] for row in db.execute("PRAGMA table_info(articles)")}
        assert {"id", "title", "text"} <= columns
        rows = db.execute(
            "SELECT id FROM articles WHERE title LIKE ? ESCAPE '\\' "
            "OR text LIKE ? ESCAPE '\\' ORDER BY id",
            ("%الله%", "%الله%"),
        ).fetchall()
        assert len(rows) > 50, "Search must not truncate results to 50"
        assert rows == sorted(rows)


if __name__ == "__main__":
    verify_quran()
    verify_mafatih()
    print("Bundled SQLite search contract OK")
