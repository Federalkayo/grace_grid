import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/agora_chat_provider.dart';
import '../services/agora_chat_service.dart';

class ChatLocalCacheService {
  static final ChatLocalCacheService _instance = ChatLocalCacheService._internal();
  factory ChatLocalCacheService() => _instance;
  ChatLocalCacheService._internal();

  Directory? _appDocDir;

  Future<Directory?> _getDir() async {
    if (_appDocDir != null) return _appDocDir;
    try {
      _appDocDir = await getApplicationDocumentsDirectory();
      return _appDocDir;
    } catch (e) {
      debugPrint('ChatLocalCacheService getDir notice: $e');
      return null;
    }
  }

  /// Save conversations list to local disk
  Future<void> saveConversations(String userId, List<ConversationItem> items) async {
    try {
      final dir = await _getDir();
      if (dir == null) return;
      final cleanUser = userId.trim().toLowerCase();
      if (cleanUser.isEmpty) return;

      final file = File('${dir.path}/fellowship_conversations_$cleanUser.json');
      final listJson = items.map((c) => {
        'id': c.id,
        'partnerName': c.partnerName,
        'avatarUrl': c.avatarUrl,
        'lastMessage': c.lastMessage,
        'timeAgo': c.timeAgo,
        'unreadCount': c.unreadCount,
        'isOnline': c.isOnline,
      }).toList();

      await file.writeAsString(jsonEncode(listJson));
    } catch (e) {
      debugPrint('saveConversations error: $e');
    }
  }

  /// Load conversations list from local disk
  Future<List<ConversationItem>> loadConversations(String userId) async {
    try {
      final dir = await _getDir();
      if (dir == null) return [];
      final cleanUser = userId.trim().toLowerCase();
      if (cleanUser.isEmpty) return [];

      final file = File('${dir.path}/fellowship_conversations_$cleanUser.json');
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);

      return list.map((json) => ConversationItem(
        id: (json['id'] ?? '').toString(),
        partnerName: (json['partnerName'] ?? '').toString(),
        avatarUrl: (json['avatarUrl'] ?? '').toString(),
        lastMessage: (json['lastMessage'] ?? '').toString(),
        timeAgo: (json['timeAgo'] ?? '').toString(),
        unreadCount: json['unreadCount'] ?? 0,
        isOnline: json['isOnline'] ?? true,
      )).toList();
    } catch (e) {
      debugPrint('loadConversations error: $e');
      return [];
    }
  }

  /// Save chat messages for a specific partner/chatId to local disk
  Future<void> saveMessages(String chatId, List<AgoraChatMessageData> messages) async {
    try {
      final dir = await _getDir();
      if (dir == null) return;

      final cleanId = chatId.trim().toLowerCase();
      final file = File('${dir.path}/fellowship_chat_$cleanId.json');

      final listJson = messages.map((m) => {
        'id': m.id,
        'senderId': m.senderId,
        'senderName': m.senderName,
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
        'isMe': m.isMe,
        'conversationId': m.conversationId,
        'isDelivered': m.isDelivered,
        'isRead': m.isRead,
        'reactions': m.reactions,
      }).toList();

      await file.writeAsString(jsonEncode(listJson));
    } catch (e) {
      debugPrint('saveMessages error: $e');
    }
  }

  /// Load chat messages for a specific partner/chatId from local disk
  Future<List<AgoraChatMessageData>> loadMessages(String chatId) async {
    try {
      final dir = await _getDir();
      if (dir == null) return [];

      final cleanId = chatId.trim().toLowerCase();
      final file = File('${dir.path}/fellowship_chat_$cleanId.json');
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);

      return list.map((json) {
        final dt = DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now();
        return AgoraChatMessageData(
          id: (json['id'] ?? '').toString(),
          senderId: (json['senderId'] ?? '').toString(),
          senderName: (json['senderName'] ?? '').toString(),
          content: (json['content'] ?? '').toString(),
          timestamp: dt,
          isMe: json['isMe'] ?? false,
          conversationId: json['conversationId']?.toString(),
          isDelivered: json['isDelivered'] ?? true,
          isRead: json['isRead'] ?? false,
          reactions: List<String>.from(json['reactions'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('loadMessages error: $e');
      return [];
    }
  }
}
