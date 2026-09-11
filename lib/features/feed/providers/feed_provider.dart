import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/mock_community_data.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/feed_firestore_service.dart';
import '../../../core/services/firebase_storage_service.dart';

/// Stories older than this are treated as expired and dropped from the
/// feed, the same way a real "Status"/"Story" feature works.
const Duration kStoryLifetime = Duration(hours: 24);

class FeedState {
  final List<FeedPost> posts;
  final List<SanctuaryStory> stories;
  final bool isLoading;
  final String selectedCategory;
  final String? errorMessage;

  FeedState({
    this.posts = const [],
    this.stories = const [],
    this.isLoading = false,
    this.selectedCategory = 'All',
    this.errorMessage,
  });

  /// Stories grouped by author so one bubble in the story bar = one
  /// person, and the viewer only ever plays that person's own segments.
  List<StoryGroup> get groupedActiveStories => StoryGroup.fromStories(stories);

  FeedState copyWith({
    List<FeedPost>? posts,
    List<SanctuaryStory>? stories,
    bool? isLoading,
    String? selectedCategory,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final Ref _ref;
  final FeedFirestoreService _firestoreService = FeedFirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  StreamSubscription<List<FeedPost>>? _firestoreSubscription;
  StreamSubscription<List<SanctuaryStory>>? _storiesSubscription;
  String _currentUserId = '';

  FeedNotifier(this._ref) : super(FeedState(posts: const [], stories: const [], isLoading: true)) {
    // Defer past the current build: reading/listening to another
    // provider (authNotifierProvider) synchronously from inside this
    // notifier's own constructor can fire while the widget tree — and
    // this provider itself — is still being built, which Riverpod
    // rejects with "Tried to modify a provider while the widget tree
    // was building." Running it a microtask later sidesteps that.
    Future.microtask(() {
      if (!mounted) return;
      _currentUserId = _resolveUserId();
      _initFirestoreStream();

      // Re-subscribe with the right currentUserId once auth resolves/
      // changes, otherwise every post loads as "not yet Amen'd" even for
      // posts the user already Amen'd, which is what let the count
      // climb on every tap.
      _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
        final newId = next.profile.id;
        if (newId.isNotEmpty && newId != _currentUserId) {
          _currentUserId = newId;
          _initFirestoreStream();
        }
      });
    });
  }

  String _resolveUserId() {
    final id = _ref.read(authNotifierProvider).profile.id;
    // Match the same 'user_me' guest fallback used by the rest of the
    // feed UI so the id written on Amen/comment actions always matches
    // the id the posts/comments streams read back against.
    return id.isNotEmpty ? id : 'user_me';
  }

