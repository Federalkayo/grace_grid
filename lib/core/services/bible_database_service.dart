import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class BibleBook {
  final String bookId;
  final String name;
  final String nameYoruba;
  final String testament; // OT or NT
  final int orderIndex;
  final int chapterCount;

  BibleBook({
    required this.bookId,
    required this.name,
    required this.nameYoruba,
    required this.testament,
    required this.orderIndex,
    required this.chapterCount,
  });

  factory BibleBook.fromMap(Map<String, dynamic> map) {
    return BibleBook(
      bookId: map['book_id'] as String,
      name: map['name'] as String,
      nameYoruba: map['name_yoruba'] as String? ?? map['name'] as String,
      testament: map['testament'] as String,
      orderIndex: map['order_index'] as int,
      chapterCount: map['chapter_count'] as int? ?? 1,
    );
  }

  String displayName(String translation) {
    if (translation.toUpperCase() == 'YOR') {
      return nameYoruba;
    }
    return name;
  }
}

class SermonNoteItem {
  final int? id;
  final String sermonTitle;
  final String speakerName;
  final String noteTitle;
  final String content;
  final String scriptureRef;
  final String timestampStr;
  final int createdAt;
  final String? audioPath;

  SermonNoteItem({
    this.id,
    required this.sermonTitle,
    required this.speakerName,
    required this.noteTitle,
    required this.content,
    required this.scriptureRef,
    required this.timestampStr,
    required this.createdAt,
    this.audioPath,
  });

  factory SermonNoteItem.fromMap(Map<String, dynamic> map) {
    return SermonNoteItem(
      id: map['id'] as int?,
      sermonTitle: map['sermon_title'] as String? ?? 'Sermon Reflection',
      speakerName: map['speaker_name'] as String? ?? 'Pastor',
      noteTitle: map['note_title'] as String? ?? 'Key Takeaway',
      content: map['content'] as String? ?? '',
      scriptureRef: map['scripture_ref'] as String? ?? '',
      timestampStr: map['timestamp_str'] as String? ?? '00:00:00',
      createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      audioPath: map['audio_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sermon_title': sermonTitle,
      'speaker_name': speakerName,
      'note_title': noteTitle,
      'content': content,
      'scripture_ref': scriptureRef,
      'timestamp_str': timestampStr,
      'created_at': createdAt,
      'audio_path': audioPath,
    };
  }
}

class BibleVerse {
  final int id;
  final String translation;
  final String bookId;
  final int chapter;
  final int verse;
  final String text;
  final bool isHighlighted;
  final int? highlightColor;
  final bool isBookmarked;
  final bool isDirectReferenceMatch;

  BibleVerse({
    required this.id,
    required this.translation,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    this.isHighlighted = false,
    this.highlightColor,
    this.isBookmarked = false,
    this.isDirectReferenceMatch = false,
  });

  BibleVerse copyWith({
    bool? isHighlighted,
    int? highlightColor,
    bool? isBookmarked,
    bool? isDirectReferenceMatch,
  }) {
    return BibleVerse(
      id: id,
      translation: translation,
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      text: text,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      highlightColor: highlightColor ?? this.highlightColor,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isDirectReferenceMatch: isDirectReferenceMatch ?? this.isDirectReferenceMatch,
    );
  }

  factory BibleVerse.fromMap(
    Map<String, dynamic> map, {
    bool isHighlighted = false,
    int? highlightColor,
    bool isBookmarked = false,
    bool isDirectReferenceMatch = false,
  }) {
    return BibleVerse(
      id: map['id'] as int,
      translation: map['translation'] as String,
      bookId: map['book_id'] as String,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      text: map['text'] as String,
      isHighlighted: isHighlighted,
      highlightColor: highlightColor,
      isBookmarked: isBookmarked,
      isDirectReferenceMatch: isDirectReferenceMatch,
    );
  }
}

class BibleTranslationInfo {
  final String code;
  final String name;

  const BibleTranslationInfo({
    required this.code,
    required this.name,
  });
}

class ReferenceMatch {
  final String bookId;
  final int chapter;
  final int? verse;

  ReferenceMatch({
    required this.bookId,
    required this.chapter,
    this.verse,
  });
}

class BibleDatabaseService {
  static final BibleDatabaseService _instance = BibleDatabaseService._internal();
  factory BibleDatabaseService() => _instance;
  BibleDatabaseService._internal();

  Database? _db;

