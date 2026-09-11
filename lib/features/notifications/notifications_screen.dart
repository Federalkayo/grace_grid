import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import 'models/app_notification_model.dart';
import 'providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.read);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => ref.read(notificationsActionsProvider).markAllRead(notifications),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.w600),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryContainer),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Couldn\'t load notifications right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () {
                  if (!notification.read) {
                    ref.read(notificationsActionsProvider).markRead(notification.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAmen = notification.type == 'amen';

    return GlassCard(
      level: notification.read ? GlassLevel.level1 : GlassLevel.level2,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.surfaceHigh,
            backgroundImage:
                (notification.actorAvatar != null && notification.actorAvatar!.isNotEmpty)
                    ? NetworkImage(notification.actorAvatar!)
                    : null,
            child: (notification.actorAvatar == null || notification.actorAvatar!.isEmpty)
                ? Text(
                    notification.actorName.isNotEmpty ? notification.actorName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isAmen ? Icons.favorite : Icons.mode_comment_outlined,
                      size: 14,
                      color: isAmen ? AppTheme.errorContainer : AppTheme.primaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notification.message,
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (notification.postSnippet != null && notification.postSnippet!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"${notification.postSnippet}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  notification.timeAgo,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (!notification.read)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 48, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'When someone says Amen to or comments on your posts, you\'ll see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
