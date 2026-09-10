import '../../features/feed/models/feed_post_model.dart';
export '../../features/feed/models/feed_post_model.dart';

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
  static List<SanctuaryStory> getMockStories() => [
        SanctuaryStory(
          id: 'story-0',
          userName: 'Your Status',
          roleTag: 'Believer',
        ),
        SanctuaryStory(
          id: 'story-1',
          userName: 'Pastor Kaleb',
          userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
          roleTag: 'Lead Teacher',
          isLive: true,
          storyText: 'Join us live for Morning Sanctuary Prayer & Exposition on Psalm 91!',
          imageUrl: 'https://images.unsplash.com/photo-1544427920-c49ccfb85579?auto=format&fit=crop&w=1000&q=80',
          caption: 'Morning Worship & Prayer Fellowship',
          amenCount: 34,
        ),
        SanctuaryStory(
          id: 'story-2',
          userName: 'Sister Maya',
          userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
          roleTag: 'Intercessor',
          storyText: '“The Lord is my light and my salvation—whom shall I fear?” — Psalm 27:1 ✨',
          imageUrl: 'https://images.unsplash.com/photo-1499209974431-9dac3ada00d7?auto=format&fit=crop&w=1000&q=80',
          caption: 'Daily scripture meditation',
          amenCount: 19,
        ),
        SanctuaryStory(
          id: 'story-3',
          userName: 'David O.',
          userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
          roleTag: 'Worship Lead',
          storyText: 'Rehearsing new acoustic praise songs for Sunday service. Praise God!',
          imageUrl: 'https://images.unsplash.com/photo-1507692049790-de58290a4334?auto=format&fit=crop&w=1000&q=80',
          caption: 'Worship team rehearsal snippet',
          amenCount: 42,
        ),
        SanctuaryStory(
          id: 'story-4',
          userName: 'Grace Youth',
          userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
          roleTag: 'Sanctuary Team',
          storyText: 'Youth sanctuary retreat registration is officially open!',
          imageUrl: 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?auto=format&fit=crop&w=1000&q=80',
          caption: 'Youth fellowship gathering',
          amenCount: 15,
        ),
      ];

  static List<FeedPost> getMockPosts() {
    final now = DateTime.now();

    return [
      FeedPost(
        id: 'mock-1',
        authorName: 'Pastor Kaleb',
        authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        authorTitle: 'Lead Teacher',
        authorId: 'pastor_kaleb',
        authorHandle: '@pastorkaleb',
        timeAgo: '25m ago',
        createdAt: now.subtract(const Duration(minutes: 25)),
        category: 'Reflection',
        scriptureRef: 'John 15:4',
        body: 'Remember: Abiding precedes fruitfulness. Don’t rush the quiet moments in scripture before embarking on your day. When we remain in Him, strength flows naturally. #AbideInChrist #DailySanctuary #GraceGrid',
        imageUrl: 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?auto=format&fit=crop&w=1000&q=80',
        imageCaption: 'Morning scripture meditation session in John 15',
        amenCount: 142,
        hasSaidAmen: true,
        commentCount: 18,
        comments: [
          PostComment(
            id: 'c-1',
            postId: 'mock-1',
            authorName: 'Sister Hannah',
            authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
            authorTitle: 'Fellowship Member',
            authorId: 'hannah_1',
            text: 'Amen Pastor! Needed this reminder today. Abiding is peace.',
            timeAgo: '18m ago',
            createdAt: now.subtract(const Duration(minutes: 18)),
            likeCount: 5,
            isLiked: true,
          ),
          PostComment(
            id: 'c-2',
            postId: 'mock-1',
            authorName: 'Brother Paul',
            authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
            authorTitle: 'Intercessor',
            authorId: 'paul_2',
            text: 'Glory to God! Verse 5 also hit home so deeply in morning prayer.',
            timeAgo: '10m ago',
            createdAt: now.subtract(const Duration(minutes: 10)),
            likeCount: 3,
          ),
        ],
      ),
      FeedPost(
        id: 'mock-2',
        authorName: 'Sister Maya Lin',
        authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        authorTitle: 'Sanctuary Intercessor',
        authorId: 'maya_lin',
        authorHandle: '@mayalin',
        timeAgo: '1h ago',
        createdAt: now.subtract(const Duration(hours: 1)),
        category: 'Prayer Wall',
        scriptureRef: 'Psalm 46:1',
        body: 'Lifting up everyone walking through uncertain transitions this week. God is our refuge and very present help in trouble! Please drop your specific prayer points below so our intercessors can pray with you. #PrayerWall #Intercession',
        amenCount: 89,
        hasSaidAmen: false,
        commentCount: 12,
        comments: [
          PostComment(
            id: 'c-3',
            postId: 'mock-2',
            authorName: 'Grace M.',
            authorTitle: 'Believer',
            authorId: 'grace_m',
            text: 'Please pray for my mother’s medical checkup tomorrow morning.',
            timeAgo: '45m ago',
            createdAt: now.subtract(const Duration(minutes: 45)),
            likeCount: 7,
          ),
        ],
      ),
      FeedPost(
        id: 'mock-3',
        authorName: 'Brother David O.',
        authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
        authorTitle: 'Worship Minister',
        authorId: 'david_o',
        authorHandle: '@davido_worship',
        timeAgo: '3h ago',
        createdAt: now.subtract(const Duration(hours: 3)),
        category: 'Testimony',
        scriptureRef: 'Philippians 4:19',
        body: 'Testifying to God’s faithful provision! We just received full approval for our local community outreach food drive! God moves when His people unite in prayer. #Testimony #GodIsFaithful #GraceGrid',
        imageUrl: 'https://images.unsplash.com/photo-1507692049790-de58290a4334?auto=format&fit=crop&w=1000&q=80',
        imageCaption: 'Sanctuary community food drive preparations in action',
        amenCount: 210,
        hasSaidAmen: true,
        commentCount: 31,
      ),
    ];
  }

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
