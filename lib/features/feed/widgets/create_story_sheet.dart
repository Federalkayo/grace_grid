import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/feed_provider.dart';

class CreateStorySheet extends ConsumerStatefulWidget {
  final String currentUserName;
  final String? currentUserAvatar;

  const CreateStorySheet({
    super.key,
    this.currentUserName = 'Believer',
    this.currentUserAvatar,
  });

  static Future<void> show(
    BuildContext context, {
    String currentUserName = 'Believer',
    String? currentUserAvatar,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreateStorySheet(
          currentUserName: currentUserName,
          currentUserAvatar: currentUserAvatar,
        ),
      ),
    );
  }

  @override
  ConsumerState<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends ConsumerState<CreateStorySheet> {
  final TextEditingController _storyTextController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  XFile? _pickedImageFile;
  String? _selectedPresetUrl;
  bool _isPublishing = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _presetStoryImages = [
    'https://images.unsplash.com/photo-1544427920-c49ccfb85579?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1499209974431-9dac3ada00d7?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1507692049790-de58290a4334?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?auto=format&fit=crop&w=1000&q=80',
  ];

  @override
  void dispose() {
    _storyTextController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImageFile = image;
          _selectedPresetUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Story image pick error: $e');
    }
  }

  Future<void> _handlePublishStory() async {
    final storyText = _storyTextController.text.trim();
    if (storyText.isEmpty && _pickedImageFile == null && _selectedPresetUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a status message or select an image for your story.')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    final success = await ref.read(feedProvider.notifier).createStory(
          userName: widget.currentUserName,
          userAvatar: widget.currentUserAvatar,
          roleTag: 'Sanctuary Believer',
          storyText: storyText.isNotEmpty ? storyText : null,
          imageFile: _pickedImageFile,
          imageUrlPreset: _selectedPresetUrl,
          caption: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
        );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sanctuary Story published successfully!'),
            backgroundColor: AppTheme.primaryContainer,
          ),
        );
      }
    }
  }

  Widget _buildPreviewImage() {
    if (_pickedImageFile != null) {
      if (kIsWeb) {
        return Image.network(_pickedImageFile!.path, height: 160, width: double.infinity, fit: BoxFit.cover);
      } else {
        return Image.file(File(_pickedImageFile!.path), height: 160, width: double.infinity, fit: BoxFit.cover);
      }
    } else if (_selectedPresetUrl != null) {
      return Image.network(_selectedPresetUrl!, height: 160, width: double.infinity, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _pickedImageFile != null || _selectedPresetUrl != null;

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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Post Sanctuary Status Story',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.emeraldStrokeAlpha15, height: 1),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // User Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                          backgroundImage: widget.currentUserAvatar != null ? NetworkImage(widget.currentUserAvatar!) : null,
                          child: widget.currentUserAvatar == null
                              ? Text(widget.currentUserName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.currentUserName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.onSurface),
                            ),
                            const Text(
                              'Sanctuary Status Story • Visible 24 Hours',
                              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Story Text / Quote Input
                    TextField(
                      controller: _storyTextController,
                      maxLines: 4,
                      minLines: 2,
                      autofocus: true,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Share a 24-hour faith reflection, prayer status, or scripture quote...',
                        hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                        filled: true,
                        fillColor: AppTheme.surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.emeraldStrokeAlpha25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media Picker Row
                    const Text(
                      'ATTACH PHOTO TO STORY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceLow,
                            foregroundColor: AppTheme.primaryContainer,
                            elevation: 0,
                            side: const BorderSide(color: AppTheme.emeraldStrokeAlpha25),
                          ),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceLow,
                            foregroundColor: AppTheme.primaryContainer,
                            elevation: 0,
                            side: const BorderSide(color: AppTheme.emeraldStrokeAlpha25),
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Faith Gallery Presets
                    const Text(
                      'Or choose a Sanctuary Faith Background:',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presetStoryImages.length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final url = _presetStoryImages[idx];
                          final isSel = _selectedPresetUrl == url;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPresetUrl = url;
                                _pickedImageFile = null;
                              });
                            },
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: isSel ? Border.all(color: AppTheme.primaryContainer, width: 2.5) : null,
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Preview
                    if (hasMedia) ...[
                      GlassCard(
                        level: GlassLevel.level1,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildPreviewImage(),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                                    radius: 14,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => setState(() {
                                        _pickedImageFile = null;
                                        _selectedPresetUrl = null;
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _captionController,
                              style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Add a story caption (optional)...',
                                hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                                filled: true,
                                fillColor: AppTheme.surfaceLow,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: _isPublishing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onPrimary))
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _isPublishing ? 'Publishing Status...' : 'Share Sanctuary Story',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryContainer,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isPublishing ? null : _handlePublishStory,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
