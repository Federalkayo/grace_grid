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

  /// Clean and normalize handle/name token for deterministic chat IDs
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

  /// Generate deterministic 1:1 chat ID between two handles/IDs
  static String getChatId(String user1, String user2) {
    final u1 = cleanHandle(user1);
    final u2 = cleanHandle(user2);
    if (u1 == u2) return u1;
    final list = [u1, u2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Helper to check if a user (id or name) matches any target in a list of participants
  static bool isParticipantMatch(String userId, String userName, List<String> targets) {
    final cleanId = userId.trim().toLowerCase();
    final cleanName = userName.trim().toLowerCase();
    if (cleanId.isEmpty && cleanName.isEmpty) return false;

    for (final rawTarget in targets) {
      final t = rawTarget.trim().toLowerCase();
      if (t.isEmpty) continue;

      // Direct equality or containment
      if (cleanId.isNotEmpty && (t == cleanId || t.contains(cleanId) || cleanId.contains(t))) {
        return true;
      }
      if (cleanName.isNotEmpty && (t == cleanName || t.contains(cleanName) || cleanName.contains(t))) {
        return true;
      }

      // Word token matching (e.g. 'kayode' matches 'kayode koko')
      if (cleanName.isNotEmpty) {
        final tWords = t.split(RegExp(r'[\s_.-]+'));
        final uWords = cleanName.split(RegExp(r'[\s_.-]+'));
        for (final w1 in tWords) {
          if (w1.length >= 2) {
            for (final w2 in uWords) {
              if (w2.length >= 2 && (w1 == w2 || w1.contains(w2) || w2.contains(w1))) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }

  CollectionReference<Map<String, dynamic>>? get _chatsRef => _firestore?.collection('chats');

  /// Stream active conversations from Firestore strictly for current user
  Stream<List<Map<String, dynamic>>> getConversationsStream(String currentUserId, {String currentUserName = ''}) {
    final ref = _chatsRef;
    if (ref == null) return const Stream.empty();

    return ref.snapshots().map((snapshot) {
      final list = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? [])
            .map((p) => p.trim().toLowerCase())
            .where((p) => p.isNotEmpty)
            .toList();

        final docIdParts = doc.id.toLowerCase().split('_');
        final allTargets = [...participants, ...docIdParts];

        // STRICT MATCH: Check if current user is a participant
        final isParticipant = isParticipantMatch(currentUserId, currentUserName, allTargets);

        if (isParticipant) {
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
  Stream<List<AgoraChatMessageData>> getMessagesStream(String chatId, String currentUserId, {String currentUserName = ''}) {
    final ref = _chatsRef;
    if (ref == null) return const Stream.empty();

    final cleanCurrentId = currentUserId.trim().toLowerCase();
    final cleanCurrentName = currentUserName.trim().toLowerCase();

    return ref
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final senderId = (data['senderId'] ?? '').toString();
        final senderName = (data['senderName'] ?? '').toString();

        final isMe = (cleanCurrentId.isNotEmpty && (senderId.toLowerCase() == cleanCurrentId || cleanCurrentId.contains(senderId.toLowerCase()))) ||
                     (cleanCurrentName.isNotEmpty && (senderName.toLowerCase() == cleanCurrentName || cleanCurrentName.contains(senderName.toLowerCase()) || senderName.toLowerCase().contains(cleanCurrentName))) ||
                     (data['isMe'] == true && senderId == 'user_me');

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

  /// Send direct message and persist to Firestore
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String recipientName,
    required String content,
    String senderAvatar = '',
    String recipientAvatar = '',
  }) async {
    try {
      final db = _firestore;
      final ref = _chatsRef;
      if (db == null || ref == null) return;

      final chatId = getChatId(senderId.isNotEmpty ? senderId : senderName, recipientName);

      final chatDocRef = ref.doc(chatId);
      final msgDocRef = chatDocRef.collection('messages').doc();

      final batch = db.batch();

      // Write message doc
      batch.set(msgDocRef, {
        'senderId': senderId,
        'senderName': senderName,
        'recipientName': recipientName,
        'content': content.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isMe': true,
        'isDelivered': true,
        'isRead': false,
        'reactions': <String>[],
      });

      // Update parent chat doc
      batch.set(chatDocRef, {
        'participants': [senderId.toLowerCase(), senderName.toLowerCase(), recipientName.toLowerCase()],
        'lastSenderId': senderId,
        'lastSenderName': senderName,
        'lastRecipientName': recipientName,
        'lastMessage': content.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'partnerAvatars': {
          senderName.toLowerCase(): senderAvatar,
          recipientName.toLowerCase(): recipientAvatar,
          senderId.toLowerCase(): senderAvatar,
        },
        'partnerNames': {
          senderId.toLowerCase(): senderName,
          senderName.toLowerCase(): senderName,
          recipientName.toLowerCase(): recipientName,
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
      final cleanUser = currentUserId.trim().toLowerCase();

      final batch = _firestore?.batch();
      if (batch == null) return;

      int updatedCount = 0;
      for (final doc in messagesQuery.docs) {
        final senderId = (doc.data()['senderId'] ?? '').toString().toLowerCase();
        final senderName = (doc.data()['senderName'] ?? '').toString().toLowerCase();
        if (senderId != cleanUser && senderName != cleanUser) {
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
