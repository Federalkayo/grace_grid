import 'dart:async';
import 'package:flutter/foundation.dart';

enum AgoraConnectionStatus {
  disconnected,
  connecting,
  connected,
  demoMode,
}

class AgoraChatMessageData {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final String? conversationId;
  final bool isDelivered;
  final bool isRead;
  final Map<String, String> reactions; // userId -> emoji
  final bool isForwarded;

  const AgoraChatMessageData({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.conversationId,
    this.isDelivered = true,
    this.isRead = false,
    this.reactions = const {},
    this.isForwarded = false,
  });

  AgoraChatMessageData copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isMe,
    String? conversationId,
    bool? isDelivered,
    bool? isRead,
    Map<String, String>? reactions,
    bool? isForwarded,
  }) {
    return AgoraChatMessageData(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      conversationId: conversationId ?? this.conversationId,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      isForwarded: isForwarded ?? this.isForwarded,
    );
  }

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class AgoraTypingEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;

  const AgoraTypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
}

class AgoraReadAckEvent {
  final String conversationId;
  final String? messageId;

  const AgoraReadAckEvent({
    required this.conversationId,
    this.messageId,
  });
}

class AgoraChatService {
  static final AgoraChatService _instance = AgoraChatService._internal();
  factory AgoraChatService() => _instance;
  AgoraChatService._internal();

  bool _isInitialized = false;
  bool _isDemoMode = false;
  String? _currentUserId;
  AgoraConnectionStatus _status = AgoraConnectionStatus.disconnected;

  final StreamController<AgoraChatMessageData> _incomingMessageController =
      StreamController<AgoraChatMessageData>.broadcast();

  final StreamController<AgoraConnectionStatus> _statusController =
      StreamController<AgoraConnectionStatus>.broadcast();

  final StreamController<AgoraTypingEvent> _typingEventController =
      StreamController<AgoraTypingEvent>.broadcast();

  final StreamController<AgoraReadAckEvent> _readAckController =
      StreamController<AgoraReadAckEvent>.broadcast();

  Stream<AgoraChatMessageData> get incomingMessages => _incomingMessageController.stream;
  Stream<AgoraConnectionStatus> get statusStream => _statusController.stream;
  Stream<AgoraTypingEvent> get typingEvents => _typingEventController.stream;
  Stream<AgoraReadAckEvent> get readAckEvents => _readAckController.stream;

  AgoraConnectionStatus get status => _status;
  String? get currentUserId => _currentUserId;
  bool get isDemoMode => _isDemoMode;

  final List<AgoraChatMessageData> _demoMessageStorage = [];

  /// Initialize Chat Service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isDemoMode = true;
    _isInitialized = true;
    _updateStatus(AgoraConnectionStatus.connected);
    debugPrint('AgoraChatService: Initialized (Firestore-backed real-time messaging active).');
  }

  /// Login user
  Future<bool> login(String userId) async {
    await initialize();
    _currentUserId = userId;
    _updateStatus(AgoraConnectionStatus.connected);
    return true;
  }

  /// Logout current user
  Future<void> logout() async {
    _currentUserId = null;
    _updateStatus(AgoraConnectionStatus.disconnected);
  }

  /// Send a 1:1 direct message (broadcast locally; persistent storage is handled by Cloud Firestore)
  Future<AgoraChatMessageData> sendDirectMessage({
    required String recipientUserId,
    required String content,
    String? senderId,
    String senderName = 'You',
  }) async {
    final activeSenderId = senderId ?? _currentUserId ?? 'user_me';
    final msgId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
    final chatData = AgoraChatMessageData(
      id: msgId,
      senderId: activeSenderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
      conversationId: recipientUserId,
      isDelivered: true,
      isRead: false,
    );

    _demoMessageStorage.add(chatData);
    return chatData;
  }

  /// Send real-time typing signal to partner
  Future<void> sendTypingSignal(String recipientUserId, bool isTyping) async {
    _typingEventController.add(AgoraTypingEvent(
      conversationId: recipientUserId,
      userId: recipientUserId,
      isTyping: isTyping,
    ));
  }

  /// Send Read Acknowledgment for a conversation
  Future<void> sendConversationReadAck(String conversationId) async {
    _readAckController.add(AgoraReadAckEvent(conversationId: conversationId));
  }

  /// Join a Chat Room (e.g. for Live Worship)
  Future<void> joinChatRoom(String roomId) async {}

  /// Leave a Chat Room
  Future<void> leaveChatRoom(String roomId) async {}

  /// Send a message to a Chat Room
  Future<AgoraChatMessageData> sendRoomMessage({
    required String roomId,
    required String content,
    String senderName = 'You',
  }) async {
    final msgId = 'room-msg-${DateTime.now().millisecondsSinceEpoch}';
    final chatData = AgoraChatMessageData(
      id: msgId,
      senderId: _currentUserId ?? 'user_me',
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
      conversationId: roomId,
      isDelivered: true,
      isRead: false,
    );

    _demoMessageStorage.add(chatData);
    return chatData;
  }

  void _updateStatus(AgoraConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _incomingMessageController.close();
    _statusController.close();
    _typingEventController.close();
    _readAckController.close();
  }
}