  static const List<BibleTranslationInfo> supportedTranslations = [
    BibleTranslationInfo(code: 'KJV', name: 'King James Version'),
    BibleTranslationInfo(code: 'ASV', name: 'American Standard Version'),
    BibleTranslationInfo(code: 'WEB', name: 'World English Bible'),
    BibleTranslationInfo(code: 'YOR', name: 'Bibeli Mimo (Yoruba)'),
  ];

  // Web Fallback In-Memory Storage
  final List<SermonNoteItem> _webSermonNotes = [
    SermonNoteItem(
      id: 1,
      sermonTitle: 'Abiding in the Vine & Sacred Fellowship',
      speakerName: 'Pastor Kaleb',
      noteTitle: 'Pruning as Divine Favor',
      content: 'Pruning is not punishment; it is the Father freeing us from distraction to bear greater eternal fruit.',
      scriptureRef: 'John 15:2',
      timestampStr: '00:03:15',
      createdAt: DateTime.now().millisecondsSinceEpoch - 300000,
    ),
    SermonNoteItem(
      id: 2,
      sermonTitle: 'Abiding in the Vine & Sacred Fellowship',
      speakerName: 'Pastor Kaleb',
      noteTitle: 'The Organic Connection',
      content: 'We do not generate life ourselves—we simply stay attached to the true source through daily prayer.',
      scriptureRef: 'John 15:5',
      timestampStr: '00:08:40',
      createdAt: DateTime.now().millisecondsSinceEpoch - 200000,
    ),
  ];

  final Map<String, int> _webHighlights = {};
  final Set<String> _webBookmarks = {};

  static final List<BibleBook> _webBooks = [
    BibleBook(bookId: 'GEN', name: 'Genesis', nameYoruba: 'Genesi', testament: 'OT', orderIndex: 1, chapterCount: 50),
    BibleBook(bookId: 'EXO', name: 'Exodus', nameYoruba: 'Eksodu', testament: 'OT', orderIndex: 2, chapterCount: 40),
    BibleBook(bookId: 'PSA', name: 'Psalms', nameYoruba: 'Awọn Orin Dafidi', testament: 'OT', orderIndex: 19, chapterCount: 150),
    BibleBook(bookId: 'MAT', name: 'Matthew', nameYoruba: 'Matteu', testament: 'NT', orderIndex: 40, chapterCount: 28),
    BibleBook(bookId: 'JHN', name: 'John', nameYoruba: 'Johanu', testament: 'NT', orderIndex: 43, chapterCount: 21),
    BibleBook(bookId: 'ACT', name: 'Acts', nameYoruba: 'Awọn Iṣẹ', testament: 'NT', orderIndex: 44, chapterCount: 28),
    BibleBook(bookId: 'ROM', name: 'Romans', nameYoruba: 'Ara Roma', testament: 'NT', orderIndex: 45, chapterCount: 16),
  ];

