import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/feed_firestore_service.dart';
import '../models/app_notification_model.dart';

final _feedFirestoreServiceProvider = Provider<FeedFirestoreService>((ref) => FeedFirestoreService());

/// Live stream of the current user's notifications (Amens & comments on
/// their posts), newest first. Same guest-id fallback ('user_me') the
/// rest of the feed uses, so a signed-out browsing session and a signed-in
/// one don't silently point at two different notification inboxes.
final notificationsListProvider = StreamProvider<List<AppNotification>>((ref) {
  final profile = ref.watch(authNotifierProvider).profile;
  final userId = profile.id.isNotEmpty ? profile.id : 'user_me';
  final service = ref.watch(_feedFirestoreServiceProvider);
  return service.getNotificationsStream(userId);
});

/// Unread count for the bell-icon badge.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsListProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.read).length,
    orElse: () => 0,
  );
});

final notificationsActionsProvider = Provider<NotificationsActions>((ref) {
  return NotificationsActions(ref);
});

class NotificationsActions {
  NotificationsActions(this._ref);
  final Ref _ref;

  String get _userId {
    final id = _ref.read(authNotifierProvider).profile.id;
    return id.isNotEmpty ? id : 'user_me';
  }

  Future<void> markRead(String notificationId) {
    final service = _ref.read(_feedFirestoreServiceProvider);
    return service.markNotificationRead(_userId, notificationId);
  }

  Future<void> markAllRead(List<AppNotification> notifications) {
    final service = _ref.read(_feedFirestoreServiceProvider);
    final unreadIds = notifications.where((n) => !n.read).map((n) => n.id).toList();
    return service.markAllNotificationsRead(_userId, unreadIds);
  }
}
