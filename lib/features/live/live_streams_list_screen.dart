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

  Future<void> _handleGoLivePrompt() async {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: 'start a Live Worship Stream');
      return;
    }

    final bool? withVideo = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Start Live Worship Stream',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you would like to minister to the community today.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: AppTheme.primaryContainer),
                ),
                title: const Text('Audio-Only Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Stream worship audio, prayers & chants'),
                onTap: () => Navigator.pop(context, false),
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam, color: AppTheme.primaryContainer),
                ),
                title: const Text('Video + Audio Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Live video camera feed & audio stream'),
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 12),
            ],
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
        title: const Row(
          children: [
            LiveBadge(label: 'LIVE WORSHIP'),
            SizedBox(width: 10),
            Text(
              'Sanctuary Sanctuary Rooms',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                level: GlassLevel.level2,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Worship Sanctuary Live',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Join live fellowship, prayer chants, or lead a worship broadcast for believers worldwide.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimarySanctuaryButton(
                            text: 'Go Live Now',
                            icon: Icons.cell_tower,
                            onPressed: _handleGoLivePrompt,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Active Live Rooms',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ),
          ),
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

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 64,
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Streams Right Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first believer to initiate a live worship or prayer stream for the community.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryContainer,
                              foregroundColor: AppTheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            onPressed: _handleGoLivePrompt,
                            icon: const Icon(Icons.videocam),
                            label: const Text('Start Stream'),
                          ),
                        ],
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
                          level: GlassLevel.level1,
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
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
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
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.surfaceLow,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          hasVideo ? Icons.videocam : Icons.mic,
                                          size: 14,
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
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          const LiveBadge(label: 'LIVE'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            hasVideo ? Icons.video_call : Icons.graphic_eq,
                                            size: 14,
                                            color: AppTheme.onSurfaceVariant,
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
                                            size: 14,
                                            color: Colors.redAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${likesList.length}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.onSurfaceVariant,
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
    );
  }
}
