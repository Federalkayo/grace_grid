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
  final String userName;
  final String? userAvatar;
  final String roleTag;
  final bool hasUnread;
  final String? storyText;
  final String? imageUrl;
  final String? caption;
  final bool isLive;
  final DateTime createdAt;
  int amenCount;
  bool hasSaidAmen;

  SanctuaryStory({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.roleTag,
    this.hasUnread = true,
    this.storyText,
    this.imageUrl,
    this.caption,
    this.isLive = false,
    DateTime? createdAt,
    this.amenCount = 0,
    this.hasSaidAmen = false,
  }) : createdAt = createdAt ?? DateTime.now();

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

    return SanctuaryStory(
      id: id,
      userName: data['userName'] ?? 'Sanctuary Believer',
      userAvatar: data['userAvatar'],
      roleTag: data['roleTag'] ?? 'Believer',
      hasUnread: data['hasUnread'] ?? true,
      storyText: data['storyText'],
      imageUrl: data['imageUrl'],
      caption: data['caption'],
      isLive: data['isLive'] ?? false,
      createdAt: created,
      amenCount: data['amenCount'] ?? 0,
      hasSaidAmen: currentUserId.isNotEmpty && likes.contains(currentUserId),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userAvatar': userAvatar,
      'roleTag': roleTag,
      'hasUnread': hasUnread,
      'storyText': storyText,
      'imageUrl': imageUrl,
      'caption': caption,
      'isLive': isLive,
      'createdAt': Timestamp.fromDate(createdAt),
      'amenCount': amenCount,
    };
  }

  SanctuaryStory copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    String? roleTag,
    bool? hasUnread,
    String? storyText,
    String? imageUrl,
    String? caption,
    bool? isLive,
    DateTime? createdAt,
    int? amenCount,
    bool? hasSaidAmen,
  }) {
    return SanctuaryStory(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      roleTag: roleTag ?? this.roleTag,
      hasUnread: hasUnread ?? this.hasUnread,
      storyText: storyText ?? this.storyText,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      isLive: isLive ?? this.isLive,
      createdAt: createdAt ?? this.createdAt,
      amenCount: amenCount ?? this.amenCount,
      hasSaidAmen: hasSaidAmen ?? this.hasSaidAmen,
    );
  }
}
