import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/mock_auth_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'features/auth/login_signup_modal.dart';
import 'features/bible/bible_reader_screen.dart';
import 'features/sermon/sermon_studio_screen.dart';
import 'features/feed/sanctuary_community_feed_screen.dart';
import 'features/live/live_fellowship_worship_room_screen.dart';
import 'features/profile/profile_journey_hub_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _screens = [
    BibleReaderScreen(),
    SermonStudioScreen(),
    LiveFellowshipWorshipRoomScreen(),
    SanctuaryCommunityFeedScreen(),
    ProfileJourneyHubScreen(),
  ];

  void _onTabTapped(BuildContext context, WidgetRef ref, int targetIndex) {
    final authState = ref.read(mockAuthNotifierProvider);

    // Gated tabs: Live (2) and Feed (3) require soft-gate if unauthenticated
    final bool isGatedTab = (targetIndex == 2 || targetIndex == 3);

    if (isGatedTab && authState.isGuest) {
      final tabName = targetIndex == 2 ? 'Live Worship Rooms' : 'Community Feed';
      LoginSignupModal.show(context, gatedActionTitle: 'access $tabName').then((_) {
        // Check if user authenticated during the modal interaction
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
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navigationProvider);

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
