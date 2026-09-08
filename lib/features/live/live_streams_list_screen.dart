import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/mock_auth_provider.dart';
import '../../core/services/live_session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_buttons.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../auth/login_signup_modal.dart';
import 'live_fellowship_worship_room_screen.dart';

class LiveStreamsListScreen extends ConsumerStatefulWidget {
  const LiveStreamsListScreen({super.key});

  @override
  ConsumerState<LiveStreamsListScreen> createState() => _LiveStreamsListScreenState();
}

class _LiveStreamsListScreenState extends ConsumerState<LiveStreamsListScreen> {
  final LiveSessionService _sessionService = LiveSessionService();
  bool _isStartingStream = false;

  /// Pull-to-refresh handler. watchActiveRooms() is called fresh on every
  /// build (it's not cached in a field), so simply rebuilding is enough to
  /// force StreamBuilder to drop the old subscription and resubscribe —
  /// handy if the live list ever looks stuck or a transient Firestore error
  /// left it stale.
  Future<void> _handleRefresh() async {
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _handleGoLivePrompt() async {
    if (_isStartingStream) return;
    _isStartingStream = true;
    try {
      await _handleGoLivePromptInner();
    } finally {
      _isStartingStream = false;
    }
  }

  Future<void> _handleGoLivePromptInner() async {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: 'start a Live Worship Stream');
      return;
    }

    final bool? withVideo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      LiveBadge(label: 'NEW'),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select Stream Mode',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose how you would like to minister and fellowship with the community.',
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => Navigator.pop(context, false),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic_rounded, color: AppTheme.primaryContainer, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audio-Only Broadcast',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Stream worship audio & intercession chants',
                                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.primaryContainer, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => Navigator.pop(context, true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam_rounded, color: AppTheme.primaryContainer, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Video + Audio Broadcast',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Live camera feed with high quality audio',
                                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.primaryContainer, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (withVideo == null || !mounted) return;

    final authProfile = authState.profile;
    try {
      final roomId = await _sessionService.goLive(
        hostId: authProfile.id,
        hostName: authProfile.name,
        hostAvatar: authProfile.avatarUrl,
        hasVideo: withVideo,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveFellowshipWorshipRoomScreen(
            roomId: roomId,
            hostId: authProfile.id,
            hostName: authProfile.name,
            hasVideo: withVideo,
            isHostStarting: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start stream: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            LiveBadge(label: 'LIVE'),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sanctuary Worship Rooms',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryContainer,
        backgroundColor: AppTheme.surfaceLow,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
          // Hero Banner Container
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0B2B1B),
                      Color(0xFF041A0F),
                      Color(0xFF03100A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryContainer.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors_rounded, size: 14, color: AppTheme.primaryContainer),
                          SizedBox(width: 6),
                          Text(
                            'REAL-TIME SANCTUARY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryContainer,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Worship & Fellowship Sanctuary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join live prayer intercession, spiritual audio chants, or broadcast video to believers globally.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    PrimarySanctuaryButton(
                      text: 'Go Live Now',
                      icon: Icons.cell_tower,
                      fullWidth: true,
                      onPressed: _handleGoLivePrompt,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Section Title Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.radio_button_checked_rounded, color: Colors.redAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Active Live Rooms',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _sessionService.watchActiveRooms(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHighest,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '$count Active',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryContainer,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Live Rooms List or Empty State
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _sessionService.watchActiveRooms(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryContainer),
                  ),
                );
              }

              if (snapshot.hasError) {
                // Surface this in logs so a missing Firestore index (or a
                // rules issue) shows up immediately instead of silently
                // rendering as "no active streams".
                debugPrint('watchActiveRooms() stream error: ${snapshot.error}');
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: GlassCard(
                        level: GlassLevel.level1,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.graphic_eq_rounded,
                                size: 48,
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No Active Streams Right Now',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first believer or minister to initiate a live worship or prayer stream for the community.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            PrimarySanctuaryButton(
                              text: 'Start Stream',
                              icon: Icons.videocam_rounded,
                              onPressed: _handleGoLivePrompt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final roomId = doc.id;
                      final hostName = data['hostName'] as String? ?? 'Grace Believer';
                      final hostAvatar = data['hostAvatar'] as String? ?? '';
                      final hasVideo = data['hasVideo'] as bool? ?? false;
                      final likesList = (data['likedUserIds'] as List?) ?? [];
                      final hostId = data['hostId'] as String? ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassCard(
                          level: GlassLevel.level2,
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LiveFellowshipWorshipRoomScreen(
                                    roomId: roomId,
                                    hostId: hostId,
                                    hostName: hostName,
                                    hasVideo: hasVideo,
                                    isHostStarting: false,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.redAccent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: AppTheme.surfaceHighest,
                                        backgroundImage: hostAvatar.isNotEmpty
                                            ? NetworkImage(hostAvatar)
                                            : null,
                                        child: hostAvatar.isEmpty
                                            ? Text(
                                                hostName.isNotEmpty ? hostName[0].toUpperCase() : 'G',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryContainer,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.surfaceLow,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          hasVideo ? Icons.videocam : Icons.mic,
                                          size: 13,
                                          color: AppTheme.primaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              hostName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const LiveBadge(label: 'LIVE'),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            hasVideo ? Icons.video_call : Icons.graphic_eq,
                                            size: 14,
                                            color: AppTheme.primaryContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasVideo ? 'Video Stream' : 'Audio Prayer Chants',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.favorite,
                                            size: 13,
                                            color: Colors.redAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${likesList.length}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          StreamBuilder<int>(
                                            stream: _sessionService.watchViewerCount(roomId),
                                            builder: (context, viewerSnap) {
                                              final viewerCount = viewerSnap.data ?? 0;
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.remove_red_eye_outlined,
                                                    size: 13,
                                                    color: AppTheme.primaryContainer,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$viewerCount',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Text(
                                    'Join',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
