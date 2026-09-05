import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/mock_community_data.dart';
import '../../../core/services/feed_firestore_service.dart';
import '../../../core/services/firebase_storage_service.dart';

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
  final FeedFirestoreService _firestoreService = FeedFirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  StreamSubscription<List<FeedPost>>? _firestoreSubscription;
  StreamSubscription<List<SanctuaryStory>>? _storiesSubscription;

  FeedNotifier() : super(FeedState(posts: const [], stories: const [], isLoading: true)) {
    _initFirestoreStream();
  }

  void _initFirestoreStream() {
    try {
      _firestoreSubscription = _firestoreService.getPostsStream().listen(
        (firestorePosts) {
          state = state.copyWith(posts: firestorePosts, isLoading: false);
        },
        onError: (e) {
          debugPrint('Firestore posts stream notice: $e');
          state = state.copyWith(isLoading: false);
        },
      );

      _storiesSubscription = _firestoreService.getStoriesStream().listen(
        (firestoreStories) {
          state = state.copyWith(stories: firestoreStories);
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
  Future<void> toggleAmen(String postId, {String userId = 'user_me'}) async {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        final newHasSaidAmen = !post.hasSaidAmen;
        final newCount = post.amenCount + (newHasSaidAmen ? 1 : -1);
        final newLikedIds = List<String>.from(post.likedUserIds);
        if (newHasSaidAmen) {
          newLikedIds.add(userId);
        } else {
          newLikedIds.remove(userId);
        }

        // Fire & forget firestore update
        _firestoreService.toggleAmen(
          postId: postId,
          userId: userId,
          isCurrentlyLiked: post.hasSaidAmen,
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
    String userId = 'user_me',
  }) async {
    final newComment = PostComment(
      id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorTitle: authorTitle,
      authorId: userId,
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
    await _firestoreService.addComment(postId: postId, comment: newComment);
  }

  /// Toggle like on a comment
  void toggleCommentLike(String postId, String commentId, {String userId = 'user_me', PostComment? commentObj}) {
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
            if (!newLikedUsers.contains(userId)) newLikedUsers.add(userId);
          } else {
            newLikedUsers.remove(userId);
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
            userId: userId,
            isCurrentlyLiked: currentlyLiked,
          );
        } else if (commentObj != null) {
          final currentlyLiked = commentObj.isLiked;
          final newIsLiked = !currentlyLiked;
          final newLikeCount = commentObj.likeCount + (newIsLiked ? 1 : -1);

          final newLikedUsers = List<String>.from(commentObj.likedUserIds);
          if (newIsLiked) {
            if (!newLikedUsers.contains(userId)) newLikedUsers.add(userId);
          } else {
            newLikedUsers.remove(userId);
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
            userId: userId,
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
    String userId = 'user_me',
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      String? finalImageUrl = imageUrlPreset;

      if (imageFile != null) {
        final uploadedUrl = await _storageService.uploadPostImage(
          imageFile: imageFile,
          userId: userId,
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
        authorId: userId,
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
        likedUserIds: [userId],
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
    required String userName,
    String? userAvatar,
    required String roleTag,
    String? storyText,
    XFile? imageFile,
    String? imageUrlPreset,
    String? caption,
  }) async {
    try {
      String? finalImageUrl = imageUrlPreset;
      if (imageFile != null) {
        final uploadedUrl = await _storageService.uploadPostImage(
          imageFile: imageFile,
          userId: userName.replaceAll(' ', '_'),
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
        userName: userName,
        userAvatar: userAvatar,
        roleTag: roleTag,
        hasUnread: true,
        storyText: storyText,
        imageUrl: finalImageUrl,
        caption: caption,
        createdAt: DateTime.now(),
      );

      // Keep user status circle at index 0 and insert new story at index 1
      final currentStories = List<SanctuaryStory>.from(state.stories);
      if (currentStories.isNotEmpty) {
        currentStories.insert(1, newStory);
      } else {
        currentStories.add(newStory);
      }

      state = state.copyWith(stories: currentStories);

      // Sync to Firestore
      await _firestoreService.createStory(newStory);
      return true;
    } catch (e) {
      debugPrint('Create story error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _storiesSubscription?.cancel();
    super.dispose();
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});
