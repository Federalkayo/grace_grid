import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/mock_auth_provider.dart';
import 'models/feed_post_model.dart';
import 'providers/feed_provider.dart';
import 'widgets/post_comments_sheet.dart';

/// Full-text search over the community feed — matches a post's author
/// name/handle, body text, category, and scripture reference.
class FeedSearchScreen extends ConsumerStatefulWidget {
  const FeedSearchScreen({super.key});

  @override
  ConsumerState<FeedSearchScreen> createState() => _FeedSearchScreenState();
}

class _FeedSearchScreenState extends ConsumerState<FeedSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Open with the keyboard already up — the person tapped search to
    // type, not to look at an empty screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<FeedPost> _matches(List<FeedPost> posts) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return posts.where((post) {
      final haystack = [
        post.authorName,
        post.authorHandle,
        post.body,
        post.category,
        post.scriptureRef ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final authState = ref.watch(mockAuthNotifierProvider);
    final userName = authState.profile.name;
    final userAvatarUrl = authState.profile.avatarUrl.isNotEmpty ? authState.profile.avatarUrl : null;
    final results = _matches(feedState.posts);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search prayers, testimonies, people...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.onSurfaceVariant),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppTheme.onSurfaceVariant),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
      ),
      body: _buildBody(context, results, userName, userAvatarUrl),
    );
  }

  Widget _buildBody(BuildContext context, List<FeedPost> results, String userName, String? userAvatarUrl) {
    if (_query.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              const Text(
                'Search the Sanctuary Feed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              const Text(
                'Find posts by name, category, scripture, or keyword',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'No results for "${_query.trim()}"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final post = results[index];
        return _SearchResultCard(
          post: post,
          onTap: () => PostCommentsSheet.show(
            context,
            post: post,
            currentUserName: userName,
            currentUserAvatar: userAvatarUrl,
          ),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onTap;

  const _SearchResultCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
              backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                  ? NetworkImage(post.authorAvatar!)
                  : null,
              child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                  ? Text(
                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
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
                      Flexible(
                        child: Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          post.category,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (post.scriptureRef != null && post.scriptureRef!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        post.scriptureRef!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                      ),
                    ),
                  Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 13, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${post.amenCount}', style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(width: 12),
                      const Icon(Icons.chat_bubble_outline, size: 13, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${post.commentCount}', style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
