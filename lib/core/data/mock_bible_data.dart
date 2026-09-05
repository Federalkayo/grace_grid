class BibleVerse {
  final int verseNumber;
  final String text;
  final bool isHighlighted;

  const BibleVerse({
    required this.verseNumber,
    required this.text,
    this.isHighlighted = false,
  });
}

class BiblePassage {
  final String book;
  final int chapter;
  final String title;
  final List<BibleVerse> verses;

  const BiblePassage({
    required this.book,
    required this.chapter,
    required this.title,
    required this.verses,
  });

  String get reference => '$book $chapter';
}

class MockBibleData {
  static const List<String> availableTranslations = ['KJV', 'ASV', 'WEB', 'YOR'];

  static const List<BiblePassage> passages = [
    BiblePassage(
      book: 'John',
      chapter: 15,
      title: 'The True Vine',
      verses: [
        BibleVerse(
          verseNumber: 1,
          text: 'I am the true vine, and my Father is the vinedresser.',
        ),
        BibleVerse(
          verseNumber: 2,
          text: 'Every branch in me that doesn’t bear fruit, he takes away. Every branch that bears fruit, he prunes, that it may bear more fruit.',
        ),
        BibleVerse(
          verseNumber: 3,
          text: 'You are already pruned because of the word which I have spoken to you.',
        ),
        BibleVerse(
          verseNumber: 4,
          text: 'Remain in me, and I in you. As the branch cannot bear fruit of itself unless it remains in the vine, so neither can you unless you remain in me.',
          isHighlighted: true,
        ),
        BibleVerse(
          verseNumber: 5,
          text: 'I am the vine. You are the branches. He who remains in me, and I in him, bears much fruit; for apart from me you can do nothing.',
          isHighlighted: true,
        ),
        BibleVerse(
          verseNumber: 6,
          text: 'If anyone doesn’t remain in me, he is thrown out as a branch and is withered; and they gather them, throw them into the fire, and they are burned.',
        ),
        BibleVerse(
          verseNumber: 7,
          text: 'If you remain in me, and my words remain in you, you will ask whatever you desire, and it will be done for you.',
        ),
        BibleVerse(
          verseNumber: 8,
          text: 'In this my Father is glorified, that you bear much fruit; and so you will be my disciples.',
        ),
      ],
    ),
    BiblePassage(
      book: 'Psalm',
      chapter: 23,
      title: 'The Lord is My Shepherd',
      verses: [
        BibleVerse(
          verseNumber: 1,
          text: 'The Lord is my shepherd; I shall not want.',
        ),
        BibleVerse(
          verseNumber: 2,
          text: 'He makes me lie down in green pastures; he leads me beside still waters.',
          isHighlighted: true,
        ),
        BibleVerse(
          verseNumber: 3,
          text: 'He restores my soul; he leads me in paths of righteousness for his name’s sake.',
        ),
        BibleVerse(
          verseNumber: 4,
          text: 'Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me; your rod and your staff, they comfort me.',
        ),
      ],
    ),
  ];
}
