import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LiveSessionService {
  FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>>? get _ref {
    if (_db != null) return _db!.collection('liveSessions');
    try {
      _db = FirebaseFirestore.instance;
      return _db!.collection('liveSessions');
    } catch (e) {
      debugPrint('Firestore instance not available in LiveSessionService: $e');
      return null;
    }
  }

  /// Creates a new live worship session doc and returns its generated document ID.
  /// The document ID serves as both the Firestore session ID and the Agora channel ID.
  Future<String> goLive({
    required String hostId,
    required String hostName,
    String? hostAvatar,
    required bool hasVideo,
  }) async {
    final ref = _ref;
    if (ref == null) throw Exception('Firestore unavailable');

    final doc = await ref.add({
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar ?? '',
      'hasVideo': hasVideo,
      'isLive': true,
      'likedUserIds': <String>[],
      'startedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Ends a live stream session by marking isLive = false.
  Future<void> endLive(String roomId) async {
    final ref = _ref;
    if (ref == null) return;
    await ref.doc(roomId).update({'isLive': false});
  }

  /// Stream of a specific live session room document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) {
    final ref = _ref;
    if (ref == null) return const Stream.empty();
    return ref.doc(roomId).snapshots();
  }

  /// Stream of all currently active live rooms (isLive == true).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveRooms() {
    final ref = _ref;
    if (ref == null) return const Stream.empty();
    return ref
        .where('isLive', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots();
  }

  /// Toggle like status for a given user on a live session room.
  Future<void> toggleLike({required String roomId, required String userId}) async {
    final ref = _ref;
    if (ref == null) return;
    final docRef = ref.doc(roomId);
    final snap = await docRef.get();
    final liked = List<String>.from(snap.data()?['likedUserIds'] ?? []);
    if (liked.contains(userId)) {
      liked.remove(userId);
    } else {
      liked.add(userId);
    }
    await docRef.update({'likedUserIds': liked});
  }

  /// Add a comment to the live session's comments subcollection.
  Future<void> addComment({
    required String roomId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    final ref = _ref;
    if (ref == null) return;
    await ref.doc(roomId).collection('comments').add({
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of comments for a live room ordered by creation time.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchComments(String roomId) {
    final ref = _ref;
    if (ref == null) return const Stream.empty();
    return ref
        .doc(roomId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
