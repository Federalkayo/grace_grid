import 'package:cloud_firestore/cloud_firestore.dart';

/// A single real notification — someone said Amen to, or commented on,
/// one of the current user's posts. Backs the Notifications screen and
/// the bell-icon badge.
class AppNotification {
  final String id;
  final String type; // 'amen' | 'comment'
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final String postId;
  final String? postSnippet;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    required this.postId,
    this.postSnippet,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> data, String id) {
    final rawTimestamp = data['createdAt'];
    DateTime created;
    if (rawTimestamp is Timestamp) {
      created = rawTimestamp.toDate();
    } else {
      // A brand-new notification hasn't had its serverTimestamp fill in
      // yet on this device's first snapshot — treat it as "now" rather
      // than crashing or sorting it to the wrong end of the list.
      created = DateTime.now();
    }

    return AppNotification(
      id: id,
      type: data['type'] as String? ?? 'amen',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? 'Someone',
      actorAvatar: data['actorAvatar'] as String?,
      postId: data['postId'] as String? ?? '',
      postSnippet: data['postSnippet'] as String?,
      createdAt: created,
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'actorId': actorId,
      'actorName': actorName,
      'actorAvatar': actorAvatar,
      'postId': postId,
      'postSnippet': postSnippet,
      'createdAt': FieldValue.serverTimestamp(),
      'read': read,
    };
  }

  String get message {
    switch (type) {
      case 'comment':
        return '$actorName commented on your post';
      case 'amen':
      default:
        return '$actorName said Amen to your post';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
