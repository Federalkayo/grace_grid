import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/mock_auth_provider.dart';
import '../providers/feed_provider.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  final String currentUserName;
  final String? currentUserAvatar;

  const CreatePostSheet({
    super.key,
    this.currentUserName = 'Believer',
    this.currentUserAvatar,
  });

  static Future<void> show(BuildContext context, {String currentUserName = 'Believer', String? currentUserAvatar}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreatePostSheet(
          currentUserName: currentUserName,
          currentUserAvatar: currentUserAvatar,
        ),
      ),
    );
  }

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _scriptureController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String _selectedCategory = 'Testimony';
  XFile? _pickedImageFile;
  String? _selectedPresetUrl;
  bool _isUploading = false;
  bool _showUrlInput = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _presetImages = [
    'https://images.unsplash.com/photo-1544427920-c49ccfb85579?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1507692049790-de58290a4334?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1499209974431-9dac3ada00d7?auto=format&fit=crop&w=1000&q=80',
  ];

  @override
  void dispose() {
    _bodyController.dispose();
    _scriptureController.dispose();
    _captionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImageFile = image;
          _selectedPresetUrl = null;
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _handlePublish() async {
    final bodyText = _bodyController.text.trim();
    if (bodyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a testimony or reflection message.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final String? presetUrl = _selectedPresetUrl ??
        (_imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null);

    final currentProfile = ref.read(mockAuthNotifierProvider).profile;

    final success = await ref.read(feedProvider.notifier).createPost(
          userId: currentProfile.id,
          authorName: widget.currentUserName,
          authorAvatar: widget.currentUserAvatar,
          authorTitle: 'Sanctuary Believer',
          authorHandle: '@${widget.currentUserName.toLowerCase().replaceAll(' ', '')}',
          category: _selectedCategory,
          body: bodyText,
          scriptureRef: _scriptureController.text.trim(),
          imageFile: _pickedImageFile,
          imageUrlPreset: presetUrl,
          imageCaption: _captionController.text.trim(),
        );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post published to Community Feed!'),
            backgroundColor: AppTheme.primaryContainer,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _pickedImageFile != null || _selectedPresetUrl != null || _imageUrlController.text.trim().isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
                      'Share Testimony & Post',
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
                    // Category Selection Chips
                    const Text(
                      'SELECT CATEGORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Prayer Wall', 'Testimony', 'Reflection', 'Fellowship'].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: AppTheme.primaryContainer,
                          backgroundColor: AppTheme.surfaceLow,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? AppTheme.onPrimary : AppTheme.onSurface,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // User Profile Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                          backgroundImage: widget.currentUserAvatar != null ? NetworkImage(widget.currentUserAvatar!) : null,
                          child: widget.currentUserAvatar == null
                              ? Text(
                                  widget.currentUserName[0],
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                                )
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
                            Text(
                              '@${widget.currentUserName.toLowerCase().replaceAll(' ', '')} • Posting to Sanctuary',
                              style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Post Body Text Field
                    TextField(
                      controller: _bodyController,
                      maxLines: 5,
                      minLines: 3,
                      autofocus: true,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'What is on your heart today? Share a scripture reflection, testimony, or prayer request...',
                        hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                        filled: true,
                        fillColor: AppTheme.surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.emeraldStrokeAlpha25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Scripture Reference Attachment Input
                    TextField(
                      controller: _scriptureController,
                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.menu_book, size: 18, color: AppTheme.primaryContainer),
                        hintText: 'Attach Scripture reference (e.g. John 15:4, Psalm 23)...',
                        hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.surfaceLow,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.emeraldStrokeAlpha15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image Attachment Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ATTACH MEDIA & CAPTION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _showUrlInput = !_showUrlInput),
                          child: Text(
                            _showUrlInput ? 'Hide URL' : '+ Image URL',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Image Picker Action Bar
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

                    // Preset Photo Gallery Picker Row
                    const Text(
                      'Or pick from Faith Inspiration Gallery:',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presetImages.length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final url = _presetImages[idx];
                          final isSel = _selectedPresetUrl == url;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPresetUrl = url;
                                _pickedImageFile = null;
                                _imageUrlController.clear();
                              });
                            },
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: isSel ? Border.all(color: AppTheme.primaryContainer, width: 2.5) : null,
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_showUrlInput) ...[
                      TextField(
                        controller: _imageUrlController,
                        onChanged: (_) => setState(() => _selectedPresetUrl = null),
                        decoration: InputDecoration(
                          hintText: 'Paste Image URL (https://...)',
                          prefixIcon: const Icon(Icons.link, size: 18),
                          filled: true,
                          fillColor: AppTheme.surfaceLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Image Preview Card & Caption
                    if (hasImage) ...[
                      GlassCard(
                        level: GlassLevel.level1,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _pickedImageFile != null
                                      ? (kIsWeb
                                          ? Image.network(_pickedImageFile!.path, height: 180, width: double.infinity, fit: BoxFit.cover)
                                          : Image.file(File(_pickedImageFile!.path), height: 180, width: double.infinity, fit: BoxFit.cover))
                                      : Image.network(
                                          _selectedPresetUrl ?? _imageUrlController.text.trim(),
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => const SizedBox(
                                            height: 100,
                                            child: Center(child: Icon(Icons.broken_image, size: 36, color: AppTheme.onSurfaceVariant)),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                                    radius: 16,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        setState(() {
                                          _pickedImageFile = null;
                                          _selectedPresetUrl = null;
                                          _imageUrlController.clear();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _captionController,
                              style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Add an image caption (optional)...',
                                hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                                prefixIcon: const Icon(Icons.subtitles_outlined, size: 18, color: AppTheme.primaryContainer),
                                filled: true,
                                fillColor: AppTheme.surfaceLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 10),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onPrimary),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isUploading ? 'Publishing to Cloud...' : 'Publish Post',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryContainer,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isUploading ? null : _handlePublish,
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
