import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agora_chat_service.dart';
import '../services/chat_firestore_service.dart';
import '../services/chat_local_cache_service.dart';
import '../providers/mock_auth_provider.dart';

final agoraChatServiceProvider = Provider<AgoraChatService>((ref) {
  return AgoraChatService();
});

final chatFirestoreServiceProvider = Provider<ChatFirestoreService>((ref) {
  return ChatFirestoreService();
});

final agoraConnectionStatusProvider = StreamProvider<AgoraConnectionStatus>((ref) {
  final service = ref.watch(agoraChatServiceProvider);
  return service.statusStream;
});

// -----------------------------------------------------------------------------
// Conversation Item Model for Inbox List
// -----------------------------------------------------------------------------
class ConversationItem {
  final String id;
  final String partnerName;
  final String avatarUrl;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;

  const ConversationItem({
    required this.id,
    required this.partnerName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.unreadCount = 0,
    this.isOnline = true,
    this.isTyping = false,
  });

  ConversationItem copyWith({
    String? id,
    String? partnerName,
    String? avatarUrl,
    String? lastMessage,
    String? timeAgo,
    int? unreadCount,
    bool? isOnline,
    bool? isTyping,
  }) {
    return ConversationItem(
      id: id ?? this.id,
      partnerName: partnerName ?? this.partnerName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timeAgo: timeAgo ?? this.timeAgo,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

// -----------------------------------------------------------------------------
// Conversations List Notifier (Inbox)
// -----------------------------------------------------------------------------
class ConversationsListNotifier extends StateNotifier<List<ConversationItem>> {
  final AgoraChatService _service;
  final ChatFirestoreService _firestoreService;
  final Ref ref;
  StreamSubscription<AgoraChatMessageData>? _msgSub;
  StreamSubscription<AgoraTypingEvent>? _typingSub;
  StreamSubscription<List<Map<String, dynamic>>>? _firestoreSub;

  ConversationsListNotifier(this._service, this._firestoreService, this.ref) : super([]) {
    _loadLocalCache();
    _initListeners();
    _listenToAuthChanges();
  }

  Future<void> _loadLocalCache() async {
    final currentProfile = ref.read(mockAuthNotifierProvider).profile;
    final userKey = currentProfile.id.isNotEmpty ? currentProfile.id : currentProfile.name;
    final cached = await ChatLocalCacheService().loadConversations(userKey);
    state = cached;
  }

  void _saveLocalCache() {
    final currentProfile = ref.read(mockAuthNotifierProvider).profile;
    final userKey = currentProfile.id.isNotEmpty ? currentProfile.id : currentProfile.name;
    ChatLocalCacheService().saveConversations(userKey, state);
  }

  void _listenToAuthChanges() {
    ref.listen(mockAuthNotifierProvider, (previous, next) {
      if (previous?.profile.id != next.profile.id || previous?.profile.name != next.profile.name) {
        state = []; // Clear previous account's conversations immediately
        _loadLocalCache();
        _subscribeFirestore(next.profile.id, next.profile.name);
      }
    });
  }

  void _subscribeFirestore(String userId, String userName) {
    _firestoreSub?.cancel();
    final cleanSubUserId = userId.trim().toLowerCase();

    _firestoreSub = _firestoreService.getConversationsStream(userId, currentUserName: userName).listen((docs) {
      final currentProfile = ref.read(mockAuthNotifierProvider).profile;
      final currentName = currentProfile.name.toLowerCase();
      final currentId = currentProfile.id.toLowerCase();

      // Ensure stream hasn't been outdistanced by a fast user account switch
      if (cleanSubUserId.isNotEmpty && currentId.isNotEmpty && cleanSubUserId != currentId) {
        return;
      }

      final firestoreItems = <ConversationItem>[];
      for (final data in docs) {
        final participants = List<String>.from(data['participants'] ?? [])
            .map((p) => p.trim().toLowerCase())
            .toList();
        final lastSenderName = (data['lastSenderName'] ?? '').toString();
        final lastSenderId = (data['lastSenderId'] ?? '').toString();
        final lastRecipientName = (data['lastRecipientName'] ?? '').toString();

        final docIdParts = (data['id'] ?? '').toString().toLowerCase().split('_');
        final allTargets = [...participants, ...docIdParts];

        final isMeParticipant = ChatFirestoreService.isParticipantMatch(currentId, currentName, allTargets);

        if (!isMeParticipant) {
          continue; // Strict safety check: Skip non-matching user chats
        }

        String partner = '';

        // 1. Find participant that is NOT current user
        for (final p in participants) {
          final pClean = p.trim().toLowerCase();
          if (pClean.isNotEmpty && pClean != currentName && pClean != currentId && pClean != 'user_me' && pClean != 'you') {
            partner = p;
            break;
          }
        }

        // 2. Check lastSender and lastRecipient names
        if (partner.isEmpty || partner.toLowerCase() == currentName || partner.toLowerCase() == currentId) {
          if (lastSenderName.isNotEmpty && lastSenderName.toLowerCase() != currentName && lastSenderName.toLowerCase() != currentId) {
            partner = lastSenderName;
          } else if (lastSenderId.isNotEmpty && lastSenderId.toLowerCase() != currentName && lastSenderId.toLowerCase() != currentId) {
            partner = lastSenderId;
          } else if (lastRecipientName.isNotEmpty && lastRecipientName.toLowerCase() != currentName && lastRecipientName.toLowerCase() != currentId) {
            partner = lastRecipientName;
          }
        }

        // 3. Check document ID (e.g. kayode_koko)
        if (partner.isEmpty || partner.toLowerCase() == currentName || partner.toLowerCase() == currentId) {
          for (final pt in docIdParts) {
            final ptClean = pt.trim().toLowerCase();
            if (ptClean.isNotEmpty && ptClean != currentName && ptClean != currentId && ptClean != 'user_me' && ptClean != 'you') {
              partner = pt;
              break;
            }
          }
        }

        if (partner.isEmpty || partner.toLowerCase() == currentName || partner.toLowerCase() == currentId) {
          continue; // Skip self-chat doc
        }

        final partnerNames = Map<String, dynamic>.from(data['partnerNames'] ?? {});
        final avatars = Map<String, dynamic>.from(data['partnerAvatars'] ?? {});

        String partnerDisplayName = (partnerNames[partner.toLowerCase()] ?? partnerNames[partner] ?? '').toString();
        if (partnerDisplayName.isEmpty) {
          if (lastSenderId.isNotEmpty && lastSenderId.toLowerCase() == partner.toLowerCase() && lastSenderName.isNotEmpty) {
            partnerDisplayName = lastSenderName;
          } else if (lastRecipientName.isNotEmpty && partner.toLowerCase() != currentName) {
            partnerDisplayName = lastRecipientName;
          }
        }
        if (partnerDisplayName.isEmpty) {
          partnerDisplayName = partner;
        }

        final formattedPartner = partnerDisplayName.length > 1 && !partnerDisplayName.startsWith('Gs')
            ? partnerDisplayName[0].toUpperCase() + partnerDisplayName.substring(1)
            : partnerDisplayName;

        final avatarUrl = (avatars[partner.toLowerCase()] ?? avatars[partnerDisplayName.toLowerCase()] ?? avatars[partner] ?? '').toString();

        final updatedAtVal = data['updatedAt'];
        String timeAgoStr = 'Just now';
        if (updatedAtVal != null) {
          final dt = (updatedAtVal is DateTime)
              ? updatedAtVal
              : DateTime.now();
          final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
          final minute = dt.minute.toString().padLeft(2, '0');
          final period = dt.hour >= 12 ? 'PM' : 'AM';
          timeAgoStr = '$hour:$minute $period';
        }

        firestoreItems.add(ConversationItem(
          id: partner,
          partnerName: formattedPartner,
          avatarUrl: avatarUrl,
          lastMessage: (data['lastMessage'] ?? '').toString(),
          timeAgo: timeAgoStr,
          unreadCount: 0,
          isOnline: true,
        ));
      }

      state = firestoreItems;
      _saveLocalCache();
    });
  }

  void _initListeners() {
    final currentProfile = ref.read(mockAuthNotifierProvider).profile;
    _subscribeFirestore(currentProfile.id, currentProfile.name);

    _msgSub = _service.incomingMessages.listen((msg) {
      if (msg.conversationId != null) {
        _updateWithIncomingMessage(msg.conversationId!, msg.senderName, msg.content, msg.formattedTime);
      }
    });

    _typingSub = _service.typingEvents.listen((event) {
      updateTypingStatus(event.conversationId, event.isTyping);
    });
  }

  void _updateWithIncomingMessage(String conversationId, String senderName, String content, String time, {bool incrementUnread = true}) {
    final currentProfile = ref.read(mockAuthNotifierProvider).profile;
    final currentName = currentProfile.name.toLowerCase();
    final currentId = currentProfile.id.toLowerCase();

    String partnerName = conversationId.trim();
    if (partnerName.toLowerCase() == currentName || partnerName.toLowerCase() == currentId) {
      if (senderName.isNotEmpty && senderName.toLowerCase() != currentName && senderName.toLowerCase() != currentId) {
        partnerName = senderName.trim();
      }
    } else if (senderName.isNotEmpty && senderName.toLowerCase() != currentName && senderName.toLowerCase() != currentId) {
      partnerName = senderName.trim();
    }

    if (partnerName.toLowerCase() == currentName || partnerName.toLowerCase() == currentId) {
      return; // Do not add current user as conversation partner
    }

    final cleanId = partnerName;
    final exists = state.any((item) =>
        item.id.toLowerCase() == cleanId.toLowerCase() ||
        item.partnerName.toLowerCase() == cleanId.toLowerCase());

    if (exists) {
      state = state.map((item) {
        if (item.id.toLowerCase() == cleanId.toLowerCase() ||
            item.partnerName.toLowerCase() == cleanId.toLowerCase()) {
          return item.copyWith(
            lastMessage: content,
            timeAgo: time,
            unreadCount: incrementUnread ? item.unreadCount + 1 : item.unreadCount,
            isTyping: false,
          );
        }
        return item;
      }).toList();
    } else {
      final newItem = ConversationItem(
        id: cleanId,
        partnerName: cleanId,
        avatarUrl: '',
        lastMessage: content,
        timeAgo: time,
        unreadCount: incrementUnread ? 1 : 0,
        isOnline: true,
      );
      state = [newItem, ...state];
    }
    _saveLocalCache();
  }

  void updateLastMessage(String partnerName, String content, String time, {bool incrementUnread = false}) {
    _updateWithIncomingMessage(partnerName, partnerName, content, time, incrementUnread: incrementUnread);
  }

  void updateTypingStatus(String conversationId, bool isTyping) {
    state = state.map((item) {
      if (item.id.toLowerCase() == conversationId.toLowerCase() || item.partnerName.toLowerCase() == conversationId.toLowerCase()) {
        return item.copyWith(isTyping: isTyping);
      }
      return item;
    }).toList();
  }

  void markAsRead(String conversationId) {
    state = state.map((item) {
      if (item.id.toLowerCase() == conversationId.toLowerCase() || item.partnerName.toLowerCase() == conversationId.toLowerCase()) {
        return item.copyWith(unreadCount: 0);
      }
      return item;
    }).toList();
    _saveLocalCache();
  }

  void addConversation(String partnerName, {String avatarUrl = ''}) {
    final cleanName = partnerName.trim();
    if (cleanName.isEmpty) return;

    final exists = state.any((item) => item.partnerName.toLowerCase() == cleanName.toLowerCase() || item.id.toLowerCase() == cleanName.toLowerCase());
    if (!exists) {
      final newItem = ConversationItem(
        id: cleanName,
        partnerName: cleanName,
        avatarUrl: avatarUrl,
        lastMessage: 'Tap to start direct prayer fellowship...',
        timeAgo: 'Just now',
        unreadCount: 0,
        isOnline: true,
      );
      state = [newItem, ...state];
    } else if (avatarUrl.isNotEmpty) {
      state = state.map((item) {
        if (item.partnerName.toLowerCase() == cleanName.toLowerCase() || item.id.toLowerCase() == cleanName.toLowerCase()) {
          return item.copyWith(avatarUrl: avatarUrl);
        }
        return item;
      }).toList();
    }
    _saveLocalCache();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}

final conversationsListProvider =
    StateNotifierProvider<ConversationsListNotifier, List<ConversationItem>>((ref) {
  final service = ref.watch(agoraChatServiceProvider);
  final firestoreService = ref.watch(chatFirestoreServiceProvider);
  return ConversationsListNotifier(service, firestoreService, ref);
});

// -----------------------------------------------------------------------------
// Fellowship 1-on-1 Chat Notifier & Provider
// -----------------------------------------------------------------------------
class FellowshipChatState {
  final List<AgoraChatMessageData> messages;
  final bool isPartnerTyping;

  const FellowshipChatState({
    required this.messages,
    this.isPartnerTyping = false,
  });

  FellowshipChatState copyWith({
    List<AgoraChatMessageData>? messages,
    bool? isPartnerTyping,
  }) {
    return FellowshipChatState(
      messages: messages ?? this.messages,
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
    );
  }
}

class FellowshipChatNotifier extends StateNotifier<FellowshipChatState> {
  final AgoraChatService _service;
  final ChatFirestoreService _firestoreService;
  final String partnerId;
  final Ref ref;
  StreamSubscription<AgoraChatMessageData>? _msgSub;
  StreamSubscription<AgoraTypingEvent>? _typingSub;
  StreamSubscription<AgoraReadAckEvent>? _readSub;
  StreamSubscription<List<AgoraChatMessageData>>? _firestoreMsgSub;

  FellowshipChatNotifier(this._service, this._firestoreService, this.partnerId, this.ref)
      : super(const FellowshipChatState(messages: [])) {
    _loadLocalCache();
    _initListeners();
    _markConversationRead();
  }

  Future<void> _loadLocalCache() async {
    final cached = await ChatLocalCacheService().loadMessages(partnerId);
    if (cached.isNotEmpty && state.messages.isEmpty) {
      state = state.copyWith(messages: cached);
    }
  }

  void _initListeners() {
    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    final chatId = ChatFirestoreService.getChatId(authProfile.name, partnerId);

    // Stream past and live messages from Cloud Firestore
    _firestoreMsgSub = _firestoreService.getMessagesStream(chatId, authProfile.id, currentUserName: authProfile.name).listen((firestoreMsgs) {
      if (firestoreMsgs.isNotEmpty) {
        state = state.copyWith(messages: firestoreMsgs);
        ChatLocalCacheService().saveMessages(partnerId, firestoreMsgs);
      }
    });

    _msgSub = _service.incomingMessages.listen((msg) {
      final isTarget = (msg.conversationId == partnerId || msg.senderId == partnerId || msg.senderName.toLowerCase() == partnerId.toLowerCase());
      if (isTarget) {
        final exists = state.messages.any((m) => m.id == msg.id);
        if (!exists) {
          state = state.copyWith(
            messages: [...state.messages, msg],
            isPartnerTyping: false,
          );
          ChatLocalCacheService().saveMessages(partnerId, state.messages);
        }
        _markConversationRead();
      }
      Future.microtask(() {
        ref.read(conversationsListProvider.notifier).updateLastMessage(
          msg.senderName.isNotEmpty ? msg.senderName : (msg.conversationId ?? partnerId),
          msg.content,
          msg.formattedTime,
          incrementUnread: !isTarget,
        );
      });
    });

    _typingSub = _service.typingEvents.listen((event) {
      if (event.conversationId == partnerId || event.userId == partnerId) {
        state = state.copyWith(isPartnerTyping: event.isTyping);
      }
    });

    _readSub = _service.readAckEvents.listen((event) {
      if (event.conversationId == partnerId) {
        final updatedMsgs = state.messages.map((m) {
          if (m.isMe) {
            return m.copyWith(isRead: true);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updatedMsgs);
        ChatLocalCacheService().saveMessages(partnerId, updatedMsgs);
      }
    });
  }

  void _markConversationRead() {
    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    final chatId = ChatFirestoreService.getChatId(authProfile.name, partnerId);

    _service.sendConversationReadAck(partnerId);
    _firestoreService.markAsRead(chatId: chatId, currentUserId: authProfile.id);

    Future.microtask(() {
      ref.read(conversationsListProvider.notifier).markAsRead(partnerId);
    });
  }

  Future<void> sendTypingSignal(bool isTyping) async {
    await _service.sendTypingSignal(partnerId, isTyping);
  }

  Future<void> sendMessage(String text, {String? senderId, String senderName = 'You'}) async {
    if (text.trim().isEmpty) return;
    await sendTypingSignal(false);

    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    final activeSenderId = senderId ?? authProfile.id;
    final activeSenderName = senderName != 'You' ? senderName : authProfile.name;

    final sentData = await _service.sendDirectMessage(
      recipientUserId: partnerId,
      content: text.trim(),
      senderId: activeSenderId,
      senderName: activeSenderName,
    );

    // Save to Cloud Firestore
    await _firestoreService.sendMessage(
      senderId: activeSenderId,
      senderName: activeSenderName,
      recipientName: partnerId,
      content: text.trim(),
      senderAvatar: authProfile.avatarUrl,
    );

    final exists = state.messages.any((m) => m.id == sentData.id);
    if (!exists) {
      state = state.copyWith(
        messages: [...state.messages, sentData],
      );
      ChatLocalCacheService().saveMessages(partnerId, state.messages);
    }

    ref.read(conversationsListProvider.notifier).updateLastMessage(
      partnerId,
      text.trim(),
      sentData.formattedTime,
      incrementUnread: false,
    );
  }

  void toggleReaction(String messageId, String emoji) {
    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    final chatId = ChatFirestoreService.getChatId(authProfile.name, partnerId);

    final updatedMessages = state.messages.map((m) {
      if (m.id == messageId) {
        final currentReactions = List<String>.from(m.reactions);
        if (currentReactions.contains(emoji)) {
          currentReactions.remove(emoji);
        } else {
          currentReactions.add(emoji);
        }
        return m.copyWith(reactions: currentReactions);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updatedMessages);
    ChatLocalCacheService().saveMessages(partnerId, updatedMessages);

    _firestoreService.toggleReaction(chatId: chatId, messageId: messageId, emoji: emoji);
  }

  @override
  void dispose() {
    sendTypingSignal(false);
    _msgSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _firestoreMsgSub?.cancel();
    super.dispose();
  }
}

final fellowshipChatProvider = StateNotifierProvider.family<
    FellowshipChatNotifier, FellowshipChatState, String>((ref, partnerId) {
  final service = ref.watch(agoraChatServiceProvider);
  final firestoreService = ref.watch(chatFirestoreServiceProvider);
  return FellowshipChatNotifier(service, firestoreService, partnerId, ref);
});

// -----------------------------------------------------------------------------
// Live Worship Room Chat Notifier & Provider
// -----------------------------------------------------------------------------
class LiveRoomChatNotifier extends StateNotifier<List<AgoraChatMessageData>> {
  final AgoraChatService _service;
  final String roomId;
  StreamSubscription<AgoraChatMessageData>? _sub;

  LiveRoomChatNotifier(this._service, this.roomId)
      : super(_initialRoomMessages(roomId)) {
    _init();
  }

  static List<AgoraChatMessageData> _initialRoomMessages(String roomId) {
    final now = DateTime.now();
    return [
      AgoraChatMessageData(
        id: 'room-1',
        senderId: 'user_maya',
        senderName: 'Sister Maya',
        content: 'Hallelujah! Amen to John 15!',
        timestamp: now.subtract(const Duration(minutes: 12)),
        isMe: false,
        conversationId: roomId,
      ),
      AgoraChatMessageData(
        id: 'room-2',
        senderId: 'user_david',
        senderName: 'Brother David',
        content: 'Praying for all saints tuned in tonight.',
        timestamp: now.subtract(const Duration(minutes: 8)),
        isMe: false,
        conversationId: roomId,
      ),
      AgoraChatMessageData(
        id: 'room-3',
        senderId: 'user_grace',
        senderName: 'Sister Grace',
        content: 'Praise God for His abiding mercy.',
        timestamp: now.subtract(const Duration(minutes: 4)),
        isMe: false,
        conversationId: roomId,
      ),
      AgoraChatMessageData(
        id: 'room-4',
        senderId: 'user_joseph',
        senderName: 'Elder Joseph',
        content: 'Amen! The True Vine feeds us.',
        timestamp: now.subtract(const Duration(minutes: 1)),
        isMe: false,
        conversationId: roomId,
      ),
    ];
  }

  void _init() {
    _service.joinChatRoom(roomId);
    _sub = _service.incomingMessages.listen((msg) {
      if (msg.conversationId == roomId) {
        state = [...state, msg];
      }
    });
  }

  Future<void> sendRoomMessage(String text, {String senderName = 'You'}) async {
    if (text.trim().isEmpty) return;
    final sentData = await _service.sendRoomMessage(
      roomId: roomId,
      content: text.trim(),
      senderName: senderName,
    );

    state = [...state, sentData];
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.leaveChatRoom(roomId);
    super.dispose();
  }
}

final liveRoomChatProvider = StateNotifierProvider.family<
    LiveRoomChatNotifier, List<AgoraChatMessageData>, String>((ref, roomId) {
  final service = ref.watch(agoraChatServiceProvider);
  return LiveRoomChatNotifier(service, roomId);
});
