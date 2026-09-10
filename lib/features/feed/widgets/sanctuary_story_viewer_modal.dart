import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/feed_post_model.dart';

class SanctuaryStoryViewerModal extends StatefulWidget {
  final List<SanctuaryStory> stories;
  final int initialIndex;
  final ValueChanged<SanctuaryStory>? onStoryViewed;

  const SanctuaryStoryViewerModal({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onStoryViewed,
  });

  static Future<void> show(
    BuildContext context, {
    required List<SanctuaryStory> stories,
    int initialIndex = 0,
    ValueChanged<SanctuaryStory>? onStoryViewed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SanctuaryStoryViewerModal(
        stories: stories,
        initialIndex: initialIndex,
        onStoryViewed: onStoryViewed,
      ),
    );
  }

  @override
  State<SanctuaryStoryViewerModal> createState() => _SanctuaryStoryViewerModalState();
}

class _SanctuaryStoryViewerModalState extends State<SanctuaryStoryViewerModal>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advanceStory();
        }
      });

    _progressController.forward();
    _markCurrentViewed();
  }

  void _markCurrentViewed() {
    if (_currentIndex >= widget.stories.length) return;
    final story = widget.stories[_currentIndex];
    // Defer to after this frame's build finishes. Calling this straight
    // from initState() modifies feedProvider's state while THIS widget
    // is still mid-build, which is exactly what Riverpod's "Tried to
    // modify a provider while the widget tree was building" guards
    // against — addPostFrameCallback runs it right after, once it's
    // safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onStoryViewed?.call(story);
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _advanceStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _progressController.reset();
        _progressController.forward();
      });
      _markCurrentViewed();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progressController.reset();
        _progressController.forward();
      });
      _markCurrentViewed();
    }
  }

  Widget _buildStoryImage(String url) {
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => _buildFallbackBackground(),
      );
    } else if (!kIsWeb) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (ctx, err, stack) => _buildFallbackBackground(),
        );
      }
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2B1E), Color(0xFF04120B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Media / Color Gradient
          if (story.imageUrl != null && story.imageUrl!.isNotEmpty)
            _buildStoryImage(story.imageUrl!)
          else
            _buildFallbackBackground(),

          // Dark Overlay Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Tap gesture navigation regions (left = previous, right = next)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _previousStory,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _advanceStory,
                ),
              ),
            ],
          ),

          // Foreground UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar Indicators
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Row(
                        children: List.generate(widget.stories.length, (idx) {
                          double value = 0.0;
                          if (idx < _currentIndex) {
                            value = 1.0;
                          } else if (idx == _currentIndex) {
                            value = _progressController.value;
                          }

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
                                minHeight: 3,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Author Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.3),
                            backgroundImage: story.userAvatar != null && story.userAvatar!.isNotEmpty
                                ? NetworkImage(story.userAvatar!)
                                : null,
                            child: story.userAvatar == null || story.userAvatar!.isEmpty
                                ? Text(story.userName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    story.userName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  if (story.isLive) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                story.roleTag,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Story Quote / Scripture Content Card
                  if (story.storyText != null && story.storyText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: GlassCard(
                        level: GlassLevel.level3,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.storyText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (story.caption != null && story.caption!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                story.caption!,
                                style: const TextStyle(color: AppTheme.primaryContainer, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Bottom Action Reactions Bar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            story.hasSaidAmen ? Icons.favorite : Icons.favorite_border,
                            color: story.hasSaidAmen ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            story.hasSaidAmen ? 'Amen Said (${story.amenCount})' : 'Say Amen (${story.amenCount})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              story.hasSaidAmen = true;
                              story.amenCount += 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Encouragement sent to ${story.userName}!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
