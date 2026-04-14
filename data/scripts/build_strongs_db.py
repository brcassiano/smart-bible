"""
ETL script to build strongs.db from openscriptures/strongs XML and
scrollmapper/bible_databases cross-references.

Usage:
    uv run python build_strongs_db.py
"""

import sqlite3
from pathlib import Path

from lxml import etree

RAW_DIR = Path(__file__).parent.parent / "raw"
PROCESSED_DIR = Path(__file__).parent.parent / "processed"
DB_PATH = PROCESSED_DIR / "strongs.db"

GREEK_XML = (
    RAW_DIR
    / "strongs"
    / "greek"
    / "StrongsGreekDictionaryXML_1.4"
    / "strongsgreek.xml"
)
HEBREW_XML = RAW_DIR / "strongs" / "hebrew" / "StrongHebrewG.xml"

# The scrollmapper repo contains multiple chunked cross-reference DBs.
XREF_DB_DIR = RAW_DIR / "bible_databases" / "formats" / "sqlite" / "extras"


def create_schema(conn: sqlite3.Connection) -> None:
    print("Creating schema...")
    conn.executescript("""
        DROP TABLE IF EXISTS cross_references;
        DROP TABLE IF EXISTS greek_lexicon;
        DROP TABLE IF EXISTS hebrew_lexicon;

        CREATE TABLE hebrew_lexicon (
            strongs_number   TEXT PRIMARY KEY,
            original_word    TEXT,
            transliteration  TEXT,
            pronunciation    TEXT,
            short_definition TEXT,
            full_definition  TEXT,
            part_of_speech   TEXT
        );

        CREATE TABLE greek_lexicon (
            strongs_number   TEXT PRIMARY KEY,
            original_word    TEXT,
            transliteration  TEXT,
            pronunciation    TEXT,
            short_definition TEXT,
            full_definition  TEXT,
            part_of_speech   TEXT
        );

        CREATE TABLE cross_references (
            id           INTEGER PRIMARY KEY,
            from_book    INTEGER NOT NULL,
            from_chapter INTEGER NOT NULL,
            from_verse   INTEGER NOT NULL,
            to_book      INTEGER NOT NULL,
            to_chapter   INTEGER NOT NULL,
            to_verse     INTEGER NOT NULL,
            votes        INTEGER DEFAULT 0
        );

        CREATE INDEX IF NOT EXISTS idx_xref_from
            ON cross_references (from_book, from_chapter, from_verse);
    """)
    conn.commit()


# ---------------------------------------------------------------------------
# Book name -> integer mapping (KJV canonical order 1..66) used by the
# scrollmapper cross-reference tables which store book names as text.
# ---------------------------------------------------------------------------
BOOK_NAME_TO_ID: dict[str, int] = {
    "Genesis": 1, "Exodus": 2, "Leviticus": 3, "Numbers": 4, "Deuteronomy": 5,
    "Joshua": 6, "Judges": 7, "Ruth": 8, "1 Samuel": 9, "2 Samuel": 10,
    "1 Kings": 11, "2 Kings": 12, "1 Chronicles": 13, "2 Chronicles": 14,
    "Ezra": 15, "Nehemiah": 16, "Esther": 17, "Job": 18, "Psalms": 19,
    "Proverbs": 20, "Ecclesiastes": 21, "Song of Solomon": 22, "Isaiah": 23,
    "Jeremiah": 24, "Lamentations": 25, "Ezekiel": 26, "Daniel": 27,
    "Hosea": 28, "Joel": 29, "Amos": 30, "Obadiah": 31, "Jonah": 32,
    "Micah": 33, "Nahum": 34, "Habakkuk": 35, "Zephaniah": 36, "Haggai": 37,
    "Zechariah": 38, "Malachi": 39, "Matthew": 40, "Mark": 41, "Luke": 42,
    "John": 43, "Acts": 44, "Romans": 45, "1 Corinthians": 46,
    "2 Corinthians": 47, "Galatians": 48, "Ephesians": 49, "Philippians": 50,
    "Colossians": 51, "1 Thessalonians": 52, "2 Thessalonians": 53,
    "1 Timothy": 54, "2 Timothy": 55, "Titus": 56, "Philemon": 57,
    "Hebrews": 58, "James": 59, "1 Peter": 60, "2 Peter": 61,
    "1 John": 62, "2 John": 63, "3 John": 64, "Jude": 65, "Revelation": 66,
}


