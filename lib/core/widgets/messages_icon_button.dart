import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/agora_chat_provider.dart';
import '../theme/app_theme.dart';

/// The "Fellowship Messages" icon used in the Feed and Profile app bars,
/// with a small unread-count badge overlaid on it. Drop-in replacement for
/// the plain `IconButton(icon: Icons.forum_outlined, ...)` that was there
/// before — same icon, same tooltip, same onPressed contract, so nothing
/// else about those screens needs to change.
class MessagesIconButton extends ConsumerWidget {
  const MessagesIconButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Fellowship Messages',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(totalUnreadMessagesProvider);
    final hasUnread = unreadCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.forum_outlined, color: AppTheme.primaryContainer),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
        if (hasUnread)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.surfaceLow, width: 1.5),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
