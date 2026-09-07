import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/bible_database_service.dart';

class BibleState {
  final String selectedTranslation;
  final String selectedBookId;
  final BibleBook? selectedBook;
  final int selectedChapter;
  final int? targetVerseNumber;
  final double fontSize;
  final String themeMode;
  final List<BibleBook> books;
  final List<BibleVerse> verses;
  final bool isLoading;
  final String searchQuery;
  final List<BibleVerse> searchResults;
  final bool isSearching;
  final BibleVerse? activeSelectedVerse;

  BibleState({
    this.selectedTranslation = 'KJV',
    this.selectedBookId = 'JHN',
    this.selectedBook,
    this.selectedChapter = 3,
    this.targetVerseNumber,
    this.fontSize = 21.0,
    this.themeMode = 'Sanctuary Dark',
    this.books = const [],
    this.verses = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.activeSelectedVerse,
  });

  BibleState copyWith({
    String? selectedTranslation,
    String? selectedBookId,
    BibleBook? selectedBook,
    int? selectedChapter,
    int? targetVerseNumber,
    bool clearTargetVerseNumber = false,
    double? fontSize,
    String? themeMode,
    List<BibleBook>? books,
    List<BibleVerse>? verses,
    bool? isLoading,
    String? searchQuery,
    List<BibleVerse>? searchResults,
    bool? isSearching,
    BibleVerse? activeSelectedVerse,
    bool clearSelectedVerse = false,
  }) {
    return BibleState(
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
      selectedBookId: selectedBookId ?? this.selectedBookId,
      selectedBook: selectedBook ?? this.selectedBook,
      selectedChapter: selectedChapter ?? this.selectedChapter,
      targetVerseNumber: clearTargetVerseNumber ? null : (targetVerseNumber ?? this.targetVerseNumber),
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
      books: books ?? this.books,
      verses: verses ?? this.verses,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      activeSelectedVerse: clearSelectedVerse ? null : (activeSelectedVerse ?? this.activeSelectedVerse),
    );
  }
}

class BibleNotifier extends StateNotifier<BibleState> {
  final BibleDatabaseService _dbService = BibleDatabaseService();

  BibleNotifier() : super(BibleState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final books = await _dbService.getBooks();
      final currentBook = books.firstWhere(
        (b) => b.bookId == state.selectedBookId,
        orElse: () => books.first,
      );

      final verses = await _dbService.getVerses(
        translation: state.selectedTranslation,
        bookId: currentBook.bookId,
        chapter: state.selectedChapter,
      );

      state = state.copyWith(
        books: books,
        selectedBook: currentBook,
        selectedBookId: currentBook.bookId,
        verses: verses,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('BibleNotifier init error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setTranslation(String translation) async {
    if (state.selectedTranslation == translation) return;
    state = state.copyWith(selectedTranslation: translation, isLoading: true);
    await _loadCurrentChapter();
  }

  Future<void> setBook(String bookId, {int chapter = 1, int? verse}) async {
    final book = state.books.firstWhere(
      (b) => b.bookId == bookId,
      orElse: () => state.books.first,
    );

    state = state.copyWith(
      selectedBookId: bookId,
      selectedBook: book,
      selectedChapter: chapter,
      targetVerseNumber: verse,
      clearTargetVerseNumber: verse == null,
      isLoading: true,
    );
    await _loadCurrentChapter();
  }

  Future<void> setChapter(int chapter, {int? verse}) async {
    state = state.copyWith(
      selectedChapter: chapter,
      targetVerseNumber: verse,
      clearTargetVerseNumber: verse == null,
      isLoading: true,
    );
    await _loadCurrentChapter();
  }

  Future<void> nextChapter() async {
    final currentBook = state.selectedBook;
    if (currentBook == null) return;

    if (state.selectedChapter < currentBook.chapterCount) {
      await setChapter(state.selectedChapter + 1);
    } else {
      final idx = state.books.indexWhere((b) => b.bookId == state.selectedBookId);
      if (idx != -1 && idx < state.books.length - 1) {
        final nextBook = state.books[idx + 1];
        await setBook(nextBook.bookId, chapter: 1);
      }
    }
  }

  Future<void> previousChapter() async {
    final currentBook = state.selectedBook;
    if (currentBook == null) return;

    if (state.selectedChapter > 1) {
      await setChapter(state.selectedChapter - 1);
    } else {
      final idx = state.books.indexWhere((b) => b.bookId == state.selectedBookId);
      if (idx > 0) {
        final prevBook = state.books[idx - 1];
        await setBook(prevBook.bookId, chapter: prevBook.chapterCount);
      }
    }
  }

  Future<void> _loadCurrentChapter() async {
    try {
      final verses = await _dbService.getVerses(
        translation: state.selectedTranslation,
        bookId: state.selectedBookId,
        chapter: state.selectedChapter,
      );
      state = state.copyWith(verses: verses, isLoading: false);
    } catch (e) {
      debugPrint('_loadCurrentChapter error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void setThemeMode(String theme) {
    state = state.copyWith(themeMode: theme);
  }

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      state = state.copyWith(searchQuery: '', searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(searchQuery: clean, isSearching: true);
    try {
      final results = await _dbService.searchVerses(
        translation: state.selectedTranslation,
        query: clean,
      );
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      debugPrint('Search error: $e');
      state = state.copyWith(isSearching: false);
    }
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', searchResults: [], isSearching: false);
  }

  Future<void> toggleHighlight(BibleVerse verse, int colorHex) async {
    await _dbService.toggleHighlight(
      translation: verse.translation,
      bookId: verse.bookId,
      chapter: verse.chapter,
      verse: verse.verse,
      color: colorHex,
    );
    await _loadCurrentChapter();
  }

  Future<void> toggleBookmark(BibleVerse verse) async {
    await _dbService.toggleBookmark(
      translation: verse.translation,
      bookId: verse.bookId,
      chapter: verse.chapter,
      verse: verse.verse,
    );
    await _loadCurrentChapter();
  }

  Future<List<BibleVerse>> getBookmarks() async {
    return await _dbService.getBookmarks();
  }

  void selectVerse(BibleVerse? verse) {
    state = state.copyWith(activeSelectedVerse: verse, clearSelectedVerse: verse == null);
  }
}

final bibleProvider = StateNotifierProvider<BibleNotifier, BibleState>((ref) {
  return BibleNotifier();
});
