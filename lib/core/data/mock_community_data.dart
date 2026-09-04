class FeedPost {
  final String id;
  final String authorName;
  final String authorTitle;
  final String timeAgo;
  final String category; // Prayer, Testimony, Reflection
  final String scriptureRef;
  final String body;
  int amenCount;
  bool hasSaidAmen;
  final int commentCount;

  FeedPost({
    required this.id,
    required this.authorName,
    required this.authorTitle,
    required this.timeAgo,
    required this.category,
    required this.scriptureRef,
    required this.body,
    required this.amenCount,
    this.hasSaidAmen = false,
    required this.commentCount,
  });
}

class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final String timestamp;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class MockCommunityData {
  static List<FeedPost> getMockPosts() => [
        FeedPost(
          id: 'post-1',
          authorName: 'Sister Maya Lin',
          authorTitle: 'Sanctuary Intercessor',
          timeAgo: '12m ago',
          category: 'Prayer Wall',
          scriptureRef: 'Psalm 46:1',
          body: 'Praying for strength and clarity for everyone starting a new season this month. May God’s peace guard your mind.',
          amenCount: 38,
          hasSaidAmen: true,
          commentCount: 9,
        ),
        FeedPost(
          id: 'post-2',
          authorName: 'Pastor Kaleb',
          authorTitle: 'Lead Teacher',
          timeAgo: '1h ago',
          category: 'Reflection',
          scriptureRef: 'John 15:4',
          body: 'Remember: Abiding precedes fruitfulness. Don’t rush the quiet moments in scripture before embarking on your day.',
          amenCount: 114,
          hasSaidAmen: false,
          commentCount: 24,
        ),
        FeedPost(
          id: 'post-3',
          authorName: 'Brother David O.',
          authorTitle: 'Worship Minister',
          timeAgo: '3h ago',
          category: 'Testimony',
          scriptureRef: 'Philippians 4:19',
          body: 'Testifying to God’s faithful provision! Received news of the community grant approval for our local sanctuary outreach.',
          amenCount: 86,
          hasSaidAmen: false,
          commentCount: 15,
        ),
      ];

  static const List<ChatMessage> mockChatMessages = [
    ChatMessage(
      id: 'msg-1',
      senderName: 'Pastor Kaleb',
      text: 'Grace and peace to you! How can I support your study in John 15 today?',
      timestamp: '10:42 AM',
      isMe: false,
    ),
    ChatMessage(
      id: 'msg-2',
      senderName: 'You',
      text: 'Thank you Pastor Kaleb. I am reflecting on verse 4 about abiding in the vine. Praying for deeper focus.',
      timestamp: '10:44 AM',
      isMe: true,
    ),
    ChatMessage(
      id: 'msg-3',
      senderName: 'Pastor Kaleb',
      text: 'Amen. Let us pray together in the Audio Sanctum when you are ready.',
      timestamp: '10:45 AM',
      isMe: false,
    ),
  ];
}
