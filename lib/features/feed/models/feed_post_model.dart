import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String postId;
  final String authorName;
  final String? authorAvatar;
  final String authorTitle;
  final String authorId;
  final String text;
  final String timeAgo;
  final DateTime createdAt;
  int likeCount;
  bool isLiked;
  List<String> likedUserIds;

  PostComment({
    required this.id,
    required this.postId,
    required this.authorName,
    this.authorAvatar,
    required this.authorTitle,
    required this.authorId,
    required this.text,
    required this.timeAgo,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
    List<String>? likedUserIds,
  }) : likedUserIds = likedUserIds ?? [];

  factory PostComment.fromMap(Map<String, dynamic> data, String id, {String currentUserId = ''}) {
    final rawTimestamp = data['createdAt'];
    DateTime created;
    if (rawTimestamp is Timestamp) {
      created = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      created = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    final likes = List<String>.from(data['likedUserIds'] ?? []);

    return PostComment(
      id: id,
      postId: data['postId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous Believer',
      authorAvatar: data['authorAvatar'],
      authorTitle: data['authorTitle'] ?? 'Community Member',
      authorId: data['authorId'] ?? '',
      text: data['text'] ?? '',
      timeAgo: data['timeAgo'] ?? _calculateTimeAgo(created),
      createdAt: created,
      likeCount: data['likeCount'] ?? 0,
      likedUserIds: likes,
      isLiked: currentUserId.isNotEmpty && likes.contains(currentUserId),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorTitle': authorTitle,
      'authorId': authorId,
      'text': text,
      'timeAgo': timeAgo,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'likedUserIds': likedUserIds,
    };
  }

  static String _calculateTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class FeedPost {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String authorTitle;
  final String authorId;
  final String authorHandle;
  final String timeAgo;
  final DateTime createdAt;
  final String category; // Prayer Wall, Testimony, Reflection, Fellowship
  final String? scriptureRef;
  final String body;
  final String? imageUrl;
  final String? imageCaption;
  int amenCount;
  bool hasSaidAmen;
  List<String> likedUserIds;
  int commentCount;
  List<PostComment> comments;

  FeedPost({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.authorTitle,
    required this.authorId,
    required this.authorHandle,
    required this.timeAgo,
    required this.createdAt,
    required this.category,
    this.scriptureRef,
    required this.body,
    this.imageUrl,
    this.imageCaption,
    this.amenCount = 0,
    this.hasSaidAmen = false,
    List<String>? likedUserIds,
    this.commentCount = 0,
    List<PostComment>? comments,
  })  : likedUserIds = likedUserIds ?? [],
        comments = comments ?? [];

  factory FeedPost.fromMap(Map<String, dynamic> data, String id, {String currentUserId = ''}) {
    final rawTimestamp = data['createdAt'];
    DateTime created;
    if (rawTimestamp is Timestamp) {
      created = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      created = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    final likes = List<String>.from(data['likedUserIds'] ?? []);

    return FeedPost(
      id: id,
      authorName: data['authorName'] ?? 'Sanctuary Believer',
      authorAvatar: data['authorAvatar'],
      authorTitle: data['authorTitle'] ?? 'Community Member',
      authorId: data['authorId'] ?? '',
      authorHandle: data['authorHandle'] ?? '@believer',
      timeAgo: data['timeAgo'] ?? _calculateTimeAgo(created),
      createdAt: created,
      category: data['category'] ?? 'Fellowship',
      scriptureRef: data['scriptureRef'],
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      imageCaption: data['imageCaption'],
      amenCount: data['amenCount'] ?? 0,
      likedUserIds: likes,
      hasSaidAmen: currentUserId.isNotEmpty && likes.contains(currentUserId),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorTitle': authorTitle,
      'authorId': authorId,
      'authorHandle': authorHandle,
      'timeAgo': timeAgo,
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'scriptureRef': scriptureRef,
      'body': body,
      'imageUrl': imageUrl,
      'imageCaption': imageCaption,
      'amenCount': amenCount,
      'likedUserIds': likedUserIds,
      'commentCount': commentCount,
    };
  }

  FeedPost copyWith({
    String? id,
    String? authorName,
    String? authorAvatar,
    String? authorTitle,
    String? authorId,
    String? authorHandle,
    String? timeAgo,
    DateTime? createdAt,
    String? category,
    String? scriptureRef,
    String? body,
    String? imageUrl,
    String? imageCaption,
    int? amenCount,
    bool? hasSaidAmen,
    List<String>? likedUserIds,
    int? commentCount,
    List<PostComment>? comments,
  }) {
    return FeedPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorTitle: authorTitle ?? this.authorTitle,
      authorId: authorId ?? this.authorId,
      authorHandle: authorHandle ?? this.authorHandle,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      scriptureRef: scriptureRef ?? this.scriptureRef,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      imageCaption: imageCaption ?? this.imageCaption,
      amenCount: amenCount ?? this.amenCount,
      hasSaidAmen: hasSaidAmen ?? this.hasSaidAmen,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? this.comments,
    );
  }

  static String _calculateTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class SanctuaryStory {
  final String id;
  final String authorId;
  final String userName;
  final String? userAvatar;
  final String roleTag;
  final String? storyText;
  final String? imageUrl;
  final String? caption;
  final bool isLive;
  final DateTime createdAt;
  int amenCount;
  bool hasSaidAmen;
  // Every user id who has already opened this specific story. Read state
  // has to live per-viewer like this — a single shared hasUnread flag
  // means the ring going gray for the person who watched it would turn
  // it gray for everyone else too, which isn't how WhatsApp/IG stories
  // work.
  List<String> viewedByUserIds;

  SanctuaryStory({
    required this.id,
    this.authorId = '',
    required this.userName,
    this.userAvatar,
    required this.roleTag,
    this.storyText,
    this.imageUrl,
    this.caption,
    this.isLive = false,
    DateTime? createdAt,
    this.amenCount = 0,
    this.hasSaidAmen = false,
    List<String>? viewedByUserIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        viewedByUserIds = viewedByUserIds ?? [];

  /// Whether THIS story is still unread for the given viewer. Every
  /// viewer gets their own answer, independent of who else has seen it.
  bool isUnreadFor(String userId) => userId.isEmpty || !viewedByUserIds.contains(userId);

  factory SanctuaryStory.fromMap(Map<String, dynamic> data, String id, {String currentUserId = ''}) {
    final rawTimestamp = data['createdAt'];
    DateTime created;
    if (rawTimestamp is Timestamp) {
      created = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      created = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    final likes = List<String>.from(data['likedUserIds'] ?? []);
    final viewedBy = List<String>.from(data['viewedByUserIds'] ?? []);

    return SanctuaryStory(
      id: id,
      authorId: data['authorId'] ?? '',
      userName: data['userName'] ?? 'Sanctuary Believer',
      userAvatar: data['userAvatar'],
      roleTag: data['roleTag'] ?? 'Believer',
      storyText: data['storyText'],
      imageUrl: data['imageUrl'],
      caption: data['caption'],
      isLive: data['isLive'] ?? false,
      createdAt: created,
      amenCount: data['amenCount'] ?? 0,
      hasSaidAmen: currentUserId.isNotEmpty && likes.contains(currentUserId),
      viewedByUserIds: viewedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'userName': userName,
      'userAvatar': userAvatar,
      'roleTag': roleTag,
      'storyText': storyText,
      'imageUrl': imageUrl,
      'caption': caption,
      'isLive': isLive,
      'createdAt': Timestamp.fromDate(createdAt),
      'amenCount': amenCount,
      'viewedByUserIds': viewedByUserIds,
    };
  }

  SanctuaryStory copyWith({
    String? id,
    String? authorId,
    String? userName,
    String? userAvatar,
    String? roleTag,
    String? storyText,
    String? imageUrl,
    String? caption,
    bool? isLive,
    DateTime? createdAt,
    int? amenCount,
    bool? hasSaidAmen,
    List<String>? viewedByUserIds,
  }) {
    return SanctuaryStory(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      roleTag: roleTag ?? this.roleTag,
      storyText: storyText ?? this.storyText,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      isLive: isLive ?? this.isLive,
      createdAt: createdAt ?? this.createdAt,
      amenCount: amenCount ?? this.amenCount,
      hasSaidAmen: hasSaidAmen ?? this.hasSaidAmen,
      viewedByUserIds: viewedByUserIds ?? this.viewedByUserIds,
    );
  }
}

/// A single story "bubble" for one author, holding every story they've
/// posted in the last 24h as ordered segments (oldest first) so the
/// viewer plays through THAT author's segments only — never other
/// people's stories.
class StoryGroup {
  final String authorId;
  final String userName;
  final String? userAvatar;
  final String roleTag;
  final bool isLive;
  final List<SanctuaryStory> stories;

  StoryGroup({
    required this.authorId,
    required this.userName,
    this.userAvatar,
    required this.roleTag,
    this.isLive = false,
    required this.stories,
  });

  /// Per-segment read state for a specific viewer — true = still unread
  /// for THAT viewer, in the same order as [stories]. One entry per ring
  /// segment.
  List<bool> unreadFlagsFor(String viewerId) => stories.map((s) => s.isUnreadFor(viewerId)).toList();

  bool hasUnreadFor(String viewerId) => stories.any((s) => s.isUnreadFor(viewerId));

  /// Groups a flat, already-24h-filtered story list by author, preserving
  /// each author's most-recent-first ordering in the bar while playing
  /// each author's own segments oldest-first inside the viewer.
  static List<StoryGroup> fromStories(List<SanctuaryStory> stories) {
    final Map<String, List<SanctuaryStory>> byAuthor = {};
    final List<String> authorOrder = [];

    for (final story in stories) {
      final key = story.authorId.isNotEmpty ? story.authorId : story.id;
      if (!byAuthor.containsKey(key)) {
        byAuthor[key] = [];
        authorOrder.add(key);
      }
      byAuthor[key]!.add(story);
    }

    return authorOrder.map((key) {
      final segments = byAuthor[key]!..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final latest = segments.last;
      return StoryGroup(
        authorId: key,
        userName: latest.userName,
        userAvatar: latest.userAvatar,
        roleTag: latest.roleTag,
        isLive: segments.any((s) => s.isLive),
        stories: segments,
      );
    }).toList();
  }
}