def _text_of(element: etree._Element, strip: bool = True) -> str:
    """Return all text content of an element, including tail text of children."""
    parts = [element.text or ""]
    for child in element:
        parts.append(child.text or "")
        parts.append(child.tail or "")
    result = "".join(parts)
    return result.strip() if strip else result


def import_greek_lexicon(conn: sqlite3.Connection) -> int:
    if not GREEK_XML.exists():
        print(f"  WARNING: {GREEK_XML} not found, skipping Greek lexicon")
        return 0

    print(f"  Parsing Greek XML from {GREEK_XML.name}...")
    tree = etree.parse(str(GREEK_XML))
    root = tree.getroot()
    entries = root.findall(".//entry")

    rows: list[tuple] = []
    for entry in entries:
        raw_num = entry.get("strongs", "").lstrip("0")
        if not raw_num:
            continue
        strongs_number = f"G{raw_num}"

        greek_el = entry.find("greek")
        original_word = greek_el.get("unicode", "") if greek_el is not None else ""
        transliteration = greek_el.get("translit", "") if greek_el is not None else ""

        pronunciation_el = entry.find("pronunciation")
        pronunciation = (
            pronunciation_el.get("strongs", "") if pronunciation_el is not None else ""
        )

        # short definition from kjv_def; full from strongs_def + strongs_derivation
        kjv_el = entry.find("kjv_def")
        short_def = _text_of(kjv_el) if kjv_el is not None else ""

        def_parts: list[str] = []
        deriv_el = entry.find("strongs_derivation")
        if deriv_el is not None:
            def_parts.append(_text_of(deriv_el))
        def_el = entry.find("strongs_def")
        if def_el is not None:
            def_parts.append(_text_of(def_el))
        full_def = " ".join(p for p in def_parts if p)

        rows.append(
            (
                strongs_number,
                original_word,
                transliteration,
                pronunciation,
                short_def,
                full_def,
                "",  # part_of_speech not available in this XML
            )
        )

    conn.executemany(
        "INSERT INTO greek_lexicon "
        "(strongs_number, original_word, transliteration, pronunciation, "
        "short_definition, full_definition, part_of_speech) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)",
        rows,
    )
    conn.commit()
    count = len(rows)
    print(f"  Inserted {count:,} Greek lexicon entries")
    return count


def import_hebrew_lexicon(conn: sqlite3.Connection) -> int:
    if not HEBREW_XML.exists():
        print(f"  WARNING: {HEBREW_XML} not found, skipping Hebrew lexicon")
        return 0

    print(f"  Parsing Hebrew XML from {HEBREW_XML.name}...")
    tree = etree.parse(str(HEBREW_XML))
    root = tree.getroot()
    ns = {"osis": "http://www.bibletechnologies.net/2003/OSIS/namespace"}

    entries = root.findall('.//osis:div[@type="entry"]', ns)

    rows: list[tuple] = []
    for entry in entries:
        w_el = entry.find("osis:w", ns)
        if w_el is None:
            continue

        strongs_number = w_el.get("ID", "")
        if not strongs_number:
            continue

        original_word = (w_el.text or "").strip()
        transliteration = w_el.get("xlit", "")
        pronunciation = w_el.get("POS", "")  # POS attr holds pronunciation in this XML
        part_of_speech = w_el.get("morph", "")

        # Full definition: join all <item> text elements
        items = entry.findall(".//osis:item", ns)
        full_def = "; ".join((it.text or "").strip() for it in items if it.text)

        # Short definition from note[@type='translation']
        note_el = entry.find('.//osis:note[@type="translation"]', ns)
        short_def = (note_el.text or "").strip() if note_el is not None else ""
        if not short_def and items:
            # Fall back to first item
            short_def = (items[0].text or "").strip()

        rows.append(
            (
                strongs_number,
                original_word,
                transliteration,
                pronunciation,
                short_def,
                full_def,
                part_of_speech,
            )
        )

    conn.executemany(
        "INSERT INTO hebrew_lexicon "
        "(strongs_number, original_word, transliteration, pronunciation, "
        "short_definition, full_definition, part_of_speech) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)",
        rows,
    )
    conn.commit()
    count = len(rows)
    print(f"  Inserted {count:,} Hebrew lexicon entries")
    return count


