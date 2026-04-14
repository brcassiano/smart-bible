"""
ETL script to build bible.db from Portuguese (biblias) and KJV (bible_databases) sources.

Usage:
    uv run python build_bible_db.py
"""

import json
import sqlite3
import sys
from pathlib import Path

RAW_DIR = Path(__file__).parent.parent / "raw"
PROCESSED_DIR = Path(__file__).parent.parent / "processed"
DB_PATH = PROCESSED_DIR / "bible.db"

BIBLIAS_JSON_DIR = RAW_DIR / "biblias" / "inst" / "json"
KJV_DB_PATH = RAW_DIR / "bible_databases" / "formats" / "sqlite" / "KJV.db"

# Canonical book list: (name_en, name_pt_abbrev, testament, book_order, original_language)
# Book order follows the Protestant canon (66 books).
BOOK_METADATA = [
    ("Genesis", "Gn", "OT", 1, "he"),
    ("Exodus", "Êx", "OT", 2, "he"),
    ("Leviticus", "Lv", "OT", 3, "he"),
    ("Numbers", "Nm", "OT", 4, "he"),
    ("Deuteronomy", "Dt", "OT", 5, "he"),
    ("Joshua", "Js", "OT", 6, "he"),
    ("Judges", "Jz", "OT", 7, "he"),
    ("Ruth", "Rt", "OT", 8, "he"),
    ("1 Samuel", "1Sm", "OT", 9, "he"),
    ("2 Samuel", "2Sm", "OT", 10, "he"),
    ("1 Kings", "1Rs", "OT", 11, "he"),
    ("2 Kings", "2Rs", "OT", 12, "he"),
    ("1 Chronicles", "1Cr", "OT", 13, "he"),
    ("2 Chronicles", "2Cr", "OT", 14, "he"),
    ("Ezra", "Ed", "OT", 15, "he"),
    ("Nehemiah", "Ne", "OT", 16, "he"),
    ("Esther", "Et", "OT", 17, "he"),
    ("Job", "Jó", "OT", 18, "he"),
    ("Psalms", "Sl", "OT", 19, "he"),
    ("Proverbs", "Pv", "OT", 20, "he"),
    ("Ecclesiastes", "Ec", "OT", 21, "he"),
    ("Song of Solomon", "Ct", "OT", 22, "he"),
    ("Isaiah", "Is", "OT", 23, "he"),
    ("Jeremiah", "Jr", "OT", 24, "he"),
    ("Lamentations", "Lm", "OT", 25, "he"),
    ("Ezekiel", "Ez", "OT", 26, "he"),
    ("Daniel", "Dn", "OT", 27, "he"),
    ("Hosea", "Os", "OT", 28, "he"),
    ("Joel", "Jl", "OT", 29, "he"),
    ("Amos", "Am", "OT", 30, "he"),
    ("Obadiah", "Ab", "OT", 31, "he"),
    ("Jonah", "Jn", "OT", 32, "he"),
    ("Micah", "Mq", "OT", 33, "he"),
    ("Nahum", "Na", "OT", 34, "he"),
    ("Habakkuk", "Hc", "OT", 35, "he"),
    ("Zephaniah", "Sf", "OT", 36, "he"),
    ("Haggai", "Ag", "OT", 37, "he"),
    ("Zechariah", "Zc", "OT", 38, "he"),
    ("Malachi", "Ml", "OT", 39, "he"),
    ("Matthew", "Mt", "NT", 40, "el"),
    ("Mark", "Mc", "NT", 41, "el"),
    ("Luke", "Lc", "NT", 42, "el"),
    ("John", "Jo", "NT", 43, "el"),
    ("Acts", "At", "NT", 44, "el"),
    ("Romans", "Rm", "NT", 45, "el"),
    ("1 Corinthians", "1Co", "NT", 46, "el"),
    ("2 Corinthians", "2Co", "NT", 47, "el"),
    ("Galatians", "Gl", "NT", 48, "el"),
    ("Ephesians", "Ef", "NT", 49, "el"),
    ("Philippians", "Fp", "NT", 50, "el"),
    ("Colossians", "Cl", "NT", 51, "el"),
    ("1 Thessalonians", "1Ts", "NT", 52, "el"),
    ("2 Thessalonians", "2Ts", "NT", 53, "el"),
    ("1 Timothy", "1Tm", "NT", 54, "el"),
    ("2 Timothy", "2Tm", "NT", 55, "el"),
    ("Titus", "Tt", "NT", 56, "el"),
    ("Philemon", "Fm", "NT", 57, "el"),
    ("Hebrews", "Hb", "NT", 58, "el"),
    ("James", "Tg", "NT", 59, "el"),
    ("1 Peter", "1Pe", "NT", 60, "el"),
    ("2 Peter", "2Pe", "NT", 61, "el"),
    ("1 John", "1Jo", "NT", 62, "el"),
    ("2 John", "2Jo", "NT", 63, "el"),
    ("3 John", "3Jo", "NT", 64, "el"),
    ("Jude", "Jd", "NT", 65, "el"),
    ("Revelation", "Ap", "NT", 66, "el"),
]