  void _initFirestoreStream() {
    try {
      _firestoreSubscription?.cancel();
      _storiesSubscription?.cancel();

      _firestoreSubscription = _firestoreService.getPostsStream(currentUserId: _currentUserId).listen(
        (firestorePosts) {
          // Preserve any locally-cached comments for posts that already
          // had them loaded, instead of wiping them back to empty on
          // every unrelated collection update (e.g. someone else Amen'ing
          // a different post) — this is what made comments "disappear".
          final previousById = {for (final p in state.posts) p.id: p};
          final mergedPosts = firestorePosts.map((post) {
            final previous = previousById[post.id];
            if (previous == null || previous.comments.isEmpty) return post;
            final knownIds = post.comments.map((c) => c.id).toSet();
            final preserved = previous.comments.where((c) => !knownIds.contains(c.id));
            return post.copyWith(comments: [...post.comments, ...preserved]);
          }).toList();

          state = state.copyWith(posts: mergedPosts, isLoading: false);
        },
        onError: (e) {
          debugPrint('Firestore posts stream notice: $e');
          state = state.copyWith(isLoading: false);
        },
      );

      _storiesSubscription = _firestoreService.getStoriesStream(currentUserId: _currentUserId).listen(
        (firestoreStories) {
          final now = DateTime.now();
          final activeStories =
              firestoreStories.where((s) => now.difference(s.createdAt) < kStoryLifetime).toList();
          state = state.copyWith(stories: activeStories);
        },
        onError: (e) {
          debugPrint('Firestore stories stream notice: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore stream init exception: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Toggle Amen / Like on a post
  Future<void> toggleAmen(String postId, {String? userId}) async {
    // Always fall back to the resolved auth id, not a hardcoded literal —
    // otherwise a signed-in user's writes go under one id ('user_me')
    // while the stream reads back against their real uid, so hasSaidAmen
    // never matches and the count just climbs on every tap.
    final effectiveUserId = userId ?? _currentUserId;
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        final newHasSaidAmen = !post.hasSaidAmen;
        final newCount = post.amenCount + (newHasSaidAmen ? 1 : -1);
        final newLikedIds = List<String>.from(post.likedUserIds);
        if (newHasSaidAmen) {
          newLikedIds.add(effectiveUserId);
        } else {
          newLikedIds.remove(effectiveUserId);
        }

        // Fire & forget firestore update
        final actorProfile = _ref.read(authNotifierProvider).profile;
        _firestoreService.toggleAmen(
          postId: postId,
          userId: effectiveUserId,
          isCurrentlyLiked: post.hasSaidAmen,
          postAuthorId: post.authorId,
          actorName: actorProfile.name,
          actorAvatar: actorProfile.avatarUrl,
          postSnippet: post.body,
        );

        return post.copyWith(
          hasSaidAmen: newHasSaidAmen,
          amenCount: newCount < 0 ? 0 : newCount,
          likedUserIds: newLikedIds,
        );
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  /// Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String text,
    required String authorName,
    String? authorAvatar,
    required String authorTitle,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    final newComment = PostComment(
      id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorTitle: authorTitle,
      authorId: effectiveUserId,
      text: text,
      timeAgo: 'Just now',
      createdAt: DateTime.now(),
    );

    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        final updatedComments = List<PostComment>.from(post.comments)..add(newComment);
        return post.copyWith(
          commentCount: post.commentCount + 1,
          comments: updatedComments,
        );
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);

    // Sync to Firestore
    final targetPost = state.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => FeedPost(
        id: postId,
        authorName: '',
        authorTitle: '',
        authorId: '',
        authorHandle: '',
        timeAgo: '',
        createdAt: DateTime.now(),
        category: '',
        body: '',
      ),
    );
    await _firestoreService.addComment(
      postId: postId,
      comment: newComment,
      postAuthorId: targetPost.authorId,
      postSnippet: targetPost.body,
    );
  }

  /// Toggle like on a comment
  void toggleCommentLike(String postId, String commentId, {String? userId, PostComment? commentObj}) {
    final effectiveUserId = userId ?? _currentUserId;
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        final comments = List<PostComment>.from(post.comments);
        final index = comments.indexWhere((c) => c.id == commentId);

        if (index != -1) {
          final c = comments[index];
          final currentlyLiked = c.isLiked;
          final newIsLiked = !currentlyLiked;
          final newLikeCount = c.likeCount + (newIsLiked ? 1 : -1);

          final newLikedUsers = List<String>.from(c.likedUserIds);
          if (newIsLiked) {
            if (!newLikedUsers.contains(effectiveUserId)) newLikedUsers.add(effectiveUserId);
          } else {
            newLikedUsers.remove(effectiveUserId);
          }

          comments[index] = PostComment(
            id: c.id,
            postId: c.postId,
            authorName: c.authorName,
            authorAvatar: c.authorAvatar,
            authorTitle: c.authorTitle,
            authorId: c.authorId,
            text: c.text,
            timeAgo: c.timeAgo,
            createdAt: c.createdAt,
            likeCount: newLikeCount < 0 ? 0 : newLikeCount,
            isLiked: newIsLiked,
            likedUserIds: newLikedUsers,
          );

          _firestoreService.toggleCommentLike(
            postId: postId,
            commentId: commentId,
            userId: effectiveUserId,
            isCurrentlyLiked: currentlyLiked,
          );
        } else if (commentObj != null) {
          final currentlyLiked = commentObj.isLiked;
          final newIsLiked = !currentlyLiked;
          final newLikeCount = commentObj.likeCount + (newIsLiked ? 1 : -1);

          final newLikedUsers = List<String>.from(commentObj.likedUserIds);
          if (newIsLiked) {
            if (!newLikedUsers.contains(effectiveUserId)) newLikedUsers.add(effectiveUserId);
          } else {
            newLikedUsers.remove(effectiveUserId);
          }

          final updatedComment = PostComment(
            id: commentObj.id,
            postId: commentObj.postId,
            authorName: commentObj.authorName,
            authorAvatar: commentObj.authorAvatar,
            authorTitle: commentObj.authorTitle,
            authorId: commentObj.authorId,
            text: commentObj.text,
            timeAgo: commentObj.timeAgo,
            createdAt: commentObj.createdAt,
            likeCount: newLikeCount < 0 ? 0 : newLikeCount,
            isLiked: newIsLiked,
            likedUserIds: newLikedUsers,
          );

          comments.add(updatedComment);

          _firestoreService.toggleCommentLike(
            postId: postId,
            commentId: commentId,
            userId: effectiveUserId,
            isCurrentlyLiked: currentlyLiked,
          );
        }

        return post.copyWith(comments: comments);
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  /// Create a new text & image post with optional image upload to Firebase Storage
  Future<bool> createPost({
    required String authorName,
    String? authorAvatar,
    required String authorTitle,
    required String authorHandle,
    required String category,
    required String body,
    String? scriptureRef,
    XFile? imageFile,
    String? imageUrlPreset,
    String? imageCaption,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    state = state.copyWith(isLoading: true);

    try {
      String? finalImageUrl = imageUrlPreset;

      if (imageFile != null) {
        final uploadedUrl = await _storageService.uploadPostImage(
          imageFile: imageFile,
          userId: effectiveUserId,
        );
        if (uploadedUrl == null) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Could not upload image. Check your connection and try again.',
          );
          return false;
        }
        finalImageUrl = uploadedUrl;
      }

      final newPost = FeedPost(
        id: 'post-${DateTime.now().millisecondsSinceEpoch}',
        authorName: authorName,
        authorAvatar: authorAvatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
        authorTitle: authorTitle,
        authorId: effectiveUserId,
        authorHandle: authorHandle,
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        category: category,
        scriptureRef: scriptureRef?.isNotEmpty == true ? scriptureRef : null,
        body: body,
        imageUrl: finalImageUrl,
        imageCaption: imageCaption?.isNotEmpty == true ? imageCaption : null,
        amenCount: 1,
        hasSaidAmen: true,
        likedUserIds: [effectiveUserId],
        commentCount: 0,
        comments: [],
      );

      final updatedPosts = [newPost, ...state.posts];
      state = state.copyWith(posts: updatedPosts, isLoading: false);

      // Save document in Cloud Firestore
      await _firestoreService.createPost(newPost);
      return true;
    } catch (e) {
      debugPrint('Create post error: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Create a new status story with image & caption
  Future<bool> createStory({
    String? userId,
    required String userName,
    String? userAvatar,
    required String roleTag,
    String? storyText,
    XFile? imageFile,
    String? imageUrlPreset,
    String? caption,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    try {
      String? finalImageUrl = imageUrlPreset;
      if (imageFile != null) {
        final uploadedUrl = await _storageService.uploadPostImage(
          imageFile: imageFile,
          userId: effectiveUserId,
        );
        if (uploadedUrl == null) {
          state = state.copyWith(
            errorMessage: 'Could not upload story image. Check your connection and try again.',
          );
          return false;
        }
        finalImageUrl = uploadedUrl;
      }

      final newStory = SanctuaryStory(
        id: 'story-${DateTime.now().millisecondsSinceEpoch}',
        authorId: effectiveUserId,
        userName: userName,
        userAvatar: userAvatar,
        roleTag: roleTag,
        storyText: storyText,
        imageUrl: finalImageUrl,
        caption: caption,
        createdAt: DateTime.now(),
      );

      // Just append — grouping by authorId (via StoryGroup.fromStories)
      // is what puts every one of this author's active stories under
      // their single bubble as extra segments, so there's no need to
      // hand-place this at a magic index.
      state = state.copyWith(stories: [...state.stories, newStory]);

      // Sync to Firestore
      await _firestoreService.createStory(newStory);
      return true;
    } catch (e) {
      debugPrint('Create story error: $e');
      return false;
    }
  }

  /// Mark a story as viewed by the current user. Updates local state
  /// immediately (so the ring segment turns gray right away) and syncs
  /// to Firestore in the background.
  void markStoryViewed(String storyId) {
    final userId = _currentUserId;
    if (userId.isEmpty) return;

    final updatedStories = state.stories.map((story) {
      if (story.id == storyId && !story.viewedByUserIds.contains(userId)) {
        return story.copyWith(viewedByUserIds: [...story.viewedByUserIds, userId]);
      }
      return story;
    }).toList();

    state = state.copyWith(stories: updatedStories);
    _firestoreService.markStoryViewed(storyId: storyId, userId: userId);
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _storiesSubscription?.cancel();
    super.dispose();
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref);
});
