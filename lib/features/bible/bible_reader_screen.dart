import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/bible_database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import 'providers/bible_provider.dart';

class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bookSearchController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  int? _lastScrolledVerse;
  String? _lastScrolledBookChapter;
  String _bookSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _bookSearchController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _scrollToVerse(int verseNumber, [int retryCount = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = ref.read(bibleProvider);
      final verseIndex = state.verses.indexWhere((v) => v.verse == verseNumber);

      if (verseIndex >= 0 && _mainScrollController.hasClients) {
        final estimatedOffset = (160.0 + (verseIndex * 78.0)).clamp(
          0.0,
          _mainScrollController.position.maxScrollExtent,
        );
        _mainScrollController.animateTo(
          estimatedOffset,
          duration: Duration(milliseconds: retryCount == 0 ? 400 : 200),
          curve: Curves.easeInOutCubic,
        );
      }

      final key = _verseKeys[verseNumber];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: 0.12,
        );
      } else if (retryCount < 5) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _scrollToVerse(verseNumber, retryCount + 1);
        });
      }
    });
  }

  void _showBookChapterPickerSheet(BuildContext context, BibleState state) {
    _bookSearchController.clear();
    _bookSearchQuery = '';

    int currentStep = 0; // 0 = Select Book/Chapter, 1 = Select Verse
    BibleBook? selectedPickerBook = state.selectedBook;
    int selectedPickerChapter = state.selectedChapter;
    int pickerVerseCount = state.verses.isNotEmpty ? state.verses.length : 30;
    bool isLoadingVerses = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void onChapterTapped(BibleBook book, int chNum) async {
              setSheetState(() {
                selectedPickerBook = book;
                selectedPickerChapter = chNum;
                currentStep = 1; // Transition to verse selection view
                isLoadingVerses = true;
              });

              final vCount = await BibleDatabaseService().getVerseCount(
                translation: state.selectedTranslation,
                bookId: book.bookId,
                chapter: chNum,
              );

              setSheetState(() {
                pickerVerseCount = vCount;
                isLoadingVerses = false;
              });
            }

            return DefaultTabController(
              length: 2,
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  final filteredBooks = state.books.where((b) {
                    if (_bookSearchQuery.isEmpty) return true;
                    final q = _bookSearchQuery.toLowerCase();
                    return b.name.toLowerCase().contains(q) ||
                        b.nameYoruba.toLowerCase().contains(q) ||
                        b.bookId.toLowerCase().contains(q);
                  }).toList();

                  final otBooks = filteredBooks.where((b) => b.testament == 'OT').toList();
                  final ntBooks = filteredBooks.where((b) => b.testament == 'NT').toList();

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (currentStep == 1)
                              TextButton.icon(
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                icon: const Icon(Icons.arrow_back, size: 18, color: AppTheme.primaryContainer),
                                label: const Text(
                                  'Back to Chapters',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                                ),
                                onPressed: () {
                                  setSheetState(() => currentStep = 0);
                                },
                              )
                            else
                              Text(
                                'Select Book & Chapter',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // STEP 1: Select Book & Chapter View
                      if (currentStep == 0) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _bookSearchController,
                            decoration: InputDecoration(
                              hintText: 'Search books (e.g. Job, Psalms, Johanu)...',
                              prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.primaryContainer),
                              suffixIcon: _bookSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _bookSearchController.clear();
                                        setSheetState(() => _bookSearchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppTheme.surfaceLow,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.emeraldStrokeAlpha25),
                              ),
                            ),
                            onChanged: (val) {
                              setSheetState(() => _bookSearchQuery = val.trim());
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        TabBar(
                          indicatorColor: AppTheme.primaryContainer,
                          labelColor: AppTheme.primaryContainer,
                          unselectedLabelColor: AppTheme.onSurfaceVariant,
                          tabs: [
                            Tab(text: 'Old Testament (${otBooks.length})'),
                            Tab(text: 'New Testament (${ntBooks.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildBookGrid(
                                otBooks,
                                state,
                                scrollController,
                                selectedPickerBook?.bookId ?? state.selectedBookId,
                                onChapterTapped,
                              ),
                              _buildBookGrid(
                                ntBooks,
                                state,
                                scrollController,
                                selectedPickerBook?.bookId ?? state.selectedBookId,
                                onChapterTapped,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // STEP 2: Dedicated Select Verse View
                      if (currentStep == 1 && selectedPickerBook != null) ...[
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            children: [
                              GlassCard(
                                level: GlassLevel.level1,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      '${selectedPickerBook!.displayName(state.selectedTranslation)} Chapter $selectedPickerChapter',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${selectedPickerBook!.nameYoruba} • ${state.selectedTranslation}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.auto_stories, size: 18),
                                        label: Text('Read Entire Chapter $selectedPickerChapter'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryContainer,
                                          foregroundColor: AppTheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          ref.read(bibleProvider.notifier).setBook(
                                                selectedPickerBook!.bookId,
                                                chapter: selectedPickerChapter,
                                              );
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Select Verse to Jump To:',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  if (isLoadingVerses)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryContainer),
                                    )
                                  else
                                    Text(
                                      '$pickerVerseCount Verses',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (isLoadingVerses)
                                const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: List.generate(pickerVerseCount, (vIdx) {
                                    final vNum = vIdx + 1;
                                    return GestureDetector(
                                      onTap: () {
                                        ref.read(bibleProvider.notifier).setBook(
                                              selectedPickerBook!.bookId,
                                              chapter: selectedPickerChapter,
                                              verse: vNum,
                                            );
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceLow,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$vNum',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookGrid(
    List<BibleBook> books,
    BibleState state,
    ScrollController scrollController,
    String activePickerBookId,
    void Function(BibleBook book, int chNum) onChapterTapped,
  ) {
    if (books.isEmpty) {
      return const Center(
        child: Text('No books matched your search.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelectedBook = book.bookId == activePickerBookId;
        final bookName = book.displayName(state.selectedTranslation);

        return ExpansionTile(
          initiallyExpanded: isSelectedBook,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            bookName,
            style: TextStyle(
              fontWeight: isSelectedBook ? FontWeight.bold : FontWeight.w500,
              color: isSelectedBook ? AppTheme.primaryContainer : AppTheme.onSurface,
            ),
          ),
          subtitle: Text(
            '${book.chapterCount} Chapters • ${book.nameYoruba}',
            style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelectedBook
                  ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                  : AppTheme.surfaceHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${book.orderIndex}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelectedBook ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Chapter (${book.chapterCount}):',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(book.chapterCount, (chIdx) {
                      final chNum = chIdx + 1;

                      return GestureDetector(
                        onTap: () => onChapterTapped(book, chNum),
                        child: Container(
                          width: 44,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
                          ),
                          child: Center(
                            child: Text(
                              '$chNum',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSearchSheet(BuildContext context, BibleState state) {
    _searchController.text = state.searchQuery;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentState = ref.watch(bibleProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Scripture & Passage Search',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search passage (e.g. Job 1:4, John 3:16, grace)...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryContainer),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(bibleProvider.notifier).clearSearch();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.surfaceLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.emeraldStrokeAlpha25),
                          ),
                        ),
                        onSubmitted: (val) {
                          ref.read(bibleProvider.notifier).search(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (currentState.isSearching)
                        const Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: currentState.searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    currentState.searchQuery.isEmpty
                                        ? 'Try searching "Job 1:4", "John 3:16", or keywords'
                                        : 'No verses found for "${currentState.searchQuery}"',
                                    style: const TextStyle(color: AppTheme.onSurfaceVariant),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: currentState.searchResults.length,
                                  separatorBuilder: (context, index) => const Divider(color: AppTheme.emeraldStrokeAlpha15),
                                  itemBuilder: (context, idx) {
                                    final v = currentState.searchResults[idx];
                                    final book = currentState.books.firstWhere(
                                      (b) => b.bookId == v.bookId,
                                      orElse: () => BibleBook(
                                        bookId: v.bookId,
                                        name: v.bookId,
                                        nameYoruba: v.bookId,
                                        testament: 'OT',
                                        orderIndex: 0,
                                        chapterCount: 1,
                                      ),
                                    );
                                    final bookTitle = book.displayName(currentState.selectedTranslation);

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                      title: Row(
                                        children: [
                                          Text(
                                            '$bookTitle ${v.chapter}:${v.verse}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryContainer,
                                            ),
                                          ),
                                          if (v.isDirectReferenceMatch) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppTheme.primaryContainer),
                                              ),
                                              child: const Text(
                                                'REFERENCE MATCH',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          v.text,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.onSurface),
                                        ),
                                      ),
                                      onTap: () {
                                        ref.read(bibleProvider.notifier).setBook(v.bookId, chapter: v.chapter, verse: v.verse);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showReadingSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(bibleProvider);
            final notifier = ref.read(bibleProvider.notifier);

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading Settings',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),

                  // Font Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${state.fontSize.toInt()} pt', style: const TextStyle(color: AppTheme.primaryContainer)),
                    ],
                  ),
                  Slider(
                    value: state.fontSize,
                    min: 14,
                    max: 26,
                    activeColor: AppTheme.primaryContainer,
                    inactiveColor: AppTheme.outlineVariant,
                    onChanged: (val) => notifier.setFontSize(val),
                  ),
                  const SizedBox(height: 16),

                  // Reading Themes
                  const Text('Reading Canvas Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Sanctuary Dark', 'Sepia Glow', 'Obsidian Void'].map((theme) {
                      final isSel = state.themeMode == theme;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.setThemeMode(theme),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primaryContainer.withValues(alpha: 0.2) : AppTheme.surfaceLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? AppTheme.primaryContainer : AppTheme.emeraldStrokeAlpha15,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                theme,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVerseActionSheet(BuildContext context, BibleVerse verse, BibleState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bookName = state.selectedBook?.displayName(state.selectedTranslation) ?? verse.bookId;
        final refText = '$bookName ${verse.chapter}:${verse.verse} (${verse.translation})';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                refText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                verse.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),

              // Highlight Colors
              const Text('Highlight Verse', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  0xFF00E676, // Emerald
                  0xFFFFD54F, // Gold
                  0xFF64B5F6, // Celestial Blue
                  0xFFBA68C8, // Lavender
                  0xFFFF8A65, // Coral
                ].map((colorHex) {
                  return GestureDetector(
                    onTap: () {
                      ref.read(bibleProvider.notifier).toggleHighlight(verse, colorHex);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        verse.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: AppTheme.primaryContainer,
                      ),
                      label: Text(verse.isBookmarked ? 'Bookmarked' : 'Bookmark'),
                      onPressed: () {
                        ref.read(bibleProvider.notifier).toggleBookmark(verse);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Verse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: AppTheme.onPrimary,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '$refText\n"${verse.text}"'));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verse copied to clipboard!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookmarksSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return GlassCard(
              level: GlassLevel.level3,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return FutureBuilder<List<BibleVerse>>(
                    future: ref.read(bibleProvider.notifier).getBookmarks(),
                    builder: (context, snapshot) {
                      final bookmarks = snapshot.data ?? [];
                      final isLoading = snapshot.connectionState == ConnectionState.waiting;

                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(Icons.bookmark, color: AppTheme.primaryContainer, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Saved Bookmarks (${bookmarks.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppTheme.emeraldStrokeAlpha15),
                          Expanded(
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : bookmarks.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.bookmark_border, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'No saved bookmarks yet',
                                              style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Tap any verse in the reader to add a bookmark',
                                              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        controller: scrollController,
                                        padding: const EdgeInsets.all(16),
                                        itemCount: bookmarks.length,
                                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final verse = bookmarks[index];
                                          final state = ref.read(bibleProvider);
                                          final bookMatch = state.books.where((b) => b.bookId == verse.bookId);
                                          final bookTitle = bookMatch.isNotEmpty ? bookMatch.first.displayName(verse.translation) : verse.bookId;
                                          final reference = '$bookTitle ${verse.chapter}:${verse.verse}';

                                          return GlassCard(
                                            level: GlassLevel.level1,
                                            padding: const EdgeInsets.all(14),
                                            onTap: () {
                                              Navigator.pop(context);
                                              ref.read(bibleProvider.notifier).setBook(
                                                    verse.bookId,
                                                    chapter: verse.chapter,
                                                    verse: verse.verse,
                                                  );
                                            },
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            reference,
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.primaryContainer,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: AppTheme.surfaceContainer,
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              verse.translation,
                                                              style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        verse.text,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.bookmark, color: AppTheme.primaryContainer, size: 20),
                                                  onPressed: () async {
                                                    await ref.read(bibleProvider.notifier).toggleBookmark(verse);
                                                    setSheetState(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bibleProvider);
    final notifier = ref.read(bibleProvider.notifier);

    final currentBookChapter = '${state.selectedTranslation}_${state.selectedBookId}_${state.selectedChapter}';

    if (_lastScrolledBookChapter != currentBookChapter) {
      _verseKeys.clear();
      _lastScrolledBookChapter = currentBookChapter;
      _lastScrolledVerse = null;
      if (!state.isLoading && state.targetVerseNumber == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mainScrollController.hasClients) {
            _mainScrollController.jumpTo(0);
          }
        });
      }
    }

    if (!state.isLoading && state.targetVerseNumber != null) {
      if (_lastScrolledVerse != state.targetVerseNumber) {
        _lastScrolledVerse = state.targetVerseNumber;
        _scrollToVerse(state.targetVerseNumber!);
      }
    }

    Color canvasColor = AppTheme.background;
    if (state.themeMode == 'Sepia Glow') canvasColor = const Color(0xFF1B1612);
    if (state.themeMode == 'Obsidian Void') canvasColor = const Color(0xFF030504);

    final currentBookTitle = state.selectedBook?.displayName(state.selectedTranslation) ?? state.selectedBookId;

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow.withValues(alpha: 0.9),
        elevation: 0,
        titleSpacing: 8,
        title: GestureDetector(
          onTap: () => _showBookChapterPickerSheet(context, state),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '$currentBookTitle ${state.selectedChapter}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryContainer, size: 20),
            ],
          ),
        ),
        actions: [
          // Search Action
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant, size: 22),
            onPressed: () => _showSearchSheet(context, state),
          ),
          const SizedBox(width: 2),

          // Saved Bookmarks Action
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.bookmark_border, color: AppTheme.onSurfaceVariant, size: 22),
            tooltip: 'Saved Bookmarks',
            onPressed: () => _showBookmarksSheet(context),
          ),
          const SizedBox(width: 2),

          // Translation Picker Popup
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            initialValue: state.selectedTranslation,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
              ),
              child: Text(
                state.selectedTranslation,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ),
            color: AppTheme.surfaceHigh,
            onSelected: (val) => notifier.setTranslation(val),
            itemBuilder: (context) => BibleDatabaseService.supportedTranslations
                .map(
                  (t) => PopupMenuItem(
                    value: t.code,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.code, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer)),
                        Text(t.name, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 2),

          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.format_size, color: AppTheme.onSurfaceVariant, size: 22),
            onPressed: () => _showReadingSettingsSheet(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              controller: _mainScrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Header Status Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_done, size: 13, color: AppTheme.primaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            'Offline Multi-Bible • ${state.selectedTranslation}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${state.verses.length} Verses',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Chapter Title Card
                GlassCard(
                  level: GlassLevel.level1,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentBookTitle Chapter ${state.selectedChapter}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Deep Study & Meditation Mode (${state.selectedTranslation})',
                        style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Verses Render Loop
                ...state.verses.map((verse) {
                  final verseKey = _verseKeys.putIfAbsent(verse.verse, () => GlobalKey());
                  final isTargetVerse = state.targetVerseNumber == verse.verse;
                  final highlightBg = verse.isHighlighted
                      ? Color(verse.highlightColor ?? 0xFF00E676).withValues(alpha: 0.18)
                      : (isTargetVerse ? AppTheme.primaryContainer.withValues(alpha: 0.25) : null);

                  return Padding(
                    key: verseKey,
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: InkWell(
                      onTap: () => _showVerseActionSheet(context, verse, state),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: verse.isHighlighted || verse.isBookmarked || isTargetVerse
                            ? const EdgeInsets.all(12)
                            : const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: highlightBg,
                          borderRadius: BorderRadius.circular(12),
                          border: verse.isHighlighted
                              ? Border.all(color: Color(verse.highlightColor ?? 0xFF00E676))
                              : (isTargetVerse
                                  ? Border.all(color: AppTheme.primaryContainer, width: 1.5)
                                  : (verse.isBookmarked ? Border.all(color: AppTheme.emeraldStrokeAlpha25) : null)),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8, top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: verse.isBookmarked || isTargetVerse
                                        ? AppTheme.primaryContainer
                                        : AppTheme.surfaceHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${verse.verse}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: verse.isBookmarked || isTargetVerse ? AppTheme.onPrimary : AppTheme.primaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: verse.text,
                                style: AppTheme.scriptureStyle.copyWith(
                                  fontSize: state.fontSize,
                                  height: 1.65,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),

          // Floating Bottom Chapter Navigation Controls (< on left edge, > on right edge, middle is completely free)
          Positioned(
            left: 16,
            bottom: 24,
            child: GlassCard(
              level: GlassLevel.level2,
              borderRadius: BorderRadius.circular(99),
              padding: const EdgeInsets.all(14),
              onTap: () => notifier.previousChapter(),
              child: const Icon(Icons.chevron_left, color: AppTheme.primaryContainer, size: 28),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: GlassCard(
              level: GlassLevel.level2,
              borderRadius: BorderRadius.circular(99),
              padding: const EdgeInsets.all(14),
              onTap: () => notifier.nextChapter(),
              child: const Icon(Icons.chevron_right, color: AppTheme.primaryContainer, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
