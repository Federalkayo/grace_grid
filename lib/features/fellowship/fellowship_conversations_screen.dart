import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/agora_chat_provider.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../feed/providers/feed_provider.dart';
import '../../core/data/mock_community_data.dart';
import 'fellowship_chat_screen.dart';

class FellowshipConversationsScreen extends ConsumerStatefulWidget {
  const FellowshipConversationsScreen({super.key});

  @override
  ConsumerState<FellowshipConversationsScreen> createState() =>
      _FellowshipConversationsScreenState();
}

class _FellowshipConversationsScreenState
    extends ConsumerState<FellowshipConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStartNewChatDialog(BuildContext context) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final feedState = ref.watch(feedProvider);
            final currentProfile = ref.watch(mockAuthNotifierProvider).profile;
            // Collect unique active believers from feed posts & stories (excluding current user)
            final activeBelieversMap = <String, Map<String, String>>{}; // id -> {name, avatar}
            for (final p in feedState.posts) {
              final pid = p.authorId.isNotEmpty ? p.authorId : p.authorName;
              if (p.authorName.isNotEmpty &&
                  p.authorName.toLowerCase() != currentProfile.name.toLowerCase() &&
                  pid.toLowerCase() != currentProfile.id.toLowerCase()) {
                activeBelieversMap[pid] = {
                  'name': p.authorName,
                  'avatar': p.authorAvatar ?? '',
                };
              }
            }
            for (final s in feedState.stories) {
              final sid = s.userName.replaceAll(' ', '_').toLowerCase();
              if (s.userName.isNotEmpty &&
                  s.userName.toLowerCase() != currentProfile.name.toLowerCase() &&
                  sid != currentProfile.id.toLowerCase()) {
                activeBelieversMap.putIfAbsent(sid, () => {
                  'name': s.userName,
                  'avatar': s.userAvatar ?? '',
                });
              }
            }

            final filter = nameController.text.trim().toLowerCase();
            final filteredBelievers = activeBelieversMap.entries.where((e) {
              if (filter.isEmpty) return true;
              return e.value['name']!.toLowerCase().contains(filter) || e.key.toLowerCase().contains(filter);
            }).toList();

            final isKeyboardOpen = MediaQuery.of(ctx).viewInsets.bottom > 0;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldStrokeAlpha25,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.forum_outlined,
                          color: AppTheme.primaryContainer,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Start 1:1 Direct Fellowship Chat',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Search registered believers or enter any custom handle below:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search or type name e.g. Sister Deborah',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.primaryContainer,
                          size: 20,
                        ),
                        suffixIcon: nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  nameController.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surfaceLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.emeraldStrokeAlpha25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (activeBelieversMap.isNotEmpty) ...[
                      const Text(
                        'Active Community Believers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: isKeyboardOpen ? 110 : 200,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredBelievers.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppTheme.emeraldStrokeAlpha15,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredBelievers[index];
                            final partnerId = item.key;
                            final name = item.value['name'] ?? partnerId;
                            final avatar = item.value['avatar'] ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              leading: Builder(
                                builder: (context) {
                                  final avatarImg = getAvatarImageProvider(
                                    avatar,
                                  );
                                  return CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primaryContainer
                                        .withValues(alpha: 0.2),
                                    backgroundImage: avatarImg,
                                    child: avatarImg == null
                                        ? Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryContainer,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryContainer,
                                  foregroundColor: AppTheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  ref
                                      .read(conversationsListProvider.notifier)
                                      .addConversation(partnerId, partnerName: name, avatarUrl: avatar);
                                  Navigator.pop(ctx);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FellowshipChatScreen(
                                            partnerId: partnerId,
                                            partnerName: name,
                                            partnerAvatar: avatar,
                                          ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Chat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            foregroundColor: AppTheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            final targetName = nameController.text.trim();
                            if (targetName.isNotEmpty) {
                              final targetId = targetName.replaceAll(' ', '_').toLowerCase();
                              ref
                                  .read(conversationsListProvider.notifier)
                                  .addConversation(targetId, partnerName: targetName);
                              Navigator.pop(ctx);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FellowshipChatScreen(
                                    partnerId: targetId,
                                    partnerName: targetName,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Start Chat',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsListProvider);

    final filteredConversations = conversations.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return item.partnerName.toLowerCase().contains(query) ||
          item.lastMessage.toLowerCase().contains(query);
    }).toList();

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
          'Fellowship Messages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: AppTheme.primaryContainer,
                ),
                SizedBox(width: 4),
                Text(
                  'Private 1:1 Connection',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Search believers or messages...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryContainer,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Conversations List
          Expanded(
            child: filteredConversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 48,
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No direct messages found',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final item = filteredConversations[index];

                      final feedState = ref.watch(feedProvider);
                      String displayPartnerName = item.partnerName;
                      String effectiveAvatarUrl = item.avatarUrl;

                      final isRawId =
                          item.partnerName.length > 20 ||
                          (item.partnerName.startsWith('Gs') &&
                              !item.partnerName.contains(' '));

                      // 1. Resolve against feed posts & stories
                      for (final p in feedState.posts) {
                        final matchName =
                            p.authorName.toLowerCase() ==
                            item.partnerName.toLowerCase();
                        final matchId =
                            p.authorId.isNotEmpty &&
                            p.authorId.toLowerCase() ==
                                item.partnerName.toLowerCase();
                        if (matchName || matchId) {
                          if (displayPartnerName.isEmpty || isRawId)
                            displayPartnerName = p.authorName;
                          if (effectiveAvatarUrl.isEmpty &&
                              (p.authorAvatar ?? '').isNotEmpty)
                            effectiveAvatarUrl = p.authorAvatar!;
                          break;
                        }
                      }

                      if (effectiveAvatarUrl.isEmpty || isRawId) {
                        for (final s in feedState.stories) {
                          final matchName =
                              s.userName.toLowerCase() ==
                              item.partnerName.toLowerCase();
                          if (matchName) {
                            if (displayPartnerName.isEmpty || isRawId)
                              displayPartnerName = s.userName;
                            if (effectiveAvatarUrl.isEmpty &&
                                (s.userAvatar ?? '').isNotEmpty)
                              effectiveAvatarUrl = s.userAvatar!;
                            break;
                          }
                        }
                      }

                      // 2. Fallback against MockCommunityData stories
                      if (effectiveAvatarUrl.isEmpty || isRawId) {
                        for (final mockS
                            in MockCommunityData.getMockStories()) {
                          if (mockS.userName.toLowerCase() ==
                                  item.partnerName.toLowerCase() ||
                              mockS.userName.toLowerCase().contains(
                                item.partnerName.toLowerCase(),
                              )) {
                            if (isRawId) displayPartnerName = mockS.userName;
                            if (effectiveAvatarUrl.isEmpty &&
                                (mockS.userAvatar ?? '').isNotEmpty)
                              effectiveAvatarUrl = mockS.userAvatar!;
                            break;
                          }
                        }
                      }

                      if (isRawId &&
                          (displayPartnerName == item.partnerName ||
                              displayPartnerName.length > 20)) {
                        displayPartnerName =
                            'Believer ${item.partnerName.substring(0, 6)}';
                      }

                      // 3. Fallback default avatar image if still empty
                      if (effectiveAvatarUrl.isEmpty) {
                        final defaultAvatars = [
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
                          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
                        ];
                        final hash =
                            displayPartnerName.hashCode.abs() %
                            defaultAvatars.length;
                        effectiveAvatarUrl = defaultAvatars[hash];
                      }

                      final avatarImg = getAvatarImageProvider(
                        effectiveAvatarUrl,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: GlassCard(
                          level: GlassLevel.level1,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryContainer
                                      .withValues(alpha: 0.2),
                                  backgroundImage: avatarImg,
                                  child: avatarImg == null
                                      ? Text(
                                          displayPartnerName.isNotEmpty
                                              ? displayPartnerName[0]
                                                    .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: AppTheme.primaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                ),
                                if (item.isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryContainer,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.surfaceLow,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayPartnerName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.timeAgo,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.isTyping
                                          ? 'typing...'
                                          : item.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: item.isTyping
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                        fontWeight: item.unreadCount > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: item.isTyping
                                            ? AppTheme.primaryContainer
                                            : (item.unreadCount > 0
                                                  ? AppTheme.primary
                                                  : AppTheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ),
                                  if (item.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          9999,
                                        ),
                                      ),
                                      child: Text(
                                        '${item.unreadCount}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            onTap: () {
                              ref
                                  .read(conversationsListProvider.notifier)
                                  .markAsRead(item.id);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FellowshipChatScreen(
                                    partnerId: item.id,
                                    partnerName: displayPartnerName,
                                    partnerAvatar: item.avatarUrl,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: AppTheme.onPrimary,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text(
          'New Fellowship Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showStartNewChatDialog(context),
      ),
    );
  }
}
