import os
import sys
import json
import sqlite3
import urllib.request
import time
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '..'))
OUTPUT_DB_PATH = os.path.join(PROJECT_ROOT, 'assets', 'bibles', 'bibles.db')
CACHE_DIR = os.path.join(SCRIPT_DIR, 'bible_raw_data')

os.makedirs(CACHE_DIR, exist_ok=True)

BOOK_METADATA = [
    # (book_id, name, name_yoruba, testament, order_index, TehShrike_json_filename)
    ('GEN', 'Genesis', 'Genesisi', 'OT', 1, 'genesis.json'),
    ('EXO', 'Exodus', 'Eksodu', 'OT', 2, 'exodus.json'),
    ('LEV', 'Leviticus', 'Lefitiku', 'OT', 3, 'leviticus.json'),
    ('NUM', 'Numbers', 'Numeri', 'OT', 4, 'numbers.json'),
    ('DEU', 'Deuteronomy', 'Deuteronomi', 'OT', 5, 'deuteronomy.json'),
    ('JSH', 'Joshua', 'Joṣua', 'OT', 6, 'joshua.json'),
    ('JDG', 'Judges', 'Onidajọ', 'OT', 7, 'judges.json'),
    ('RUT', 'Ruth', 'Rutu', 'OT', 8, 'ruth.json'),
    ('1SA', '1 Samuel', '1 Samueli', 'OT', 9, '1samuel.json'),
    ('2SA', '2 Samuel', '2 Samueli', 'OT', 10, '2samuel.json'),
    ('1KI', '1 Kings', '1 Ọba', 'OT', 11, '1kings.json'),
    ('2KI', '2 Kings', '2 Ọba', 'OT', 12, '2kings.json'),
    ('1CH', '1 Chronicles', '1 Kronika', 'OT', 13, '1chronicles.json'),
    ('2CH', '2 Chronicles', '2 Kronika', 'OT', 14, '2chronicles.json'),
    ('EZR', 'Ezra', 'Esra', 'OT', 15, 'ezra.json'),
    ('NEH', 'Nehemiah', 'Nehemiah', 'OT', 16, 'nehemiah.json'),
    ('EST', 'Esther', 'Esteri', 'OT', 17, 'esther.json'),
    ('JOB', 'Job', 'Jobu', 'OT', 18, 'job.json'),
    ('PSA', 'Psalms', 'Psalmu', 'OT', 19, 'psalms.json'),
    ('PRO', 'Proverbs', 'Owe', 'OT', 20, 'proverbs.json'),
    ('ECC', 'Ecclesiastes', 'Oniwasu', 'OT', 21, 'ecclesiastes.json'),
    ('SNG', 'Song of Solomon', 'Orin Solomoni', 'OT', 22, 'songofsolomon.json'),
    ('ISA', 'Isaiah', 'Isaiah', 'OT', 23, 'isaiah.json'),
    ('JER', 'Jeremiah', 'Jeremiah', 'OT', 24, 'jeremiah.json'),
    ('LAM', 'Lamentations', 'Ekun Jeremiah', 'OT', 25, 'lamentations.json'),
    ('EZK', 'Ezekiel', 'Esekieli', 'OT', 26, 'ezekiel.json'),
    ('DAN', 'Daniel', 'Danieli', 'OT', 27, 'daniel.json'),
    ('HOS', 'Hosea', 'Hosea', 'OT', 28, 'hosea.json'),
    ('JOL', 'Joel', 'Joeli', 'OT', 29, 'joel.json'),
    ('AMO', 'Amos', 'Amosi', 'OT', 30, 'amos.json'),
    ('OBA', 'Obadiah', 'Obadiah', 'OT', 31, 'obadiah.json'),
    ('JON', 'Jonah', 'Jonasi', 'OT', 32, 'jonah.json'),
    ('MIC', 'Micah', 'Mika', 'OT', 33, 'micah.json'),
    ('NAM', 'Nahum', 'Nahumu', 'OT', 34, 'nahum.json'),
    ('HAB', 'Habakkuk', 'Habakkuku', 'OT', 35, 'habakkuk.json'),
    ('ZEP', 'Zephaniah', 'Sefaniah', 'OT', 36, 'zephaniah.json'),
    ('HAG', 'Haggai', 'Haggai', 'OT', 37, 'haggai.json'),
    ('ZEC', 'Zechariah', 'Sekariah', 'OT', 38, 'zechariah.json'),
    ('MAL', 'Malachi', 'Malaki', 'OT', 39, 'malachi.json'),
    # New Testament
    ('MAT', 'Matthew', 'Matteu', 'NT', 40, 'matthew.json'),
    ('MRK', 'Mark', 'Marku', 'NT', 41, 'mark.json'),
    ('LUK', 'Luke', 'Luku', 'NT', 42, 'luke.json'),
    ('JHN', 'John', 'Johanu', 'NT', 43, 'john.json'),
    ('ACT', 'Acts', 'Awọn Iṣẹ', 'NT', 44, 'acts.json'),
    ('ROM', 'Romans', 'Ara Roma', 'NT', 45, 'romans.json'),
    ('1CO', '1 Corinthians', '1 Ara Korinti', 'NT', 46, '1corinthians.json'),
    ('2CO', '2 Corinthians', '2 Ara Korinti', 'NT', 47, '2corinthians.json'),
    ('GAL', 'Galatians', 'Ara Galatia', 'NT', 48, 'galatians.json'),
    ('EPH', 'Ephesians', 'Ara Efesu', 'NT', 49, 'ephesians.json'),
    ('PHP', 'Philippians', 'Ara Filipi', 'NT', 50, 'philippians.json'),
    ('COL', 'Colossians', 'Ara Kolosse', 'NT', 51, 'colossians.json'),
    ('1TH', '1 Thessalonians', '1 Ara Tessalonika', 'NT', 52, '1thessalonians.json'),
    ('2TH', '2 Thessalonians', '2 Ara Tessalonika', 'NT', 53, '2thessalonians.json'),
    ('1TI', '1 Timothy', '1 Timotiu', 'NT', 54, '1timothy.json'),
    ('2TI', '2 Timothy', '2 Timotiu', 'NT', 55, '2timothy.json'),
    ('TIT', 'Titus', 'Titu', 'NT', 56, 'titus.json'),
    ('PHM', 'Philemon', 'Filemoni', 'NT', 57, 'philemon.json'),
    ('HEB', 'Hebrews', 'Awọn Heberu', 'NT', 58, 'hebrews.json'),
    ('JAS', 'James', 'Jakobu', 'NT', 59, 'james.json'),
    ('1PE', '1 Peter', '1 Peteru', 'NT', 60, '1peter.json'),
    ('2PE', '2 Peter', '2 Peteru', 'NT', 61, '2peter.json'),
    ('1JN', '1 John', '1 Johanu', 'NT', 62, '1john.json'),
    ('2JN', '2 John', '2 Johanu', 'NT', 63, '2john.json'),
    ('3JN', '3 John', '3 Johanu', 'NT', 64, '3john.json'),
    ('JUD', 'Jude', 'Juda', 'NT', 65, 'jude.json'),
    ('REV', 'Revelation', 'Iṣipaya', 'NT', 66, 'revelation.json'),
]

