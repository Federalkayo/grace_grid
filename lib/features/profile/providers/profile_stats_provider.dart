import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/mock_auth_provider.dart';
import '../../../core/services/bible_database_service.dart';
import '../../../core/services/feed_firestore_service.dart';

/// Bumped whenever a real Journey event happens (a chapter is read, a
/// sermon note is saved, a prayer is shared). The Profile screen lives in
/// an IndexedStack tab that's never unmounted, so `autoDispose` alone won't
/// refetch its stats after the first visit — watching this tick is what
/// makes profileStatsProvider/badgeStatusProvider/activityFeedProvider
/// recompute on the next real event instead of showing stale cached numbers.
final journeyRefreshTickProvider = StateProvider<int>((ref) => 0);

/// Real Profile stats — replaces the hardcoded streak/verses/notes/prayers
/// numbers that used to live on [UserProfile].
class ProfileStats {
  final int streakDays;
  final int versesReadCount;
  final int sermonNotesCount;
  final int prayersSharedCount;

  const ProfileStats({
    this.streakDays = 0,
    this.versesReadCount = 0,
    this.sermonNotesCount = 0,
    this.prayersSharedCount = 0,
  });
}

/// Real unlock status for the Scripture Mastery Badges section.
class BadgeStatus {
  final bool vineAbiderUnlocked; // Read John 15
  final bool shepherdPathUnlocked; // Read Psalm 23
  final bool prayerWallHostUnlocked; // Shared 10+ prayers

  const BadgeStatus({
    this.vineAbiderUnlocked = false,
    this.shepherdPathUnlocked = false,
    this.prayerWallHostUnlocked = false,
  });
}

/// A single row for the Recent Journey Activity feed.
class ActivityFeedItem {
  final String type;
  final String title;
  final String timeAgo;

  const ActivityFeedItem({
    required this.type,
    required this.title,
    required this.timeAgo,
  });
}

/// Computes the real profile stats by combining local Journey tracking
/// (reading streak, verses read, sermon notes) with the real Prayer Wall
/// count from Firestore. Recomputes whenever [journeyRefreshTickProvider]
/// changes (see above), and disposes when nobody's watching it at all.
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((ref) async {
  ref.watch(journeyRefreshTickProvider);
  final authState = ref.watch(mockAuthNotifierProvider);
  final db = BibleDatabaseService();
  final feedService = FeedFirestoreService();

  final results = await Future.wait<int>([
    db.getCurrentStreak(),
    db.getTotalVersesRead(),
    db.getSermonNotesCount(),
    feedService.getPrayerCountForUser(authState.profile.id),
  ]);

  return ProfileStats(
    streakDays: results[0],
    versesReadCount: results[1],
    sermonNotesCount: results[2],
    prayersSharedCount: results[3],
  );
});

/// Computes which Scripture Mastery Badges are actually unlocked.
final badgeStatusProvider = FutureProvider.autoDispose<BadgeStatus>((ref) async {
  final stats = await ref.watch(profileStatsProvider.future);
  final db = BibleDatabaseService();

  final results = await Future.wait<bool>([
    db.isChapterRead('JHN', 15),
    db.isChapterRead('PSA', 23),
  ]);

  return BadgeStatus(
    vineAbiderUnlocked: results[0],
    shepherdPathUnlocked: results[1],
    prayerWallHostUnlocked: stats.prayersSharedCount >= 10,
  );
});

/// Recent Journey Activity feed, sourced entirely from the local activity
/// log (reading, sermon notes, prayers) instead of static placeholder rows.
final activityFeedProvider = FutureProvider.autoDispose<List<ActivityFeedItem>>((ref) async {
  ref.watch(journeyRefreshTickProvider);
  final db = BibleDatabaseService();
  final entries = await db.getRecentActivity(limit: 8);
  return entries
      .map((e) => ActivityFeedItem(type: e.type, title: e.title, timeAgo: e.timeAgo))
      .toList();
});
