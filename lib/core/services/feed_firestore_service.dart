import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/feed/models/feed_post_model.dart';

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
      final docRef = await ref.add(post.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore createPost error: $e');
      return null;
    }
  }

  /// Toggle Amen (like) on a post
  Future<void> toggleAmen({
    required String postId,
    required String userId,
    required bool isCurrentlyLiked,
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

  /// Add a comment to a post
  Future<void> addComment({
    required String postId,
    required PostComment comment,
  }) async {
    try {
      final db = _firestore;
      final ref = _postsRef;
      if (db == null || ref == null) return;

      final batch = db.batch();
      final commentDocRef = ref.doc(postId).collection('comments').doc();
      batch.set(commentDocRef, comment.toMap());

      final postDocRef = ref.doc(postId);
      batch.update(postDocRef, {
        'commentCount': FieldValue.increment(1),
      });

      await batch.commit();
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
      final docRef = await ref.add(story.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore createStory error: $e');
      return null;
    }
  }
}
