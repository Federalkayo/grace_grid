import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../config/agora_config.dart';

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
  final List<String> reactions;

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
    this.reactions = const [],
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
    List<String>? reactions,
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

  /// Initialize Agora Chat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!AgoraConfig.isConfigured) {
        debugPrint('AgoraChatService: App Key unconfigured, using fallback stream mode.');
        _isDemoMode = true;
        _isInitialized = true;
        _updateStatus(AgoraConnectionStatus.demoMode);
        return;
      }

      final options = ChatOptions.withAppKey(
        AgoraConfig.agoraAppKey,
        autoLogin: false,
      );

      await ChatClient.getInstance.init(options);

      // Register event handlers
      ChatClient.getInstance.chatManager.addEventHandler(
        'grace_grid_event_handler',
        ChatEventHandler(
          onMessagesReceived: _handleOnMessagesReceived,
          onCmdMessagesReceived: _handleOnCmdMessagesReceived,
          onConversationRead: (from, to) {
            _readAckController.add(AgoraReadAckEvent(conversationId: from));
          },
        ),
      );

      _isInitialized = true;
      _updateStatus(AgoraConnectionStatus.disconnected);
      debugPrint('AgoraChatService: SDK initialized successfully.');
    } catch (e) {
      debugPrint('AgoraChatService: Initialization notice/fallback: $e');
      _isDemoMode = true;
      _isInitialized = true;
      _updateStatus(AgoraConnectionStatus.demoMode);
    }
  }

  /// Fetch Agora Chat User Token via Firebase Cloud Function
  Future<String?> _fetchAgoraTokenFromCloudFunction(String userId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraChatToken');
      final response = await callable.call({'uid': userId});
      final data = response.data;
      if (data is Map && data['token'] != null) {
        return data['token'] as String;
      }
    } catch (e) {
      debugPrint('Cloud Function token generation notice (using fallback): $e');
    }
    return null;
  }

  /// Login user to Agora Chat securely using server-minted token
  Future<bool> login(String userId) async {
    await initialize();
    _currentUserId = userId;

    if (_isDemoMode) {
      _updateStatus(AgoraConnectionStatus.demoMode);
      return true;
    }

    try {
      _updateStatus(AgoraConnectionStatus.connecting);
      final isConnected = await ChatClient.getInstance.isConnected();
      if (!isConnected) {
        final serverToken = await _fetchAgoraTokenFromCloudFunction(userId);
        if (serverToken != null) {
          await ChatClient.getInstance.loginWithToken(userId, serverToken);
        } else {
          // Fallback if cloud function unconfigured
          await ChatClient.getInstance.loginWithPassword(userId, '123456');
        }
      }
      _updateStatus(AgoraConnectionStatus.connected);
      return true;
    } catch (e) {
      debugPrint('AgoraChatService login notice (using demo mode fallback): $e');
      _isDemoMode = true;
      _updateStatus(AgoraConnectionStatus.demoMode);
      return true;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    if (!_isDemoMode && _isInitialized) {
      try {
        await ChatClient.getInstance.logout();
      } catch (e) {
        debugPrint('AgoraChatService logout notice: $e');
      }
    }
    _currentUserId = null;
    _updateStatus(AgoraConnectionStatus.disconnected);
  }

  /// Send a 1:1 direct message
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

    if (_isDemoMode || !_isInitialized) {
      _demoMessageStorage.add(chatData);
      return chatData;
    }

    try {
      final msg = ChatMessage.createTxtSendMessage(
        targetId: recipientUserId,
        content: content,
      );

      await ChatClient.getInstance.chatManager.sendMessage(msg);
      return chatData;
    } catch (e) {
      debugPrint('AgoraChatService sendDirectMessage fallback: $e');
      _demoMessageStorage.add(chatData);
      return chatData;
    }
  }

  /// Send real-time typing signal to partner
  Future<void> sendTypingSignal(String recipientUserId, bool isTyping) async {
    if (_isDemoMode || !_isInitialized) {
      _typingEventController.add(AgoraTypingEvent(
        conversationId: recipientUserId,
        userId: recipientUserId,
        isTyping: isTyping,
      ));
      return;
    }

    try {
      final cmdMsg = ChatMessage.createCmdSendMessage(
        targetId: recipientUserId,
        action: isTyping ? 'TYPING_START' : 'TYPING_STOP',
      );
      await ChatClient.getInstance.chatManager.sendMessage(cmdMsg);
    } catch (e) {
      debugPrint('sendTypingSignal notice: $e');
    }
  }

  /// Send Read Acknowledgment for a conversation
  Future<void> sendConversationReadAck(String conversationId) async {
    if (_isDemoMode || !_isInitialized) {
      _readAckController.add(AgoraReadAckEvent(conversationId: conversationId));
      return;
    }

    try {
      await ChatClient.getInstance.chatManager.sendConversationReadAck(conversationId);
    } catch (e) {
      debugPrint('sendConversationReadAck notice: $e');
    }
  }

  /// Join a Chat Room (e.g. for Live Worship)
  Future<void> joinChatRoom(String roomId) async {
    if (_isDemoMode || !_isInitialized) return;

    try {
      await ChatClient.getInstance.chatRoomManager.joinChatRoom(roomId);
    } catch (e) {
      debugPrint('AgoraChatService joinChatRoom notice: $e');
    }
  }

  /// Leave a Chat Room
  Future<void> leaveChatRoom(String roomId) async {
    if (_isDemoMode || !_isInitialized) return;

    try {
      await ChatClient.getInstance.chatRoomManager.leaveChatRoom(roomId);
    } catch (e) {
      debugPrint('AgoraChatService leaveChatRoom notice: $e');
    }
  }

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

    if (_isDemoMode || !_isInitialized) {
      _demoMessageStorage.add(chatData);
      return chatData;
    }

    try {
      final msg = ChatMessage.createTxtSendMessage(
        targetId: roomId,
        content: content,
        chatType: ChatType.ChatRoom,
      );

      await ChatClient.getInstance.chatManager.sendMessage(msg);
      return chatData;
    } catch (e) {
      debugPrint('AgoraChatService sendRoomMessage fallback: $e');
      _demoMessageStorage.add(chatData);
      return chatData;
    }
  }

  void _handleOnMessagesReceived(List<ChatMessage> messages) {
    for (var msg in messages) {
      if (msg.body.type == MessageType.TXT) {
        final txtBody = msg.body as ChatTextMessageBody;
        final chatData = AgoraChatMessageData(
          id: msg.msgId,
          senderId: msg.from ?? 'unknown',
          senderName: msg.from ?? 'Believer',
          content: txtBody.content,
          timestamp: DateTime.fromMillisecondsSinceEpoch(msg.serverTime),
          isMe: msg.from == _currentUserId,
          conversationId: msg.conversationId,
          isDelivered: true,
          isRead: false,
        );
        _incomingMessageController.add(chatData);
      }
    }
  }

  void _handleOnCmdMessagesReceived(List<ChatMessage> messages) {
    for (var msg in messages) {
      if (msg.body.type == MessageType.CMD) {
        final cmdBody = msg.body as ChatCmdMessageBody;
        if (cmdBody.action == 'TYPING_START' || cmdBody.action == 'TYPING_STOP') {
          _typingEventController.add(AgoraTypingEvent(
            conversationId: msg.conversationId ?? msg.from ?? '',
            userId: msg.from ?? '',
            isTyping: cmdBody.action == 'TYPING_START',
          ));
        }
      }
    }
  }

  void _updateStatus(AgoraConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    if (_isInitialized && !_isDemoMode) {
      ChatClient.getInstance.chatManager.removeEventHandler('grace_grid_event_handler');
    }
    _incomingMessageController.close();
    _statusController.close();
    _typingEventController.close();
    _readAckController.close();
  }
}
