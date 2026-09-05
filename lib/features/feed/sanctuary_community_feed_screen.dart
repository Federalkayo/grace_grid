import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_buttons.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../auth/login_signup_modal.dart';
import '../fellowship/fellowship_conversations_screen.dart';
import '../fellowship/fellowship_chat_screen.dart';
import '../../core/providers/agora_chat_provider.dart';
import 'models/feed_post_model.dart';
import 'providers/feed_provider.dart';
import 'widgets/create_post_sheet.dart';
import 'widgets/create_story_sheet.dart';
import 'widgets/post_comments_sheet.dart';
import 'widgets/sanctuary_story_viewer_modal.dart';

class SanctuaryCommunityFeedScreen extends ConsumerStatefulWidget {
  const SanctuaryCommunityFeedScreen({super.key});

  @override
  ConsumerState<SanctuaryCommunityFeedScreen> createState() => _SanctuaryCommunityFeedScreenState();
}

class _SanctuaryCommunityFeedScreenState extends ConsumerState<SanctuaryCommunityFeedScreen> {
  final Map<String, bool> _animatingHeartMap = {};

  void _handleProtectedAction({required String actionTitle, required VoidCallback onAuthenticated}) {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: actionTitle);
    } else {
      onAuthenticated();
    }
  }

  void _triggerDoubleTapLike(FeedPost post) {
    setState(() => _animatingHeartMap[post.id] = true);
    ref.read(feedProvider.notifier).incrementAmen(post.id);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _animatingHeartMap[post.id] = false);
      }
    });
  }

  void _openLightboxImage(BuildContext context, String imageUrl, String? caption) {
    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: isNetwork
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => _buildMediaFallback(),
                      )
                    : (!kIsWeb && File(imageUrl).existsSync()
                        ? Image.file(
                            File(imageUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => _buildMediaFallback(),
                          )
                        : _buildMediaFallback()),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImageWidget(String url) {
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildMediaFallback(),
      );
    } else if (!kIsWeb) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildMediaFallback(),
        );
      }
    }
    return _buildMediaFallback();
  }

  Widget _buildMediaFallback() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 36, color: AppTheme.primaryContainer),
            SizedBox(height: 6),
            Text('Sanctuary Media Attachment', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildRichTextWithHashtags(String text) {
    final words = text.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isHashtag = word.startsWith('#') && word.length > 1;

      spans.add(
        TextSpan(
          text: '$word ',
          style: TextStyle(
            color: isHashtag ? AppTheme.primaryContainer : AppTheme.onSurface,
            fontWeight: isHashtag ? FontWeight.bold : FontWeight.normal,
            height: 1.5,
            fontSize: 15,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final authState = ref.watch(mockAuthNotifierProvider);
    final userName = authState.profile.name;
    final userAvatarUrl = authState.profile.avatarUrl.isNotEmpty ? authState.profile.avatarUrl : null;

    final filteredPosts = feedState.selectedCategory == 'All'
        ? feedState.posts
        : feedState.posts.where((p) => p.category == feedState.selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
              ),
              child: const Icon(Icons.dynamic_feed, color: AppTheme.primaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sanctuary Feed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppTheme.primaryContainer),
            tooltip: 'Fellowship Messages',
            onPressed: () => _handleProtectedAction(
              actionTitle: 'access Direct Messages',
              onAuthenticated: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FellowshipConversationsScreen(),
                  ),
                );
              },
            ),
          ),
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
        icon: const Icon(Icons.edit_note, size: 22),
        label: const Text(
          'Post Testimony',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _handleProtectedAction(
          actionTitle: 'post in Community',
          onAuthenticated: () {
            CreatePostSheet.show(
              context,
              currentUserName: userName,
              currentUserAvatar: userAvatarUrl,
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const SizedBox(height: 12),

            // 1. Fellowship Stories / Status Bar
SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: feedState.stories.length + 1,
                itemBuilder: (context, index) {
                  final isUser = index == 0;
                  final SanctuaryStory story = isUser
                      ? SanctuaryStory(
                          id: 'my-status',
                          userName: 'Your Status',
                          userAvatar: userAvatarUrl,
                          roleTag: 'Believer',
                          hasUnread: false,
                        )
                      : feedState.stories[index - 1];

                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: () {
                        if (isUser) {
                          _handleProtectedAction(
                            actionTitle: 'post a Fellowship Story',
                            onAuthenticated: () {
                              CreateStorySheet.show(
                                context,
                                currentUserName: userName,
                                currentUserAvatar: userAvatarUrl,
                              );
                            },
                          );
                        } else {
                          SanctuaryStoryViewerModal.show(
                            context,
                            stories: feedState.stories,
                            initialIndex: index - 1,
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: story.hasUnread ? AppTheme.primaryContainer : AppTheme.emeraldStrokeAlpha15,
                                    width: 2,
                                  ),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final avatarImg = getAvatarImageProvider(story.userAvatar);
                                    return CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                                      backgroundImage: avatarImg,
                                      child: avatarImg == null
                                          ? (isUser
                                              ? const Icon(Icons.add, color: AppTheme.primaryContainer)
                                              : Text(
                                                  story.userName.isNotEmpty ? story.userName[0].toUpperCase() : 'U',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                                                ))
                                          : null,
                                    );
                                  },
                                ),
                              ),
                              if (story.isLive)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('LIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 65,
                            child: Text(
                              isUser ? 'Your Status' : story.userName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppTheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: AppTheme.emeraldStrokeAlpha15, height: 1),

            // 2. Quick Compose Card Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                level: GlassLevel.level1,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _handleProtectedAction(
                  actionTitle: 'post in Community',
                  onAuthenticated: () {
                    CreatePostSheet.show(
                      context,
                      currentUserName: userName,
                      currentUserAvatar: userAvatarUrl,
                    );
                  },
                ),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final avatarImg = getAvatarImageProvider(userAvatarUrl);
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                          backgroundImage: avatarImg,
                          child: avatarImg == null
                              ? Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                                )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'What is on your heart today, $userName?',
                        style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                    const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryContainer, size: 22),
                  ],
                ),
              ),
            ),

            // 3. Category Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Prayer Wall', 'Testimony', 'Reflection', 'Fellowship'].map((cat) {
                  final isSelected = feedState.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TopicFilterChip(
                      label: cat,
                      isSelected: isSelected,
                      onTap: () => ref.read(feedProvider.notifier).setCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Social Feed Posts List
            if (feedState.isLoading && filteredPosts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredPosts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.feed_outlined, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No posts in ${feedState.selectedCategory}',
                        style: const TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Be the first to share a testimony or prayer!', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              ...filteredPosts.map((post) {
                final isHeartAnimating = _animatingHeartMap[post.id] ?? false;
                final isMyPost = post.authorName.trim().toLowerCase() == userName.trim().toLowerCase() ||
                                 (post.authorId.isNotEmpty && post.authorId == authState.profile.id);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GlassCard(
                    level: GlassLevel.level2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author Header
                        Row(
                          children: [
                            InkWell(
                              onTap: isMyPost
                                  ? null
                                  : () {
                                      ref.read(conversationsListProvider.notifier).addConversation(post.authorName);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => FellowshipChatScreen(partnerName: post.authorName),
                                        ),
                                      );
                                    },
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final avatarImg = getAvatarImageProvider(post.authorAvatar);
                                      return CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                                        backgroundImage: avatarImg,
                                        child: avatarImg == null
                                            ? Text(
                                                post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                                                style: const TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: isMyPost
                                    ? null
                                    : () {
                                        ref.read(conversationsListProvider.notifier).addConversation(post.authorName);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => FellowshipChatScreen(partnerName: post.authorName),
                                          ),
                                        );
                                      },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          post.authorName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, size: 14, color: AppTheme.primaryContainer),
                                      ],
                                    ),
                                    Text(
                                      '${post.authorHandle} • ${post.authorTitle} • ${post.timeAgo}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isMyPost)
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppTheme.primaryContainer),
                                tooltip: 'Message ${post.authorName}',
                                onPressed: () {
                                  ref.read(conversationsListProvider.notifier).addConversation(post.authorName);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => FellowshipChatScreen(partnerName: post.authorName),
                                    ),
                                  );
                                },
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
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Post Body Text with Hashtags
                        _buildRichTextWithHashtags(post.body),
                        const SizedBox(height: 10),

                        // Scripture Reference Pill
                        if (post.scriptureRef != null && post.scriptureRef!.isNotEmpty) ...[
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
                                  post.scriptureRef!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Image Attachment with Double-Tap Like & Lightbox Preview
                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                          GestureDetector(
                            onDoubleTap: () => _triggerDoubleTapLike(post),
                            onTap: () => _openLightboxImage(context, post.imageUrl!, post.imageCaption),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _buildPostImageWidget(post.imageUrl!),
                                ),

                                // Double Tap Animated Heart Overlay
                                if (isHeartAnimating)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.4, end: 1.2),
                                    duration: const Duration(milliseconds: 400),
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Icon(
                                          Icons.favorite,
                                          size: 80,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      );
                                    },
                                  ),

                                // Image Caption Bar
                                if (post.imageCaption != null && post.imageCaption!.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                      ),
                                      child: Text(
                                        post.imageCaption!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        const Divider(color: AppTheme.emeraldStrokeAlpha15, height: 1),
                        const SizedBox(height: 12),

                        // Social Media Actions Bar (Amen/Like, Comments, Share, Bookmark)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AmenCounterPill(
                              count: post.amenCount,
                              hasSaidAmen: post.hasSaidAmen,
                              onTap: () => _handleProtectedAction(
                                actionTitle: 'say Amen to posts',
                                onAuthenticated: () {
                                  ref.read(feedProvider.notifier).incrementAmen(post.id);
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
                                    onAuthenticated: () {
                                      PostCommentsSheet.show(
                                        context,
                                        post: post,
                                        currentUserName: userName,
                                        currentUserAvatar: userAvatarUrl,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SubtleIconButton(
                                  icon: Icons.repeat,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Testimony shared to your sanctuary circle!')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                SubtleIconButton(
                                  icon: Icons.bookmark_border,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Post saved to your bookmarks.')),
                                    );
                                  },
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
      ),
    );
  }
}
