import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_buttons.dart';
import '../../core/services/bible_database_service.dart';
import 'providers/sermon_provider.dart';

enum SermonScreenMode { hub, recordAudio, takeNote }

class SermonStudioScreen extends ConsumerStatefulWidget {
  const SermonStudioScreen({super.key});

  @override
  ConsumerState<SermonStudioScreen> createState() => _SermonStudioScreenState();
}

class _SermonStudioScreenState extends ConsumerState<SermonStudioScreen> {
  SermonScreenMode _screenMode = SermonScreenMode.hub;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFullNoteModal(BuildContext context, SermonNoteItem note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return GlassCard(
              level: GlassLevel.level3,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                        ),
                        child: Text(
                          'Timestamp: ${note.timestampStr}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryContainer,
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ),
                      if (note.scriptureRef.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            note.scriptureRef,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    note.noteTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${note.sermonTitle} • ${note.speakerName}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.emeraldStrokeAlpha15),
                  const SizedBox(height: 16),
                  if (note.audioPath != null || note.scriptureRef == 'Live Audio') ...[
                    AudioPlayerWidget(
                      audioPath: note.audioPath ?? '',
                      timestampStr: note.timestampStr,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy Note'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: '${note.noteTitle}\n\n${note.content}\n\nRef: ${note.scriptureRef} [${note.timestampStr}]',
                            ));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Full note copied to clipboard!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Delete Note?'),
                                content: const Text('Remove this sermon note permanently from offline storage?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && note.id != null) {
                              ref.read(sermonProvider.notifier).deleteNote(note.id!);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _exportSermonNotes(List<SermonNoteItem> notes, SermonState state) {
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sermon notes available to export.')),
      );
      return;
    }

    final sb = StringBuffer();
    sb.writeln('# Sermon Notes Summary');
    sb.writeln('---');

    for (final n in notes) {
      sb.writeln('\n### [${n.timestampStr}] ${n.noteTitle}');
      sb.writeln('**Sermon**: ${n.sermonTitle} (${n.speakerName})');
      if (n.scriptureRef.isNotEmpty) sb.writeln('*Scripture*: ${n.scriptureRef}');
      sb.writeln(n.content);
    }

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All sermon notes exported to clipboard in Markdown!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sermonProvider);
    final notifier = ref.read(sermonProvider.notifier);
    final notes = state.filteredNotes;