BOOK_MAP_BY_NUM = {idx + 1: b[0] for idx, b in enumerate(BOOK_METADATA)}

def fetch_url(url, cache_filename):
    cache_path = os.path.join(CACHE_DIR, cache_filename)
    if os.path.exists(cache_path) and os.path.getsize(cache_path) > 0:
        with open(cache_path, 'r', encoding='utf-8') as f:
            return f.read()

    print(f"Fetching {url}...")
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                content = resp.read().decode('utf-8', errors='ignore')
                with open(cache_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return content
        except Exception as e:
            print(f"Attempt {attempt+1} failed for {url}: {e}")
            time.sleep(2)
    raise RuntimeError(f"Failed to fetch {url}")

def build_database():
    os.makedirs(os.path.dirname(OUTPUT_DB_PATH), exist_ok=True)
    if os.path.exists(OUTPUT_DB_PATH):
        os.remove(OUTPUT_DB_PATH)

    conn = sqlite3.connect(OUTPUT_DB_PATH)
    cursor = conn.cursor()

    # Create tables
    cursor.execute("""
        CREATE TABLE books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            name_yoruba TEXT NOT NULL,
            testament TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            chapter_count INTEGER DEFAULT 0
        );
    """)

    cursor.execute("""
        CREATE TABLE verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            translation TEXT NOT NULL,
            book_id TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            text TEXT NOT NULL,
            FOREIGN KEY(book_id) REFERENCES books(book_id)
        );
    """)

    cursor.execute("""
        CREATE TABLE user_bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            translation TEXT NOT NULL,
            book_id TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            created_at INTEGER NOT NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE user_highlights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            translation TEXT NOT NULL,
            book_id TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            color INTEGER NOT NULL,
            created_at INTEGER NOT NULL
        );
    """)

    # Populate books
    for book_id, name, name_yoruba, testament, order_idx, _ in BOOK_METADATA:
        cursor.execute(
            "INSERT INTO books (book_id, name, name_yoruba, testament, order_index) VALUES (?, ?, ?, ?, ?)",
            (book_id, name, name_yoruba, testament, order_idx)
        )

    # 1. Process KJV & ASV (from bibleapi-bibles-json)
    for code, filename in [('KJV', 'kjv.json'), ('ASV', 'asv.json')]:
        url = f"https://raw.githubusercontent.com/bibleapi/bibleapi-bibles-json/master/{filename}"
        raw = fetch_url(url, f"{code.lower()}.json")
        data = json.loads(raw)
        
        verses_to_insert = []
        book_chapter_max = {}
        
        rows = data.get('resultset', {}).get('row', [])
        for row in rows:
            fields = row.get('field', [])
            if len(fields) >= 5:
                # field[1] = b_num (1..66), field[2] = ch, field[3] = verse, field[4] = text
                b_num = fields[1]
                ch = fields[2]
                v = fields[3]
                text = str(fields[4]).strip()
                
                b_id = BOOK_MAP_BY_NUM.get(b_num)
                if b_id and text:
                    verses_to_insert.append((code, b_id, ch, v, text))
                    if b_id not in book_chapter_max or ch > book_chapter_max[b_id]:
                        book_chapter_max[b_id] = ch
                            
        cursor.executemany(
            "INSERT INTO verses (translation, book_id, chapter, verse, text) VALUES (?, ?, ?, ?, ?)",
            verses_to_insert
        )
        print(f"✓ Inserted {len(verses_to_insert)} verses for {code}.")
        
        # Update chapter_count in books table
        for b_id, ch_cnt in book_chapter_max.items():
            cursor.execute("UPDATE books SET chapter_count = ? WHERE book_id = ?", (ch_cnt, b_id))

    # 2. Process WEB (from TehShrike/world-english-bible)
    print("Processing WEB translation...")
    web_verses = []
    for book_id, name, name_yoruba, testament, order_idx, web_json_file in BOOK_METADATA:
        url = f"https://raw.githubusercontent.com/TehShrike/world-english-bible/master/json/{web_json_file}"
        raw = fetch_url(url, f"web_{web_json_file}")
        data = json.loads(raw)
        if isinstance(data, list):
            for item in data:
                if isinstance(item, dict) and item.get('type') == 'paragraph text':
                    ch = item.get('chapterNumber')
                    v = item.get('verseNumber')
                    txt = item.get('value', '').strip()
                    if ch and v and txt:
                        web_verses.append(('WEB', book_id, int(ch), int(v), txt))

    cursor.executemany(
        "INSERT INTO verses (translation, book_id, chapter, verse, text) VALUES (?, ?, ?, ?, ?)",
        web_verses
    )
    print(f"✓ Inserted {len(web_verses)} verses for WEB.")

    # 3. Process Yoruba Bible (YOR)
    print("Processing Yoruba (YOR) translation...")
    yor_url = "https://raw.githubusercontent.com/gray-adeyi/pygconverter/master/Yoruba%20bible.txt"
    raw_yor = fetch_url(yor_url, "yoruba_bible.txt")

    # NOTE on this parser (rewritten — the previous version silently
    # corrupted ~17 of 66 books):
    #
    # 1. Heading detection previously used a hand-picked whitelist of
    #    accented characters (e.g. Ẹ/ẹ, Ọ/ọ) that didn't cover every
    #    Yoruba tone mark actually used in the source (e.g. 'ú', 'à').
    #    Any chapter heading containing an uncovered character — like
    #    "Ẹkún" (Lamentations) — silently failed to match at all, so its
    #    verses got misattributed into whatever book/chapter was last
    #    recognized. Fixed by using \D (Unicode-aware "not a digit")
    #    for the title portion instead of a whitelist, with the leading
    #    "1"/"2"/"3" numeral (for books like "1 Korinti") captured
    #    separately since \D would otherwise exclude it too.
    #
    # 2. Book-name matching previously used substring containment
    #    (`y_name in b_title`), scanned in book order. Short names could
    #    match inside unrelated longer ones — e.g. "Orin" (Song of
    #    Solomon) is a literal substring of "Korinti" (Corinthians), so
    #    both books of Corinthians got silently absorbed into Song of
    #    Solomon. Fixed with exact (normalized, case-insensitive) title
    #    matching against a ground-truth table built by scanning every
    #    real heading in the source once, rather than guessing spellings.
    #
    # 3. The book-index line at the very top of the file (e.g.
    #    "|Old Testament| Genesisi Eksodu ... 1 Samueli 2 Samueli ...")
    #    contains "<number> <word>" pairs that the verse regex would
    #    happily parse as extra verses before any real heading had been
    #    seen. Fixed by not collecting verses until the first real
    #    chapter heading has been matched.

    HEADING_RE = re.compile(r'^(?:([1-3])\s)?(\D{2,40}?)\s+(\d{1,3})$')
    VERSE_RE = re.compile(r'(?:^|\s)(\d+)\s+([^0-9]+?)(?=\s+\d+\s+|$)')

    # Ground truth: scan every heading-shaped line once, segment into
    # books by chapter-number resets, and take the (single, consistent)
    # title text actually used per book — rather than guessing spellings.
    all_headings = []
    for line in raw_yor.splitlines():
        line_s = line.strip()
        if not line_s:
            continue
        m = HEADING_RE.match(line_s)
        if m:
            num_prefix, title, ch_num = m.groups()
            full_title = f"{num_prefix} {title.strip()}" if num_prefix else title.strip()
            all_headings.append((full_title, int(ch_num)))

    book_order = [b[0] for b in BOOK_METADATA]
    title_by_book = {}
    book_idx = -1
    prev_ch = None
    for title, ch in all_headings:
        if prev_ch is None or ch == 1:
            book_idx += 1
        prev_ch = ch
        if book_idx < len(book_order):
            title_by_book.setdefault(book_order[book_idx], title)
    bid_by_title = {v.lower(): k for k, v in title_by_book.items()}

    assert len(title_by_book) == 66, f"Expected to detect 66 books in YOR source, found {len(title_by_book)}"

    yor_verses = []
    curr_b_id, curr_ch = None, None
    started = False

    for line in raw_yor.splitlines():
        line_s = line.strip()
        if not line_s:
            continue
        m = HEADING_RE.match(line_s)
        if m:
            num_prefix, title, ch_num = m.groups()
            full_title = f"{num_prefix} {title.strip()}" if num_prefix else title.strip()
            bid = bid_by_title.get(full_title.lower())
            if bid:
                curr_b_id, curr_ch = bid, int(ch_num)
                started = True
            continue
        if not started:
            continue  # skip preface/book-index content before the first real heading
        for vm in VERSE_RE.finditer(line_s):
            v_num = int(vm.group(1))
            v_text = vm.group(2).strip()
            if v_text and len(v_text) > 2:
                yor_verses.append(('YOR', curr_b_id, curr_ch, v_num, v_text))

    cursor.executemany(
        "INSERT INTO verses (translation, book_id, chapter, verse, text) VALUES (?, ?, ?, ?, ?)",
        yor_verses
    )
    print(f"✓ Inserted {len(yor_verses)} verses for YOR.")

    # Create Performance Indexes
    print("Creating SQLite indexes...")
    cursor.execute("CREATE INDEX idx_verses_lookup ON verses(translation, book_id, chapter, verse);")
    cursor.execute("CREATE INDEX idx_verses_book_ch ON verses(translation, book_id, chapter);")
    cursor.execute("CREATE INDEX idx_verses_text ON verses(translation, text);")

    conn.commit()

    # Verification Gate
    print("\n--- Running Verification Gate ---")
    cursor.execute("SELECT COUNT(*) FROM books")
    b_cnt = cursor.fetchone()[0]
    print(f"✓ Books Count: {b_cnt} (Expected 66)")
    assert b_cnt == 66, f"Expected 66 books, found {b_cnt}"

    for tr in ['KJV', 'ASV', 'WEB', 'YOR']:
        cursor.execute("SELECT COUNT(*) FROM verses WHERE translation = ? AND book_id = 'GEN' AND chapter = 1", (tr,))
        g1 = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM verses WHERE translation = ? AND book_id = 'JHN' AND chapter = 3", (tr,))
        j3 = cursor.fetchone()[0]
        print(f"✓ {tr} -> Gen 1: {g1} verses, John 3: {j3} verses")

    conn.close()
    print(f"\nSuccessfully built Bible database at: {OUTPUT_DB_PATH}")

if __name__ == '__main__':
    build_database()