PT_TRANSLATIONS = [
    ("ACF", "Almeida Corrigida e Fiel", "pt", "Almeida Corrigida e Fiel (1994), SBTB"),
    ("ARA", "Almeida Revista e Atualizada", "pt", "Almeida Revista e Atualizada (1993), SBB"),
]


def create_schema(conn: sqlite3.Connection) -> None:
    print("Creating schema...")
    conn.executescript("""
        DROP TABLE IF EXISTS verses;
        DROP TABLE IF EXISTS books;
        DROP TABLE IF EXISTS translations;

        CREATE TABLE translations (
            id          INTEGER PRIMARY KEY,
            abbreviation TEXT NOT NULL UNIQUE,
            name        TEXT NOT NULL,
            language    TEXT NOT NULL,
            description TEXT
        );

        CREATE TABLE books (
            id               INTEGER PRIMARY KEY,
            name             TEXT NOT NULL,
            name_pt          TEXT NOT NULL,
            testament        TEXT NOT NULL CHECK(testament IN ('OT', 'NT')),
            book_order       INTEGER NOT NULL UNIQUE,
            original_language TEXT NOT NULL CHECK(original_language IN ('he', 'el'))
        );

        CREATE TABLE verses (
            id             INTEGER PRIMARY KEY,
            translation_id INTEGER NOT NULL REFERENCES translations(id),
            book_id        INTEGER NOT NULL REFERENCES books(id),
            chapter        INTEGER NOT NULL,
            verse          INTEGER NOT NULL,
            text           TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_verses_lookup
            ON verses (translation_id, book_id, chapter, verse);
    """)
    conn.commit()


def populate_books(conn: sqlite3.Connection) -> dict[str, int]:
    """Insert canonical book list and return {name_en: book_id} mapping."""
    print("Populating books table...")
    book_id_by_name: dict[str, int] = {}
    for idx, (name, name_pt, testament, book_order, orig_lang) in enumerate(
        BOOK_METADATA, start=1
    ):
        conn.execute(
            "INSERT INTO books (id, name, name_pt, testament, book_order, original_language) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (idx, name, name_pt, testament, book_order, orig_lang),
        )
        book_id_by_name[name] = idx
    conn.commit()
    return book_id_by_name


def insert_translation(
    conn: sqlite3.Connection,
    abbreviation: str,
    name: str,
    language: str,
    description: str,
) -> int:
    cur = conn.execute(
        "INSERT INTO translations (abbreviation, name, language, description) "
        "VALUES (?, ?, ?, ?)",
        (abbreviation, name, language, description),
    )
    conn.commit()
    return cur.lastrowid  # type: ignore[return-value]


def import_portuguese_translation(
    conn: sqlite3.Connection,
    abbreviation: str,
    name: str,
    description: str,
    book_id_by_name: dict[str, int],
) -> int:
    """Import a Portuguese translation from the biblias JSON files."""
    json_path = BIBLIAS_JSON_DIR / f"{abbreviation}.json"
    if not json_path.exists():
        print(f"  WARNING: {json_path} not found, skipping {abbreviation}")
        return 0

    print(f"  Loading {abbreviation} from {json_path.name}...")
    with json_path.open(encoding="utf-8") as f:
        data = json.load(f)

    translation_id = insert_translation(conn, abbreviation, name, "pt", description)

    # data is a list of books; each book has 'abbrev' and 'chapters' (list of list of str)
    verse_count = 0
    rows: list[tuple] = []
    for book_idx, book_data in enumerate(data):
        book_id = book_idx + 1  # 1-indexed canonical order matches list position
        chapters = book_data.get("chapters", [])
        for chapter_idx, chapter_verses in enumerate(chapters, start=1):
            for verse_idx, verse_text in enumerate(chapter_verses, start=1):
                rows.append(
                    (translation_id, book_id, chapter_idx, verse_idx, verse_text)
                )
                verse_count += 1

    conn.executemany(
        "INSERT INTO verses (translation_id, book_id, chapter, verse, text) "
        "VALUES (?, ?, ?, ?, ?)",
        rows,
    )
    conn.commit()
    print(f"  Inserted {verse_count:,} verses for {abbreviation}")
    return verse_count


