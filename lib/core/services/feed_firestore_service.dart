import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/feed/models/feed_post_model.dart';
import '../../features/notifications/models/app_notification_model.dart';

class FeedFirestoreService {
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      _firestoreInstance = FirebaseFirestore.instance;
      return _firestoreInstance;
    } catch (e) {
      debugPrint('Firestore instance not available: $e');
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _postsRef => _firestore?.collection('posts');

  /// How many Prayer Wall posts a given user has shared — used for the
  /// Profile screen's real stats and the Prayer Wall Host badge.
  Future<int> getPrayerCountForUser(String userId) async {
    try {
      final ref = _postsRef;
      if (ref == null || userId.isEmpty) return 0;
      final query = ref.where('authorId', isEqualTo: userId).where('category', isEqualTo: 'Prayer Wall');
      final countSnapshot = await query.count().get();
      return countSnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Firestore getPrayerCountForUser error: $e');
      return 0;
    }
  }

  /// Stream real-time feed posts
  Stream<List<FeedPost>> getPostsStream({String currentUserId = ''}) {
    final ref = _postsRef;
    if (ref == null) return const Stream.empty();

    return ref.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FeedPost.fromMap(doc.data(), doc.id, currentUserId: currentUserId);
      }).toList();
    });
  }

  /// Create a new post in Firestore
  Future<String?> createPost(FeedPost post) async {
    try {
      final ref = _postsRef;
      if (ref == null) return null;
      final data = post.toMap();
      // Order by the server's clock, not the poster's device clock — if a
      // phone's clock is off, orderBy('createdAt') would put that user's
      // post in a different position for every viewer than it shows for
      // the poster themselves.
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await ref.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore createPost error: $e');
      return null;
    }
  }

  /// Toggle Amen (like) on a post. When this is a new Amen (not an
  /// unlike) and it isn't the post author liking their own post, also
  /// drops a real notification for [postAuthorId] — pass it (plus the
  /// liker's display info) to get that; omit it and this behaves exactly
  /// as before with no notification written.
  Future<void> toggleAmen({
    required String postId,
    required String userId,
    required bool isCurrentlyLiked,
    String? postAuthorId,
    String? actorName,
    String? actorAvatar,
    String? postSnippet,
  }) async {
    try {
      final ref = _postsRef;
      if (ref == null) return;
      final docRef = ref.doc(postId);
      if (isCurrentlyLiked) {
        await docRef.update({
          'amenCount': FieldValue.increment(-1),
          'likedUserIds': FieldValue.arrayRemove([userId]),
        });
      } else {
        await docRef.update({
          'amenCount': FieldValue.increment(1),
          'likedUserIds': FieldValue.arrayUnion([userId]),
        });
        if (postAuthorId != null && actorName != null) {
          await _addNotification(
            recipientId: postAuthorId,
            actorId: userId,
            actorName: actorName,
            actorAvatar: actorAvatar,
            type: 'amen',
            postId: postId,
            postSnippet: postSnippet,
          );
        }
      }
    } catch (e) {
      debugPrint('Firestore toggleAmen error: $e');
    }
  }

  /// Stream comments for a specific post
  Stream<List<PostComment>> getCommentsStream(String postId, {String currentUserId = ''}) {
    final ref = _postsRef;
    if (ref == null) return const Stream.empty();

    return ref
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostComment.fromMap(doc.data(), doc.id, currentUserId: currentUserId);
      }).toList();
    });
  }

  /// Add a comment to a post. Pass [postAuthorId] to also drop a real
  /// notification for the post's author (skipped automatically when
  /// they're commenting on their own post).
  Future<void> addComment({
    required String postId,
    required PostComment comment,
    String? postAuthorId,
    String? postSnippet,
  }) async {
    try {
      final db = _firestore;
      final ref = _postsRef;
      if (db == null || ref == null) return;

      final batch = db.batch();
      // Use the same id the comment already has locally, instead of
      // letting Firestore auto-generate a different one — otherwise the
      // on-screen "just sent" comment and the confirmed server copy have
      // two different ids, the comments sheet can't tell they're the
      // same comment, and it renders both = duplicate comments.
      final commentDocRef = ref.doc(postId).collection('comments').doc(comment.id);
      final data = comment.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      batch.set(commentDocRef, data);

      final postDocRef = ref.doc(postId);
      batch.update(postDocRef, {
        'commentCount': FieldValue.increment(1),
      });

      await batch.commit();

      if (postAuthorId != null) {
        await _addNotification(
          recipientId: postAuthorId,
          actorId: comment.authorId,
          actorName: comment.authorName,
          actorAvatar: comment.authorAvatar,
          type: 'comment',
          postId: postId,
          postSnippet: postSnippet,
        );
      }
    } catch (e) {
      debugPrint('Firestore addComment error: $e');
    }
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    try {
      final ref = _postsRef;
      if (ref == null) return;

      final docRef = ref.doc(postId).collection('comments').doc(commentId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('Firestore comment doc $commentId does not exist yet');
        return;
      }

      if (isCurrentlyLiked) {
        await docRef.update({
          'likeCount': FieldValue.increment(-1),
          'likedUserIds': FieldValue.arrayRemove([userId]),
        });
      } else {
        await docRef.update({
          'likeCount': FieldValue.increment(1),
          'likedUserIds': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      debugPrint('Firestore toggleCommentLike error: $e');
    }
  }

  CollectionReference<Map<String, dynamic>>? get _storiesRef => _firestore?.collection('stories');

  /// Stream real-time sanctuary stories
  Stream<List<SanctuaryStory>> getStoriesStream({String currentUserId = ''}) {
    final ref = _storiesRef;
    if (ref == null) return const Stream.empty();

    return ref.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SanctuaryStory.fromMap(doc.data(), doc.id, currentUserId: currentUserId);
      }).toList();
    });
  }

  /// Create a new story in Firestore
  Future<String?> createStory(SanctuaryStory story) async {
    try {
      final ref = _storiesRef;
      if (ref == null) return null;
      final data = story.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await ref.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore createStory error: $e');
      return null;
    }
  }

  /// Record that a specific viewer has opened a specific story, so that
  /// viewer's ring segment turns gray — and only theirs. Other viewers'
  /// copies of this story document are untouched.
  Future<void> markStoryViewed({required String storyId, required String userId}) async {
    try {
      final ref = _storiesRef;
      if (ref == null || userId.isEmpty) return;
      await ref.doc(storyId).update({
        'viewedByUserIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Firestore markStoryViewed error: $e');
    }
  }

  // --- Notifications (bell icon: Amens & comments on your posts) ---

  CollectionReference<Map<String, dynamic>>? _notificationsRef(String userId) =>
      _firestore?.collection('notifications').doc(userId).collection('items');

  Future<void> _addNotification({
    required String recipientId,
    required String actorId,
    required String actorName,
    String? actorAvatar,
    required String type,
    required String postId,
    String? postSnippet,
  }) async {
    try {
      // Never notify someone about their own Amen/comment on their own post.
      if (recipientId.isEmpty || recipientId == actorId) return;
      final ref = _notificationsRef(recipientId);
      if (ref == null) return;
      final trimmedSnippet =
          (postSnippet != null && postSnippet.length > 120) ? '${postSnippet.substring(0, 120)}…' : postSnippet;
      await ref.add(AppNotification(
        id: '',
        type: type,
        actorId: actorId,
        actorName: actorName,
        actorAvatar: actorAvatar,
        postId: postId,
        postSnippet: trimmedSnippet,
        createdAt: DateTime.now(),
      ).toMap());
    } catch (e) {
      debugPrint('Firestore _addNotification error: $e');
    }
  }

  /// Stream this user's notifications, newest first, for the
  /// Notifications screen and the bell-icon unread badge.
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    final ref = _notificationsRef(userId);
    if (ref == null || userId.isEmpty) return const Stream.empty();
    return ref.orderBy('createdAt', descending: true).limit(50).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppNotification.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> markNotificationRead(String userId, String notificationId) async {
    try {
      final ref = _notificationsRef(userId);
      if (ref == null) return;
      await ref.doc(notificationId).update({'read': true});
    } catch (e) {
      debugPrint('Firestore markNotificationRead error: $e');
    }
  }

  Future<void> markAllNotificationsRead(String userId, List<String> unreadIds) async {
    try {
      final db = _firestore;
      final ref = _notificationsRef(userId);
      if (db == null || ref == null || unreadIds.isEmpty) return;
      final batch = db.batch();
      for (final id in unreadIds) {
        batch.update(ref.doc(id), {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore markAllNotificationsRead error: $e');
    }
  }
}