    switch (_screenMode) {
      case SermonScreenMode.recordAudio:
        return SermonAudioRecordScreen(
          onBack: () => setState(() => _screenMode = SermonScreenMode.hub),
        );
      case SermonScreenMode.takeNote:
        return SermonNoteWriterScreen(
          onBack: () => setState(() => _screenMode = SermonScreenMode.hub),
        );
      case SermonScreenMode.hub:
        return _buildSermonHub(context, state, notifier, notes);
    }
  }

  // --- SCREEN 1: Sermon Hub (Shows list of sermons & actions to Record Audio or Take Note) ---
  Widget _buildSermonHub(
    BuildContext context,
    SermonState state,
    SermonNotifier notifier,
    List<SermonNoteItem> notes,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        title: const Text(
          'Sermon Studio',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.onSurfaceVariant),
            tooltip: 'Export All Notes',
            onPressed: () => _exportSermonNotes(notes, state),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Action Cards: Record Audio OR Take Note
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  level: GlassLevel.level2,
                  padding: const EdgeInsets.all(16),
                  onTap: () {
                    ref.read(sermonProvider.notifier).startNewSession(
                          title: 'Live Audio Sermon',
                          speaker: 'Pastor',
                        );
                    setState(() => _screenMode = SermonScreenMode.recordAudio);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.mic, color: AppTheme.error, size: 28),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Record Audio',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Full screen mic & sound wave',
                        style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GlassCard(
                  level: GlassLevel.level2,
                  padding: const EdgeInsets.all(16),
                  onTap: () => setState(() => _screenMode = SermonScreenMode.takeNote),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.emeraldStrokeAlpha40),
                        ),
                        child: const Icon(Icons.edit_note, color: AppTheme.primaryContainer, size: 28),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Take Note',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Full screen comfortable editor',
                        style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Header for Past Saved Sermons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sermons & Notes Taken (${notes.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => notifier.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Search past sermons & notes...',
              prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.onSurfaceVariant),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.surfaceLow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.emeraldStrokeAlpha25),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List of Past Sermons Taken Before
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (notes.isEmpty)
            GlassCard(
              level: GlassLevel.level1,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.library_books, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('No previous sermons found', style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  const Text('Tap "Record Audio" or "Take Note" above to begin', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            )
          else
            ...notes.map((note) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassCard(
                  level: GlassLevel.level1,
                  padding: const EdgeInsets.all(14),
                  onTap: () => _showFullNoteModal(context, note),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                            ),
                            child: Text(
                              note.timestampStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryContainer,
                                fontFamily: 'Monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.noteTitle,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (note.scriptureRef.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          note.scriptureRef,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${note.sermonTitle} • ${note.speakerName}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tap to view full sermon note →',
                            style: TextStyle(fontSize: 11, color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.onSurfaceVariant),
                            onPressed: () => _showFullNoteModal(context, note),
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

// --- SCREEN 2: Full-Screen Audio Recording Page ---
class SermonAudioRecordScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SermonAudioRecordScreen({super.key, required this.onBack});

  @override
  ConsumerState<SermonAudioRecordScreen> createState() => _SermonAudioRecordScreenState();
}

class _SermonAudioRecordScreenState extends ConsumerState<SermonAudioRecordScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Live Audio Sermon');
  final TextEditingController _speakerController = TextEditingController(text: 'Pastor Kaleb');

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    super.dispose();
  }

  void _saveRecordingSession() async {
    final path = await ref.read(sermonProvider.notifier).stopAndGetAudioPath();
    final state = ref.read(sermonProvider);
    await ref.read(sermonProvider.notifier).addNote(
          noteTitle: 'Audio Recording Session',
          content: 'Recorded live sermon session (${state.currentTimestampStr}) titled "${_titleController.text.trim()}".',
          scriptureRef: 'Live Audio',
          audioPath: path,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio recording session saved to offline library!')),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sermonProvider);
    final notifier = ref.read(sermonProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Live Audio Recorder',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _saveRecordingSession,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Header Settings Card
            GlassCard(
              level: GlassLevel.level1,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Sermon Title',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => notifier.setSermonSession(title: val, speaker: _speakerController.text),
                  ),
                  const Divider(color: AppTheme.emeraldStrokeAlpha15),
                  TextField(
                    controller: _speakerController,
                    style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                    decoration: const InputDecoration(
                      labelText: 'Preacher / Speaker',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => notifier.setSermonSession(title: _titleController.text, speaker: val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Big Glowing Microphone in Center
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    width: state.isRecording ? 140 : 115,
                    height: state.isRecording ? 140 : 115,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (state.isRecording ? AppTheme.error : AppTheme.primaryContainer).withValues(alpha: 0.12),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isRecording ? AppTheme.error : AppTheme.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: (state.isRecording ? AppTheme.error : AppTheme.primaryContainer).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: AppTheme.onPrimary,
                      size: 46,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Digital Timer Display
            Center(
              child: Text(
                state.currentTimestampStr,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                  letterSpacing: 2,
                  color: state.isRecording ? AppTheme.error : AppTheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isRecording ? AppTheme.error : AppTheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isRecording ? 'LIVE RECORDING ACTIVE' : 'RECORDING PAUSED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: state.isRecording ? AppTheme.error : AppTheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Full Width Animated Sound Wave Visualizer
            GlassCard(
              level: GlassLevel.level2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FullSoundWaveVisualizer(isRecording: state.isRecording),
            ),
            const SizedBox(height: 24),

            // Play / Pause Record Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => notifier.toggleRecording(),
                  borderRadius: BorderRadius.circular(40),
                  child: GlassCard(
                    level: GlassLevel.level3,
                    borderRadius: BorderRadius.circular(40),
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      state.isRecording ? Icons.pause : Icons.play_arrow,
                      color: AppTheme.primaryContainer,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary Save Button
            SizedBox(
              width: double.infinity,
              child: PrimarySanctuaryButton(
                text: 'Save Audio Recording Session',
                icon: Icons.check_circle_outline,
                onPressed: _saveRecordingSession,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 3: Full-Screen Comfortable Note Writer Page ---
class SermonNoteWriterScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SermonNoteWriterScreen({super.key, required this.onBack});

  @override
  ConsumerState<SermonNoteWriterScreen> createState() => _SermonNoteWriterScreenState();
}

class _SermonNoteWriterScreenState extends ConsumerState<SermonNoteWriterScreen> {
  final TextEditingController _sermonTitleCtrl = TextEditingController(text: 'Sunday Sermon');
  final TextEditingController _speakerCtrl = TextEditingController(text: 'Pastor Kaleb');
  final TextEditingController _noteTitleCtrl = TextEditingController();
  final TextEditingController _scriptureCtrl = TextEditingController(text: 'John 15:5');
  final TextEditingController _contentCtrl = TextEditingController();

  @override
  void dispose() {
    _sermonTitleCtrl.dispose();
    _speakerCtrl.dispose();
    _noteTitleCtrl.dispose();
    _scriptureCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _saveNote() {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your note content before saving.')),
      );
      return;
    }

    ref.read(sermonProvider.notifier).setSermonSession(
          title: _sermonTitleCtrl.text,
          speaker: _speakerCtrl.text,
        );

    ref.read(sermonProvider.notifier).addNote(
          noteTitle: _noteTitleCtrl.text,
          content: content,
          scriptureRef: _scriptureCtrl.text,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sermon note saved offline to database!')),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Write Sermon Note',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _saveNote,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              // Sermon Metadata Header
              GlassCard(
                level: GlassLevel.level1,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sermonTitleCtrl,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                            decoration: const InputDecoration(
                              labelText: 'Sermon Title',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 130,
                          child: TextField(
                            controller: _speakerCtrl,
                            style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                            decoration: const InputDecoration(
                              labelText: 'Preacher',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.emeraldStrokeAlpha15, height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteTitleCtrl,
                            style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
                            decoration: const InputDecoration(
                              labelText: 'Note Topic / Header (optional)',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 130,
                          child: TextField(
                            controller: _scriptureCtrl,
                            style: const TextStyle(fontSize: 13, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              labelText: 'Scripture Ref',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Full Screen Comfortable Writing Field
              Expanded(
                child: GlassCard(
                  level: GlassLevel.level2,
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _contentCtrl,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing your sermon notes, insights, and spiritual reflections comfortably here...\n\n• Key Point 1\n• Key Point 2',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Save Button
              SizedBox(
                width: double.infinity,
                child: PrimarySanctuaryButton(
                  text: 'Save Sermon Note Offline',
                  icon: Icons.check_circle,
                  onPressed: _saveNote,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Animated Full Sound Wave Visualizer Widget ---
class FullSoundWaveVisualizer extends StatefulWidget {
  final bool isRecording;
  final int barCount;

  const FullSoundWaveVisualizer({
    super.key,
    required this.isRecording,
    this.barCount = 36,
  });

  @override
  State<FullSoundWaveVisualizer> createState() => _FullSoundWaveVisualizerState();
}

class _FullSoundWaveVisualizerState extends State<FullSoundWaveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isRecording) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FullSoundWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!widget.isRecording && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final val = _animController.value;
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.barCount, (i) {
              final baseHeights = [18.0, 32.0, 10.0, 42.0, 22.0, 36.0, 14.0, 46.0, 24.0, 16.0, 38.0, 28.0];
              final baseH = baseHeights[i % baseHeights.length];

              final multiplier = widget.isRecording
                  ? (0.35 + 0.65 * math.sin((val * 2 * math.pi) + (i * 0.4)).abs())
                  : 0.2;
              final h = baseH * multiplier;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                width: 4,
                height: h.clamp(6.0, 46.0),
                decoration: BoxDecoration(
                  color: widget.isRecording
                      ? (i % 3 == 0 ? AppTheme.primaryContainer : AppTheme.primaryContainer.withValues(alpha: 0.7))
                      : AppTheme.surfaceHighest,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: widget.isRecording && i % 3 == 0
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// --- Audio Player Widget for Recorded Sermon Playback ---
class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final String timestampStr;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.timestampStr,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    try {
      _audioPlayer.onPlayerStateChanged.listen((s) {
        if (mounted) {
          setState(() {
            _isPlaying = s == PlayerState.playing;
          });
        }
      });

      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) {
          setState(() {
            _duration = d;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) {
          setState(() {
            _position = p;
          });
        }
      });
    } catch (e) {
      debugPrint('AudioPlayer setup error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      level: GlassLevel.level2,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppTheme.primaryContainer,
                  size: 44,
                ),
                onPressed: () async {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    if (widget.audioPath.isNotEmpty && File(widget.audioPath).existsSync()) {
                      await _audioPlayer.play(DeviceFileSource(widget.audioPath));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio session metadata saved on device.')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: AppTheme.primaryContainer,
                        inactiveTrackColor: AppTheme.surfaceHighest,
                        thumbColor: AppTheme.primaryContainer,
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
                        min: 0.0,
                        max: (_duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
                        onChanged: (val) async {
                          await _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(fontSize: 11, fontFamily: 'Monospace', color: AppTheme.onSurfaceVariant),
                          ),
                          Text(
                            _duration.inMilliseconds > 0 ? _formatDuration(_duration) : widget.timestampStr,
                            style: const TextStyle(fontSize: 11, fontFamily: 'Monospace', color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
