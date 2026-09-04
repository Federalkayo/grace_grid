import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_buttons.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../../core/data/mock_community_data.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../auth/login_signup_modal.dart';

class SanctuaryCommunityFeedScreen extends ConsumerStatefulWidget {
  const SanctuaryCommunityFeedScreen({super.key});

  @override
  ConsumerState<SanctuaryCommunityFeedScreen> createState() => _SanctuaryCommunityFeedScreenState();
}

class _SanctuaryCommunityFeedScreenState extends ConsumerState<SanctuaryCommunityFeedScreen> {
  String _selectedCategory = 'All';
  late List<FeedPost> _posts;

  @override
  void initState() {
    super.initState();
    _posts = MockCommunityData.getMockPosts();
  }

  void _handleProtectedAction({required String actionTitle, required VoidCallback onAuthenticated}) {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: actionTitle);
    } else {
      onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _selectedCategory == 'All'
        ? _posts
        : _posts.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.dynamic_feed, color: AppTheme.primaryContainer, size: 22),
            const SizedBox(width: 8),
            Text(
              'Community Feed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.onSurfaceVariant),
            onPressed: () => _handleProtectedAction(
              actionTitle: 'view notifications',
              onAuthenticated: () {},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: AppTheme.onPrimary,
        icon: const Icon(Icons.edit_square, size: 18),
        label: const Text(
          'Share Testimony',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _handleProtectedAction(
          actionTitle: 'post in Community',
          onAuthenticated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Testimony compose opened!')),
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Prayer Wall', 'Testimony', 'Reflection'].map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TopicFilterChip(
                    label: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Posts List
          ...filteredPosts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GlassCard(
                level: GlassLevel.level2,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                          child: Text(
                            post.authorName[0],
                            style: const TextStyle(
                              color: AppTheme.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                '${post.authorTitle} • ${post.timeAgo}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
                          ),
                          child: Text(
                            post.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Body
                    Text(
                      post.body,
                      style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Scripture Reference Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book, size: 13, color: AppTheme.primaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            post.scriptureRef,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.emeraldStrokeAlpha15, height: 1),
                    const SizedBox(height: 12),

                    // Actions Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AmenCounterPill(
                          count: post.amenCount,
                          hasSaidAmen: post.hasSaidAmen,
                          onTap: () => _handleProtectedAction(
                            actionTitle: 'say Amen to prayer requests',
                            onAuthenticated: () {
                              setState(() {
                                post.hasSaidAmen = !post.hasSaidAmen;
                                post.amenCount += post.hasSaidAmen ? 1 : -1;
                              });
                            },
                          ),
                        ),
                        Row(
                          children: [
                            SubtleIconButton(
                              icon: Icons.chat_bubble_outline,
                              label: '${post.commentCount}',
                              onTap: () => _handleProtectedAction(
                                actionTitle: 'comment on posts',
                                onAuthenticated: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            SubtleIconButton(
                              icon: Icons.share_outlined,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