def import_cross_references(conn: sqlite3.Connection) -> int:
    """Merge all chunked cross-reference DBs from scrollmapper."""
    xref_dbs = sorted(XREF_DB_DIR.glob("cross_references_*.db"))
    if not xref_dbs:
        print(f"  WARNING: No cross-reference DBs found in {XREF_DB_DIR}")
        return 0

    print(f"  Found {len(xref_dbs)} cross-reference DB files")

    rows: list[tuple] = []
    seen: set[tuple] = set()

    for db_path in xref_dbs:
        src = sqlite3.connect(db_path)
        for (
            from_book_name,
            from_chapter,
            from_verse,
            to_book_name,
            to_chapter,
            to_verse_start,
            _to_verse_end,
            votes,
        ) in src.execute(
            "SELECT from_book, from_chapter, from_verse, "
            "to_book, to_chapter, to_verse_start, to_verse_end, votes "
            "FROM cross_references"
        ):
            from_book_id = BOOK_NAME_TO_ID.get(from_book_name)
            to_book_id = BOOK_NAME_TO_ID.get(to_book_name)
            if from_book_id is None or to_book_id is None:
                continue

            key = (from_book_id, from_chapter, from_verse, to_book_id, to_chapter, to_verse_start)
            if key in seen:
                continue
            seen.add(key)

            rows.append(
                (from_book_id, from_chapter, from_verse, to_book_id, to_chapter, to_verse_start, votes or 0)
            )
        src.close()

    conn.executemany(
        "INSERT INTO cross_references "
        "(from_book, from_chapter, from_verse, to_book, to_chapter, to_verse, votes) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)",
        rows,
    )
    conn.commit()
    count = len(rows)
    print(f"  Inserted {count:,} cross-references")
    return count


def validate(conn: sqlite3.Connection) -> None:
    print("\n--- Validation ---")

    (hebrew_count,) = conn.execute("SELECT COUNT(*) FROM hebrew_lexicon").fetchone()
    (greek_count,) = conn.execute("SELECT COUNT(*) FROM greek_lexicon").fetchone()
    (xref_count,) = conn.execute("SELECT COUNT(*) FROM cross_references").fetchone()
    print(f"  Hebrew lexicon entries: {hebrew_count:,}")
    print(f"  Greek lexicon entries:  {greek_count:,}")
    print(f"  Cross-references:       {xref_count:,}")

    print("\n  H1 (Hebrew) spot-check:")
    row = conn.execute(
        "SELECT strongs_number, original_word, transliteration, short_definition "
        "FROM hebrew_lexicon WHERE strongs_number = 'H1'"
    ).fetchone()
    if row:
        print(f"    {row[0]} | {row[1]} | xlit={row[2]} | def={row[3][:60]}")
    else:
        print("    NOT FOUND")

    print("\n  G1 (Greek) spot-check:")
    row = conn.execute(
        "SELECT strongs_number, original_word, transliteration, short_definition "
        "FROM greek_lexicon WHERE strongs_number = 'G1'"
    ).fetchone()
    if row:
        print(f"    {row[0]} | {row[1]} | xlit={row[2]} | def={row[3][:60]}")
    else:
        print("    NOT FOUND")


def main() -> None:
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Building {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")

    create_schema(conn)

    print("\nImporting Greek lexicon...")
    import_greek_lexicon(conn)

    print("\nImporting Hebrew lexicon...")
    import_hebrew_lexicon(conn)

    print("\nImporting cross-references...")
    import_cross_references(conn)

    validate(conn)
    conn.close()

    size_mb = DB_PATH.stat().st_size / 1024 / 1024
    print(f"\nstrongs.db size: {size_mb:.2f} MB")
    print("Done.")


if __name__ == "__main__":
    main()
