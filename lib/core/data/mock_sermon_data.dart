class SermonNote {
  final String timestamp;
  final String title;
  final String content;
  final String scriptureRef;

  const SermonNote({
    required this.timestamp,
    required this.title,
    required this.content,
    required this.scriptureRef,
  });
}

class MockSermonData {
  static const String sermonTitle = 'Abiding in the Vine & Sacred Fellowship';
  static const String speakerName = 'Pastor Kaleb';
  static const String seriesName = 'Kingdom Roots Vol. 4';
  static const String dateStr = 'Sunday Service • Sep 3';
  static const String currentRecTime = '00:14:32';

  static const List<SermonNote> notes = [
    SermonNote(
      timestamp: '00:03:15',
      title: 'Pruning as Divine Favor',
      content: 'Pruning is not punishment; it is the Father freeing us from distraction to bear greater eternal fruit.',
      scriptureRef: 'John 15:2',
    ),
    SermonNote(
      timestamp: '00:08:40',
      title: 'The Organic Connection',
      content: 'We do not generate life ourselves—we simply stay attached to the true source through daily prayer.',
      scriptureRef: 'John 15:5',
    ),
    SermonNote(
      timestamp: '00:12:10',
      title: 'Sacred Fellowship Gating',
      content: 'Community thrives when hearts are aligned in prayer and accountability.',
      scriptureRef: 'Acts 2:42',
    ),
  ];
}
