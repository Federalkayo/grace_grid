import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/mock_auth_provider.dart';
import '../../../core/services/feed_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/feed_post_model.dart';
import '../providers/feed_provider.dart';

class PostCommentsSheet extends ConsumerStatefulWidget {
  final FeedPost post;
  final String currentUserName;
  final String? currentUserAvatar;

  const PostCommentsSheet({
    super.key,
    required this.post,
    this.currentUserName = 'Believer',
    this.currentUserAvatar,
  });

  static Future<void> show(
    BuildContext context, {
    required FeedPost post,
    String currentUserName = 'Believer',
    String? currentUserAvatar,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentsSheet(
        post: post,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
      ),
    );
  }

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _commentController.clear();

    await ref.read(feedProvider.notifier).addComment(
          postId: widget.post.id,
          text: text,
          authorName: widget.currentUserName,
          authorAvatar: widget.currentUserAvatar,
          authorTitle: 'Sanctuary Believer',
        );

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  void _insertQuickEmoji(String emojiText) {
    _commentController.text = '${_commentController.text} $emojiText'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final authState = ref.watch(mockAuthNotifierProvider);
    final currentUserId = authState.profile.id.isNotEmpty ? authState.profile.id : 'user_me';

    final currentPost = feedState.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 20, color: AppTheme.primaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Comments (${currentPost.commentCount})',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.emeraldStrokeAlpha15, height: 1),

              // Comments List Area with Real-Time Stream Integration
              Expanded(
                child: StreamBuilder<List<PostComment>>(
                  stream: FeedFirestoreService().getCommentsStream(currentPost.id, currentUserId: currentUserId),
                  builder: (context, snapshot) {
                    final firestoreComments = snapshot.data ?? [];
                    final Map<String, PostComment> mergedMap = {};

                    // 1. Put Firestore stream comments in first
                    for (final c in firestoreComments) {
                      mergedMap[c.id] = c;
                    }

                    // 2. Put local state comments in second so optimistic updates override
                    for (final c in currentPost.comments) {
                      mergedMap[c.id] = c;
                    }

                    final allComments = mergedMap.values.toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    if (allComments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'No comments yet',
                              style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Be the first to share an encouragement or prayer!',
                              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: allComments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final comment = allComments[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.emeraldStrokeAlpha15),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                                backgroundImage: comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty
                                    ? NetworkImage(comment.authorAvatar!)
                                    : null,
                                child: (comment.authorAvatar == null || comment.authorAvatar!.isEmpty)
                                    ? Text(
                                        comment.authorName[0],
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          comment.authorName,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                                        ),
                                        Text(
                                          comment.timeAgo,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.text,
                                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  ref.read(feedProvider.notifier).toggleCommentLike(
                                        currentPost.id,
                                        comment.id,
                                        userId: currentUserId,
                                        commentObj: comment,
                                      );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        comment.isLiked ? Icons.favorite : Icons.favorite_border,
                                        size: 18,
                                        color: comment.isLiked ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant,
                                      ),
                                      if (comment.likeCount > 0)
                                        Text(
                                          '${comment.likeCount}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: comment.isLiked ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Quick Reaction Emojis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Amen 🙏',
                      'Hallelujah 🙌',
                      'Praise God ✝️',
                      'Praying 🕊️',
                      'Blessed ✨',
                    ].map((emoji) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(emoji, style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppTheme.surfaceLow,
                          onPressed: () => _insertQuickEmoji(emoji),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Sticky Bottom Comment Input Bar with smooth Keyboard Inset handling
              AnimatedPadding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                duration: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceLow,
                    border: Border(top: BorderSide(color: AppTheme.emeraldStrokeAlpha15)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                        backgroundImage: widget.currentUserAvatar != null ? NetworkImage(widget.currentUserAvatar!) : null,
                        child: widget.currentUserAvatar == null
                            ? Text(
                                widget.currentUserName[0],
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Add a sanctuary encouragement...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                            filled: true,
                            fillColor: AppTheme.surfaceContainer,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _handleSendComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryContainer),
                              )
                            : const Icon(Icons.send_rounded, color: AppTheme.primaryContainer),
                        onPressed: _isSending ? null : _handleSendComment,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
