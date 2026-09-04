import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/bible_database_service.dart';

class SermonState {
  final List<SermonNoteItem> notes;
  final String activeSermonTitle;
  final String activeSpeakerName;
  final String activeSeriesName;
  final bool isRecording;
  final int recordingSeconds;
  final bool isLoading;
  final String searchQuery;
  final String? currentRecordingPath;

  const SermonState({
    this.notes = const [],
    this.activeSermonTitle = 'Abiding in the Vine & Sacred Fellowship',
    this.activeSpeakerName = 'Pastor Kaleb',
    this.activeSeriesName = 'Kingdom Roots Vol. 4',
    this.isRecording = false,
    this.recordingSeconds = 0,
    this.isLoading = false,
    this.searchQuery = '',
    this.currentRecordingPath,
  });

  String get currentTimestampStr {
    final hours = (recordingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((recordingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  List<SermonNoteItem> get filteredNotes {
    if (searchQuery.trim().isEmpty) return notes;
    final query = searchQuery.toLowerCase().trim();
    return notes.where((n) {
      return n.noteTitle.toLowerCase().contains(query) ||
          n.content.toLowerCase().contains(query) ||
          n.scriptureRef.toLowerCase().contains(query) ||
          n.sermonTitle.toLowerCase().contains(query) ||
          n.speakerName.toLowerCase().contains(query);
    }).toList();
  }

  SermonState copyWith({
    List<SermonNoteItem>? notes,
    String? activeSermonTitle,
    String? activeSpeakerName,
    String? activeSeriesName,
    bool? isRecording,
    int? recordingSeconds,
    bool? isLoading,
    String? searchQuery,
    String? currentRecordingPath,
  }) {
    return SermonState(
      notes: notes ?? this.notes,
      activeSermonTitle: activeSermonTitle ?? this.activeSermonTitle,
      activeSpeakerName: activeSpeakerName ?? this.activeSpeakerName,
      activeSeriesName: activeSeriesName ?? this.activeSeriesName,
      isRecording: isRecording ?? this.isRecording,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
    );
  }
}

class SermonNotifier extends StateNotifier<SermonState> {
  final BibleDatabaseService _dbService = BibleDatabaseService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;

  SermonNotifier() : super(const SermonState()) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _dbService.getSermonNotes();
      state = state.copyWith(notes: list, isLoading: false);
    } catch (e) {
      debugPrint('Error loading sermon notes: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      try {
        final path = await _audioRecorder.stop();
        _recordingTimer?.cancel();
        state = state.copyWith(
          isRecording: false,
          currentRecordingPath: path ?? state.currentRecordingPath,
        );
      } catch (e) {
        debugPrint('Error stopping recorder: $e');
        _recordingTimer?.cancel();
        state = state.copyWith(isRecording: false);
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final filePath = p.join(dir.path, 'sermon_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
          
          _recordingTimer?.cancel();
          _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
          });
          state = state.copyWith(isRecording: true, currentRecordingPath: filePath);
        } else {
          debugPrint('Microphone permission denied, running timer.');
          _startFallbackTimer();
        }
      } catch (e) {
        debugPrint('Error starting recorder: $e');
        _startFallbackTimer();
      }
    }
  }

  void _startFallbackTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
    });
    state = state.copyWith(isRecording: true);
  }

  Future<String?> stopAndGetAudioPath() async {
    _recordingTimer?.cancel();
    if (state.isRecording) {
      try {
        final path = await _audioRecorder.stop();
        state = state.copyWith(isRecording: false, currentRecordingPath: path);
        return path ?? state.currentRecordingPath;
      } catch (e) {
        debugPrint('Error stopping recorder: $e');
      }
    }
    state = state.copyWith(isRecording: false);
    return state.currentRecordingPath;
  }

  void startNewSession({required String title, required String speaker, String? series, bool autoStart = false}) {
    _recordingTimer?.cancel();
    state = state.copyWith(
      activeSermonTitle: title.trim().isEmpty ? 'Live Audio Sermon' : title.trim(),
      activeSpeakerName: speaker.trim().isEmpty ? 'Pastor' : speaker.trim(),
      activeSeriesName: series?.trim().isEmpty == false ? series!.trim() : 'Sunday Service',
      recordingSeconds: 0,
      isRecording: false,
      currentRecordingPath: null,
    );
  }

  void setSermonSession({required String title, required String speaker, String? series}) {
    state = state.copyWith(
      activeSermonTitle: title.trim().isEmpty ? 'Sermon Reflection' : title.trim(),
      activeSpeakerName: speaker.trim().isEmpty ? 'Pastor' : speaker.trim(),
      activeSeriesName: series?.trim() ?? 'Sunday Service',
    );
  }

  Future<void> addNote({
    required String noteTitle,
    required String content,
    required String scriptureRef,
    String? audioPath,
  }) async {
    final newItem = SermonNoteItem(
      sermonTitle: state.activeSermonTitle,
      speakerName: state.activeSpeakerName,
      noteTitle: noteTitle.trim().isEmpty ? 'Personal Reflection' : noteTitle.trim(),
      content: content.trim(),
      scriptureRef: scriptureRef.trim(),
      timestampStr: state.currentTimestampStr,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      audioPath: audioPath ?? state.currentRecordingPath,
    );

    await _dbService.addSermonNote(newItem);
    await _loadNotes();
  }

  Future<void> updateNote(SermonNoteItem note) async {
    await _dbService.updateSermonNote(note);
    await _loadNotes();
  }

  Future<void> deleteNote(int id) async {
    await _dbService.deleteSermonNote(id);
    await _loadNotes();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}

final sermonProvider = StateNotifierProvider<SermonNotifier, SermonState>((ref) {
  return SermonNotifier();
});