  static const Map<String, String> bookAbbreviations = {
    'gen': 'GEN', 'genesis': 'GEN', 'genesi': 'GEN',
    'ex': 'EXO', 'exo': 'EXO', 'exodus': 'EXO', 'eksodu': 'EXO',
    'ps': 'PSA', 'psalm': 'PSA', 'psalms': 'PSA', 'orin dafidi': 'PSA',
    'matt': 'MAT', 'mt': 'MAT', 'matthew': 'MAT', 'matteu': 'MAT',
    'john': 'JHN', 'jn': 'JHN', 'johanu': 'JHN',
    'acts': 'ACT', 'iṣẹ': 'ACT',
    'rom': 'ROM', 'romans': 'ROM', 'roma': 'ROM',
  };

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite binary database asset not supported on web.');
    }

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'bibles.db');

    final exists = await File(dbPath).exists();

    if (!exists) {
      try {
        await Directory(dirname(dbPath)).create(recursive: true);
        ByteData data = await rootBundle.load('assets/bibles/bibles.db');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(dbPath).writeAsBytes(bytes, flush: true);
      } catch (e) {
        debugPrint('Error copying bibles.db asset: $e');
      }
    }

    final db = await openDatabase(dbPath);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_sermon_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sermon_title TEXT,
        speaker_name TEXT,
        note_title TEXT,
        content TEXT,
        scripture_ref TEXT,
        timestamp_str TEXT,
        created_at INTEGER,
        audio_path TEXT
      )
    ''');
    try {
      await db.execute('ALTER TABLE user_sermon_notes ADD COLUMN audio_path TEXT;');
    } catch (_) {}
    return db;
  }

  Future<List<BibleBook>> getBooks({String? testament}) async {
    if (kIsWeb) {
      if (testament != null) {
        return _webBooks.where((b) => b.testament == testament.toUpperCase()).toList();
      }
      return _webBooks;
    }

    final db = await database;
    String query = 'SELECT * FROM books';
    List<dynamic> args = [];

    if (testament != null) {
      query += ' WHERE testament = ?';
      args.add(testament.toUpperCase());
    }

    query += ' ORDER BY order_index ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return maps.map((m) => BibleBook.fromMap(m)).toList();
  }

  Future<BibleBook?> getBookById(String bookId) async {
    if (kIsWeb) {
      final matches = _webBooks.where((b) => b.bookId.toUpperCase() == bookId.toUpperCase());
      return matches.isNotEmpty ? matches.first : _webBooks.first;
    }

    final db = await database;
    final maps = await db.query(
      'books',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return BibleBook.fromMap(maps.first);
    }
    return null;
  }

  Future<List<BibleVerse>> getVerses({
    required String translation,
    required String bookId,
    required int chapter,
  }) async {
    if (kIsWeb) {
      return _getWebVerses(translation, bookId, chapter);
    }

    final db = await database;
    final maps = await db.query(
      'verses',
      where: 'translation = ? AND book_id = ? AND chapter = ?',
      whereArgs: [translation.toUpperCase(), bookId, chapter],
      orderBy: 'verse ASC',
    );

    final highlightsMap = await _getHighlightsMap(translation, bookId, chapter);
    final bookmarksSet = await _getBookmarksSet(translation, bookId, chapter);

    return maps.map((m) {
      final verseNum = m['verse'] as int;
      final highlightColor = highlightsMap[verseNum];
      final isBookmarked = bookmarksSet.contains(verseNum);

      return BibleVerse.fromMap(
        m,
        isHighlighted: highlightColor != null,
        highlightColor: highlightColor,
        isBookmarked: isBookmarked,
      );
    }).toList();
  }

  Future<int> getVerseCount({
    required String translation,
    required String bookId,
    required int chapter,
  }) async {
    if (kIsWeb) return 15;

    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM verses WHERE translation = ? AND book_id = ? AND chapter = ?',
      [translation.toUpperCase(), bookId, chapter],
    );
    if (res.isNotEmpty) {
      return (res.first['count'] as int?) ?? 1;
    }
    return 1;
  }

  ReferenceMatch? parseReferenceQuery(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return null;

    final regExp = RegExp(r'^([1-3]?\s?[A-Za-zṢṣỌọẸẹÌìÓóỤụ\s]+?)\s*(\d+)(?::(\d+))?$', caseSensitive: false);
    final match = regExp.firstMatch(clean);

    if (match != null) {
      final bookPart = match.group(1)?.trim().toLowerCase() ?? '';
      final chapterPart = int.tryParse(match.group(2) ?? '');
      final versePart = match.group(3) != null ? int.tryParse(match.group(3)!) : null;

      if (chapterPart == null) return null;

      String? matchedBookId = bookAbbreviations[bookPart];

      if (matchedBookId == null) {
        final compact = bookPart.replaceAll(' ', '');
        matchedBookId = bookAbbreviations[compact];
      }

      if (matchedBookId != null) {
        return ReferenceMatch(
          bookId: matchedBookId,
          chapter: chapterPart,
          verse: versePart,
        );
      }
    }

    return null;
  }

  Future<List<BibleVerse>> searchVerses({
    required String translation,
    required String query,
    int limit = 50,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    if (kIsWeb) {
      return _getWebVerses(translation, 'JHN', 15);
    }

    final db = await database;
    final results = <BibleVerse>[];
    final addedVerseKeys = <String>{};

    final refMatch = parseReferenceQuery(clean);
    if (refMatch != null) {
      if (refMatch.verse != null) {
        final maps = await db.query(
          'verses',
          where: 'translation = ? AND book_id = ? AND chapter = ? AND verse = ?',
          whereArgs: [translation.toUpperCase(), refMatch.bookId, refMatch.chapter, refMatch.verse],
        );
        for (final m in maps) {
          final key = '${m['translation']}_${m['book_id']}_${m['chapter']}_${m['verse']}';
          if (!addedVerseKeys.contains(key)) {
            addedVerseKeys.add(key);
            results.add(BibleVerse.fromMap(m, isDirectReferenceMatch: true));
          }
        }
      } else {
        final maps = await db.query(
          'verses',
          where: 'translation = ? AND book_id = ? AND chapter = ?',
          whereArgs: [translation.toUpperCase(), refMatch.bookId, refMatch.chapter],
          orderBy: 'verse ASC',
          limit: limit,
        );
        for (final m in maps) {
          final key = '${m['translation']}_${m['book_id']}_${m['chapter']}_${m['verse']}';
          if (!addedVerseKeys.contains(key)) {
            addedVerseKeys.add(key);
            results.add(BibleVerse.fromMap(m, isDirectReferenceMatch: true));
          }
        }
      }
    }

    final maps = await db.query(
      'verses',
      where: 'translation = ? AND text LIKE ?',
      whereArgs: [translation.toUpperCase(), '%$clean%'],
      orderBy: 'book_id ASC, chapter ASC, verse ASC',
      limit: limit,
    );

    for (final m in maps) {
      final key = '${m['translation']}_${m['book_id']}_${m['chapter']}_${m['verse']}';
      if (!addedVerseKeys.contains(key)) {
        addedVerseKeys.add(key);
        results.add(BibleVerse.fromMap(m));
      }
    }

    return results;
  }

  Future<BibleVerse?> getRandomDailyVerse(String translation) async {
    if (kIsWeb) {
      return BibleVerse(
        id: 1,
        translation: translation,
        bookId: 'JHN',
        chapter: 15,
        verse: 5,
        text: 'I am the vine, you are the branches. He who abides in Me, and I in him, bears much fruit; for without Me you can do nothing.',
      );
    }

    final db = await database;
    final maps = await db.query(
      'verses',
      where: 'translation = ? AND book_id = ? AND chapter = ? AND verse = ?',
      whereArgs: [translation.toUpperCase(), 'JHN', 3, 16],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return BibleVerse.fromMap(maps.first);
    }

    return null;
  }

  Future<Map<int, int>> _getHighlightsMap(String translation, String bookId, int chapter) async {
    if (kIsWeb) {
      final res = <int, int>{};
      _webHighlights.forEach((key, color) {
        final parts = key.split('_');
        if (parts.length == 4 && parts[0] == translation.toUpperCase() && parts[1] == bookId && parts[2] == chapter.toString()) {
          res[int.parse(parts[3])] = color;
        }
      });
      return res;
    }
    final db = await database;
    final maps = await db.query(
      'user_highlights',
      where: 'translation = ? AND book_id = ? AND chapter = ?',
      whereArgs: [translation.toUpperCase(), bookId, chapter],
    );

    final result = <int, int>{};
    for (final m in maps) {
      result[m['verse'] as int] = m['color'] as int;
    }
    return result;
  }

  Future<Set<int>> _getBookmarksSet(String translation, String bookId, int chapter) async {
    if (kIsWeb) {
      final res = <int>{};
      for (final key in _webBookmarks) {
        final parts = key.split('_');
        if (parts.length == 4 && parts[0] == translation.toUpperCase() && parts[1] == bookId && parts[2] == chapter.toString()) {
          res.add(int.parse(parts[3]));
        }
      }
      return res;
    }
    final db = await database;
    final maps = await db.query(
      'user_bookmarks',
      where: 'translation = ? AND book_id = ? AND chapter = ?',
      whereArgs: [translation.toUpperCase(), bookId, chapter],
    );

    return maps.map((m) => m['verse'] as int).toSet();
  }

  Future<void> toggleHighlight({
    required String translation,
    required String bookId,
    required int chapter,
    required int verse,
    required int color,
  }) async {
    if (kIsWeb) {
      final key = '${translation.toUpperCase()}_${bookId}_${chapter}_$verse';
      if (_webHighlights.containsKey(key)) {
        _webHighlights.remove(key);
      } else {
        _webHighlights[key] = color;
      }
      return;
    }
    final db = await database;
    final existing = await db.query(
      'user_highlights',
      where: 'translation = ? AND book_id = ? AND chapter = ? AND verse = ?',
      whereArgs: [translation.toUpperCase(), bookId, chapter, verse],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'user_highlights',
        where: 'translation = ? AND book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: [translation.toUpperCase(), bookId, chapter, verse],
      );
    } else {
      await db.insert('user_highlights', {
        'translation': translation.toUpperCase(),
        'book_id': bookId,
        'chapter': chapter,
        'verse': verse,
        'color': color,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> toggleBookmark({
    required String translation,
    required String bookId,
    required int chapter,
    required int verse,
  }) async {
    if (kIsWeb) {
      final key = '${translation.toUpperCase()}_${bookId}_${chapter}_$verse';
      if (_webBookmarks.contains(key)) {
        _webBookmarks.remove(key);
      } else {
        _webBookmarks.add(key);
      }
      return;
    }
    final db = await database;
    final existing = await db.query(
      'user_bookmarks',
      where: 'translation = ? AND book_id = ? AND chapter = ? AND verse = ?',
      whereArgs: [translation.toUpperCase(), bookId, chapter, verse],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'user_bookmarks',
        where: 'translation = ? AND book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: [translation.toUpperCase(), bookId, chapter, verse],
      );
    } else {
      await db.insert('user_bookmarks', {
        'translation': translation.toUpperCase(),
        'book_id': bookId,
        'chapter': chapter,
        'verse': verse,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<List<BibleVerse>> getBookmarks() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.rawQuery('''
      SELECT COALESCE(v.id, 0) as id, b.translation, b.book_id, b.chapter, b.verse, v.text, b.created_at
      FROM user_bookmarks b
      LEFT JOIN verses v ON b.translation = v.translation AND b.book_id = v.book_id AND b.chapter = v.chapter AND b.verse = v.verse
      ORDER BY b.created_at DESC
    ''');

    return results.map((row) {
      return BibleVerse(
        id: row['id'] as int,
        translation: row['translation'] as String,
        bookId: row['book_id'] as String,
        chapter: row['chapter'] as int,
        verse: row['verse'] as int,
        text: (row['text'] as String?) ?? '',
        isBookmarked: true,
      );
    }).toList();
  }

  // --- Sermon Notes ---

  Future<List<SermonNoteItem>> getSermonNotes() async {
    if (kIsWeb) {
      return List.from(_webSermonNotes);
    }

    final db = await database;
    final results = await db.query(
      'user_sermon_notes',
      orderBy: 'created_at DESC',
    );

    return results.map((map) => SermonNoteItem.fromMap(map)).toList();
  }

  Future<int> addSermonNote(SermonNoteItem note) async {
    if (kIsWeb) {
      final newNote = SermonNoteItem(
        id: _webSermonNotes.length + 1,
        sermonTitle: note.sermonTitle,
        speakerName: note.speakerName,
        noteTitle: note.noteTitle,
        content: note.content,
        scriptureRef: note.scriptureRef,
        timestampStr: note.timestampStr,
        createdAt: note.createdAt,
        audioPath: note.audioPath,
      );
      _webSermonNotes.insert(0, newNote);
      return newNote.id!;
    }

    final db = await database;
    return await db.insert('user_sermon_notes', note.toMap());
  }

  Future<int> updateSermonNote(SermonNoteItem note) async {
    if (kIsWeb) return 1;
    if (note.id == null) return 0;
    final db = await database;
    return await db.update(
      'user_sermon_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteSermonNote(int id) async {
    if (kIsWeb) {
      _webSermonNotes.removeWhere((item) => item.id == id);
      return 1;
    }
    final db = await database;
    return await db.delete(
      'user_sermon_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  List<BibleVerse> _getWebVerses(String translation, String bookId, int chapter) {
    return [
      BibleVerse(id: 1, translation: translation, bookId: bookId, chapter: chapter, verse: 1, text: 'I am the true vine, and my Father is the vinedresser.'),
      BibleVerse(id: 2, translation: translation, bookId: bookId, chapter: chapter, verse: 2, text: 'Every branch in me that doesn’t bear fruit, he takes away. Every branch that bears fruit, he prunes, that it may bear more fruit.'),
      BibleVerse(id: 3, translation: translation, bookId: bookId, chapter: chapter, verse: 3, text: 'You are already pruned because of the word which I have spoken to you.'),
      BibleVerse(id: 4, translation: translation, bookId: bookId, chapter: chapter, verse: 4, text: 'Remain in me, and I in you. As the branch cannot bear fruit of itself unless it remains in the vine, so neither can you unless you remain in me.', isHighlighted: true),
      BibleVerse(id: 5, translation: translation, bookId: bookId, chapter: chapter, verse: 5, text: 'I am the vine. You are the branches. He who remains in me, and I in him, bears much fruit; for apart from me you can do nothing.', isHighlighted: true),
      BibleVerse(id: 6, translation: translation, bookId: bookId, chapter: chapter, verse: 6, text: 'If anyone doesn’t remain in me, he is thrown out as a branch, and is withered; and they gather them, throw them into the fire, and they are burned.'),
      BibleVerse(id: 7, translation: translation, bookId: bookId, chapter: chapter, verse: 7, text: 'If you remain in me, and my words remain in you, you will ask whatever you desire, and it will be done for you.'),
      BibleVerse(id: 8, translation: translation, bookId: bookId, chapter: chapter, verse: 8, text: 'In this my Father is glorified, that you bear much fruit; and so you will be my disciples.'),
    ];
  }
}
