import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/agora_chat_service.dart';

class ChatFirestoreService {
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      _firestoreInstance = FirebaseFirestore.instance;
      return _firestoreInstance;
    } catch (e) {
      debugPrint('Firestore instance not available for chat: $e');
      return null;
    }
  }

  /// Clean and normalize handle/name token for fallback legacy compatibility
  static String cleanHandle(String handle) {
    var clean = handle.trim().toLowerCase();
    for (final prefix in ['pastor ', 'sister ', 'brother ', 'evangelist ', 'deacon ']) {
      if (clean.startsWith(prefix)) {
        clean = clean.substring(prefix.length).trim();
      }
    }
    if (clean.contains(' ')) {
      clean = clean.split(RegExp(r'\s+')).first.trim();
    }
    return clean;
  }

  /// Generate deterministic 1:1 chat ID between two user IDs/UIDs
  static String getChatId(String uid1, String uid2) {
    final u1 = uid1.trim();
    final u2 = uid2.trim();
    if (u1 == u2) return u1;
    final list = [u1, u2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Helper to check if current user ID matches any target in a list of participants
  static bool isParticipantMatch(String userId, List<String> targets) {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) return false;
    return targets.any((t) => t.trim() == cleanId);
  }

  /// Stream registered users live from Firestore by name query
  static Stream<QuerySnapshot<Map<String, dynamic>>> searchUsers(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return FirebaseFirestore.instance.collection('users').limit(20).snapshots();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('nameLower')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(20)
        .snapshots();
  }

  CollectionReference<Map<String, dynamic>>? get _chatsRef => _firestore?.collection('chats');

  /// Stream active conversations from Firestore strictly for current user UID.
  ///
  /// IMPORTANT: this must filter with `.where('participants', arrayContains: cleanId)`.
  /// Our firestore.rules require `request.auth.uid in resource.data.participants`
  /// for reads on /chats/{chatId}. Firestore can only validate that condition for a
  /// *list* query (as opposed to a single-doc get) if the query itself is filtered
  /// the same way. Listening to the whole collection and filtering client-side (as
  /// this used to do) gets rejected by the rules engine with permission-denied for
  /// the entire query — so the stream silently never emits. On a device that already
  /// has a local cache, that's invisible (you still see the old cached list). On a
  /// fresh install / new device with no cache, it shows up as "my conversations are
  /// gone", because nothing was ever able to load from Firestore in the first place.
  Stream<List<Map<String, dynamic>>> getConversationsStream(String currentUserId) {
    final ref = _chatsRef;
    final cleanId = currentUserId.trim();
    if (ref == null || cleanId.isEmpty) return const Stream.empty();

    return ref
        .where('participants', arrayContains: cleanId)
        .snapshots()
        .map((snapshot) {
      final list = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        list.add({
          'id': doc.id,
          ...data,
        });
      }
      list.sort((a, b) {
        final aTime = (a['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return list;
    }).handleError((e) {
      debugPrint('Firestore getConversationsStream error: $e');
    });
  }

  /// Stream direct messages for a specific chat ID
  Stream<List<AgoraChatMessageData>> getMessagesStream(String chatId, String currentUserId) {
    final ref = _chatsRef;
    if (ref == null) return const Stream.empty();

    final cleanCurrentId = currentUserId.trim();

    return ref
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final senderId = (data['senderId'] ?? '').toString().trim();
        final senderName = (data['senderName'] ?? '').toString();

        final isMe = cleanCurrentId.isNotEmpty && senderId == cleanCurrentId;

        final timestampVal = data['timestamp'];
        DateTime dt = DateTime.now();
        if (timestampVal is Timestamp) {
          dt = timestampVal.toDate();
        } else if (timestampVal is String) {
          dt = DateTime.tryParse(timestampVal) ?? DateTime.now();
        }

        return AgoraChatMessageData(
          id: doc.id,
          senderId: senderId,
          senderName: senderName,
          content: (data['content'] ?? '').toString(),
          timestamp: dt,
          isMe: isMe,
          conversationId: chatId,
          isDelivered: data['isDelivered'] ?? true,
          isRead: data['isRead'] ?? false,
          reactions: Map<String, String>.from(data['reactions'] is Map ? data['reactions'] : {}),
          isForwarded: data['isForwarded'] ?? false,
          replyToId: (data['replyToId'] as String?)?.isNotEmpty == true ? data['replyToId'] as String : null,
          replyToSenderName: data['replyToSenderName'] as String?,
          replyToContent: data['replyToContent'] as String?,
        );
      }).toList();
    });
  }

  /// Send direct message and persist to Firestore using UIDs and consistent message IDs
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String recipientId,
    required String recipientName,
    required String content,
    String senderAvatar = '',
    String recipientAvatar = '',
    String? messageId,
    bool isForwarded = false,
    // Pass all three to send this message as a reply. A snapshot of the
    // original is stored inline (not a live reference), so the quoted
    // preview keeps working even if the original message is later deleted.
    String? replyToId,
    String? replyToSenderName,
    String? replyToContent,
  }) async {
    try {
      final db = _firestore;
      final ref = _chatsRef;
      if (db == null || ref == null) return;

      final chatId = getChatId(senderId, recipientId);
      final chatDocRef = ref.doc(chatId);
      final msgId = messageId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';
      final msgDocRef = chatDocRef.collection('messages').doc(msgId);

      final batch = db.batch();

      // Write message doc - NO stored isMe boolean
      batch.set(msgDocRef, {
        'senderId': senderId,
        'senderName': senderName,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'content': content.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isDelivered': true,
        'isRead': false,
        'reactions': <String, String>{},
        'isForwarded': isForwarded,
        if (replyToId != null && replyToId.isNotEmpty) ...{
          'replyToId': replyToId,
          'replyToSenderName': replyToSenderName ?? '',
          'replyToContent': replyToContent ?? '',
        },
      });

      // Update parent chat doc keying partnerNames and partnerAvatars by UID
      batch.set(chatDocRef, {
        'participants': [senderId, recipientId],
        'lastSenderId': senderId,
        'lastSenderName': senderName,
        'lastRecipientId': recipientId,
        'lastRecipientName': recipientName,
        'lastMessage': content.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'partnerAvatars': {
          senderId: senderAvatar,
          recipientId: recipientAvatar,
        },
        'partnerNames': {
          senderId: senderName,
          recipientId: recipientName,
        },
        // Per-user unread counters, keyed by UID, live on the chat doc itself.
        // Only the recipient's counter goes up — this is what the conversations
        // list badge (WhatsApp-style unread number) reads from.
        'unreadCounts': {
          recipientId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore sendMessage error: $e');
    }
  }

  /// Toggle reaction on a message in Firestore
  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final ref = _chatsRef;
      if (ref == null) return;

      final msgDocRef = ref.doc(chatId).collection('messages').doc(messageId);
      final snapshot = await msgDocRef.get();
      if (!snapshot.exists) return;

      final reactions = Map<String, String>.from(snapshot.data()?['reactions'] is Map ? snapshot.data()!['reactions'] : {});
      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }

      await msgDocRef.update({'reactions': reactions});
    } catch (e) {
      debugPrint('Firestore toggleReaction error: $e');
    }
  }

  /// Delete a message document from Firestore
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final ref = _chatsRef;
      if (ref == null) return;
      await ref.doc(chatId).collection('messages').doc(messageId).delete();
    } catch (e) {
      debugPrint('Firestore deleteMessage error: $e');
    }
  }

  /// Mark conversation as read in Firestore
  Future<void> markAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final ref = _chatsRef;
      if (ref == null) return;

      final chatDocRef = ref.doc(chatId);
      final chatDocSnap = await chatDocRef.get();
      // If no one has sent a message in this chat yet, the doc doesn't exist —
      // skip entirely rather than let the merge below create a doc without a
      // 'participants' field, which the Firestore create rule would reject.
      if (!chatDocSnap.exists) return;

      final messagesQuery = await chatDocRef.collection('messages').where('isRead', isEqualTo: false).get();
      final cleanUser = currentUserId.trim();

      final batch = _firestore?.batch();
      if (batch == null) return;

      for (final doc in messagesQuery.docs) {
        final senderId = (doc.data()['senderId'] ?? '').toString().trim();
        if (senderId != cleanUser) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      // Always reset this reader's unread counter, even if there were no
      // unread messages left to mark (e.g. they were already all read but the
      // counter drifted) — this is the field the conversations list badge uses.
      batch.set(
        chatDocRef,
        {
          'unreadCounts': {cleanUser: 0},
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore markAsRead error: $e');
    }
  }
}