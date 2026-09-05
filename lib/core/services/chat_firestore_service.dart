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

  CollectionReference<Map<String, dynamic>>? get _chatsRef => _firestore?.collection('chats');

  /// Stream active conversations from Firestore strictly for current user UID
  Stream<List<Map<String, dynamic>>> getConversationsStream(String currentUserId) {
    final ref = _chatsRef;
    final cleanId = currentUserId.trim();
    if (ref == null || cleanId.isEmpty) return const Stream.empty();

    return ref.snapshots().map((snapshot) {
      final list = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? [])
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        // Exact match on UID or fallback ID
        if (participants.contains(cleanId)) {
          list.add({
            'id': doc.id,
            ...data,
          });
        }
      }
      list.sort((a, b) {
        final aTime = (a['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return list;
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
          reactions: List<String>.from(data['reactions'] ?? []),
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
        'reactions': <String>[],
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
    required String emoji,
  }) async {
    try {
      final ref = _chatsRef;
      if (ref == null) return;

      final msgDocRef = ref.doc(chatId).collection('messages').doc(messageId);
      final snapshot = await msgDocRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final currentReactions = List<String>.from(data?['reactions'] ?? []);
      if (currentReactions.contains(emoji)) {
        currentReactions.remove(emoji);
      } else {
        currentReactions.add(emoji);
      }

      await msgDocRef.update({'reactions': currentReactions});
    } catch (e) {
      debugPrint('Firestore toggleReaction error: $e');
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

      final messagesQuery = await ref.doc(chatId).collection('messages').where('isRead', isEqualTo: false).get();
      final cleanUser = currentUserId.trim();

      final batch = _firestore?.batch();
      if (batch == null) return;

      int updatedCount = 0;
      for (final doc in messagesQuery.docs) {
        final senderId = (doc.data()['senderId'] ?? '').toString().trim();
        if (senderId != cleanUser) {
          batch.update(doc.reference, {'isRead': true});
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Firestore markAsRead error: $e');
    }
  }
}
