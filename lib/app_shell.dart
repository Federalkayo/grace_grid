import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/mock_auth_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/services/call_signaling_service.dart';
import 'features/auth/login_signup_modal.dart';
import 'features/bible/bible_reader_screen.dart';
import 'features/sermon/sermon_studio_screen.dart';
import 'features/feed/sanctuary_community_feed_screen.dart';
import 'features/fellowship/voice_prayer_call_screen.dart';
import 'features/fellowship/video_fellowship_call_screen.dart';
import 'features/live/live_fellowship_worship_room_screen.dart';
import 'features/profile/profile_journey_hub_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callSubscription;
  String? _listeningUid;
  String? _activeRingingChatId;
  BuildContext? _incomingDialogContext;

  static const List<Widget> _screens = [
    BibleReaderScreen(),
    SermonStudioScreen(),
    LiveFellowshipWorshipRoomScreen(),
    SanctuaryCommunityFeedScreen(),
    ProfileJourneyHubScreen(),
  ];

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  void _listenForIncomingCalls(String myUid) {
    if (myUid == _listeningUid) return;
    _callSubscription?.cancel();
    _listeningUid = myUid;

    if (myUid.isEmpty || myUid == 'guest') return;

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final chatId = doc.id;
        final callerId = doc.data()['callerId'] as String? ?? '';
        final callType = doc.data()['callType'] as String? ?? 'voice';
        if (_activeRingingChatId != chatId) {
          _activeRingingChatId = chatId;
          _showIncomingCallDialog(chatId, callerId, callType);
        }
      } else {
        if (_activeRingingChatId != null) {
          _activeRingingChatId = null;
          if (_incomingDialogContext != null && mounted) {
            Navigator.of(_incomingDialogContext!).pop();
            _incomingDialogContext = null;
          }
        }
      }
    });
  }

  Future<void> _showIncomingCallDialog(String chatId, String callerId, String callType) async {
    String callerName = 'Fellow Believer';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(callerId).get();
      if (userDoc.exists && userDoc.data()?['name'] != null) {
        callerName = userDoc.data()!['name'] as String;
      }
    } catch (_) {}

    if (!mounted) return;

    final isVideo = callType == 'video';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _incomingDialogContext = dialogContext;
        return Dialog(
          backgroundColor: AppTheme.surfaceLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isVideo ? Icons.videocam : Icons.phone_in_talk, size: 14, color: AppTheme.primaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        isVideo ? 'INCOMING VIDEO CALL' : 'INCOMING AUDIO CALL',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                  child: Text(
                    callerName.isNotEmpty ? callerName[0].toUpperCase() : 'C',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  callerName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isVideo ? 'Inviting you to video fellowship' : 'Inviting you to pray in one accord',
                  style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.errorContainer,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.call_end, color: AppTheme.error, size: 28),
                      onPressed: () async {
                        _incomingDialogContext = null;
                        _activeRingingChatId = null;
                        Navigator.of(dialogContext).pop();
                        await CallSignalingService().updateStatus(chatId, CallStatus.declined);
                      },
                    ),
                    // Accept
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.emeraldStrokeAlpha25,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: Icon(isVideo ? Icons.videocam : Icons.call, color: AppTheme.primaryContainer, size: 28),
                      onPressed: () async {
                        _incomingDialogContext = null;
                        _activeRingingChatId = null;
                        Navigator.of(dialogContext).pop();
                        await CallSignalingService().updateStatus(chatId, CallStatus.accepted);
                        if (mounted) {
                          if (callType == 'video') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VideoFellowshipCallScreen(
                                  partnerId: callerId,
                                  partnerName: callerName,
                                  isIncoming: true,
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VoicePrayerCallScreen(
                                  partnerId: callerId,
                                  partnerName: callerName,
                                  isIncoming: true,
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _incomingDialogContext = null;
    });
  }

  void _onTabTapped(BuildContext context, WidgetRef ref, int targetIndex) {
    final authState = ref.read(mockAuthNotifierProvider);

    final bool isGatedTab = (targetIndex == 2 || targetIndex == 3);

    if (isGatedTab && authState.isGuest) {
      final tabName = targetIndex == 2 ? 'Live Worship Rooms' : 'Community Feed';
      LoginSignupModal.show(context, gatedActionTitle: 'access $tabName').then((_) {
        final updatedAuth = ref.read(mockAuthNotifierProvider);
        if (updatedAuth.isAuthenticated) {
          ref.read(navigationProvider.notifier).setTab(targetIndex);
        }
      });
    } else {
      ref.read(navigationProvider.notifier).setTab(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(navigationProvider);
    final authState = ref.watch(mockAuthNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForIncomingCalls(authState.profile.id);
    });

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLow,
          border: Border(
            top: BorderSide(
              color: AppTheme.emeraldStrokeAlpha15,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) => _onTabTapped(context, ref, index),
          backgroundColor: AppTheme.surfaceLow,
          selectedItemColor: AppTheme.primaryContainer,
          unselectedItemColor: AppTheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Bible',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_none),
              activeIcon: Icon(Icons.mic),
              label: 'Sermons',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors_outlined),
              activeIcon: Icon(Icons.sensors),
              label: 'Live',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dynamic_feed_outlined),
              activeIcon: Icon(Icons.dynamic_feed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