def import_kjv(
    conn: sqlite3.Connection,
    book_id_by_name: dict[str, int],
) -> int:
    """Import KJV from scrollmapper/bible_databases SQLite."""
    if not KJV_DB_PATH.exists():
        print(f"  WARNING: {KJV_DB_PATH} not found, skipping KJV")
        return 0

    print(f"  Loading KJV from {KJV_DB_PATH.name}...")
    translation_id = insert_translation(
        conn,
        "KJV",
        "King James Version",
        "en",
        "King James Version (1611)",
    )

    src = sqlite3.connect(KJV_DB_PATH)
    src_books = {
        row[0]: row[1]
        for row in src.execute("SELECT id, name FROM KJV_books ORDER BY id")
    }

    # Build KJV source book_id -> our canonical book_id
    # KJV books are in canonical order (1..66)
    kjv_to_canonical: dict[int, int] = {}
    for src_id, src_name in src_books.items():
        kjv_to_canonical[src_id] = src_id  # KJV order == canonical order

    rows: list[tuple] = []
    verse_count = 0
    for src_book_id, src_chapter, src_verse, text in src.execute(
        "SELECT book_id, chapter, verse, text FROM KJV_verses ORDER BY id"
    ):
        canonical_book_id = kjv_to_canonical.get(src_book_id)
        if canonical_book_id is None:
            continue
        rows.append((translation_id, canonical_book_id, src_chapter, src_verse, text))
        verse_count += 1

    src.close()

    conn.executemany(
        "INSERT INTO verses (translation_id, book_id, chapter, verse, text) "
        "VALUES (?, ?, ?, ?, ?)",
        rows,
    )
    conn.commit()
    print(f"  Inserted {verse_count:,} verses for KJV")
    return verse_count


def validate(conn: sqlite3.Connection) -> None:
    print("\n--- Validation ---")

    # Verse counts per translation
    for row in conn.execute(
        "SELECT t.abbreviation, COUNT(*) FROM verses v "
        "JOIN translations t ON t.id = v.translation_id "
        "GROUP BY t.id ORDER BY t.id"
    ):
        print(f"  {row[0]}: {row[1]:,} verses")

    # Spot-check Genesis 1:1
    print("\n  Genesis 1:1 spot-checks:")
    for row in conn.execute(
        "SELECT t.abbreviation, v.text FROM verses v "
        "JOIN translations t ON t.id = v.translation_id "
        "JOIN books b ON b.id = v.book_id "
        "WHERE b.book_order = 1 AND v.chapter = 1 AND v.verse = 1 "
        "ORDER BY t.id"
    ):
        print(f"    [{row[0]}] {row[1][:80]}")

    # Spot-check John 3:16
    print("\n  John 3:16 spot-checks:")
    for row in conn.execute(
        "SELECT t.abbreviation, v.text FROM verses v "
        "JOIN translations t ON t.id = v.translation_id "
        "JOIN books b ON b.id = v.book_id "
        "WHERE b.book_order = 43 AND v.chapter = 3 AND v.verse = 16 "
        "ORDER BY t.id"
    ):
        print(f"    [{row[0]}] {row[1][:80]}")


def main() -> None:
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Building {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")

    create_schema(conn)
    book_id_by_name = populate_books(conn)

    print("\nImporting Portuguese translations...")
    for abbrev, name, lang, desc in PT_TRANSLATIONS:
        import_portuguese_translation(conn, abbrev, name, desc, book_id_by_name)

    print("\nImporting KJV...")
    import_kjv(conn, book_id_by_name)

    validate(conn)
    conn.close()

    size_mb = DB_PATH.stat().st_size / 1024 / 1024
    print(f"\nbible.db size: {size_mb:.2f} MB")
    print("Done.")


if __name__ == "__main__":
    main()
