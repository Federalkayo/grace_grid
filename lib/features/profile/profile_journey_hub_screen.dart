import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_buttons.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../auth/login_signup_modal.dart';
import '../fellowship/fellowship_conversations_screen.dart';

class ProfileJourneyHubScreen extends ConsumerWidget {
  const ProfileJourneyHubScreen({super.key});

  Future<void> _pickAndChangeAvatar(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        final success = await ref.read(mockAuthNotifierProvider.notifier).updateProfileAvatar(image);
        if (context.mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppTheme.primaryContainer,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not set profile image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAvatarPickerModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.emeraldStrokeAlpha25,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryContainer),
              title: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickAndChangeAvatar(context, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryContainer),
              title: const Text('Take a Photo', style: TextStyle(color: AppTheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickAndChangeAvatar(context, ref, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getAvatarProvider(String avatarUrl) {
    return getAvatarImageProvider(avatarUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(mockAuthNotifierProvider);
    final profile = authState.profile;
    final avatarProvider = _getAvatarProvider(profile.avatarUrl);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        title: Text(
          authState.isGuest ? 'Guest Sanctuary Profile' : 'Believer Journey Hub',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppTheme.primaryContainer),
            tooltip: 'Fellowship Messages',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FellowshipConversationsScreen(),
                ),
              );
            },
          ),
          if (authState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.error),
              onPressed: () {
                ref.read(mockAuthNotifierProvider.notifier).logout();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          GlassCard(
            level: GlassLevel.level2,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarPickerModal(context, ref),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                        backgroundImage: avatarProvider,
                        child: avatarProvider == null
                            ? Icon(
                                authState.isGuest ? Icons.person_outline : Icons.auto_awesome,
                                size: 40,
                                color: AppTheme.primaryContainer,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: AppTheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  profile.email,
                  style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Streak', '${profile.streakDays} Days', Icons.local_fire_department),
                    _buildStatItem('Verses', '${profile.versesReadCount}', Icons.menu_book),
                    _buildStatItem('Notes', '${profile.sermonNotesCount}', Icons.edit_note),
                    if (authState.isAuthenticated)
                      _buildStatItem('Prayers', '${profile.prayersSharedCount}', Icons.favorite),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Guest Soft-Gate Banner (if in Guest mode)
          if (authState.isGuest) ...[
            GlassCard(
              level: GlassLevel.level3,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_open, color: AppTheme.primaryContainer, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Unlock Full Community & Fellowship',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create an account to backup your reading streaks, share prayer requests on the Community Wall, and join 1:1 Audio Sanctum calls.',
                    style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  PrimarySanctuaryButton(
                    text: 'Sign In / Link Account',
                    fullWidth: true,
                    onPressed: () {
                      LoginSignupModal.show(context, gatedActionTitle: 'unlock Fellowship');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Scripture Mastery Badges Section
          Text(
            'Scripture Mastery Badges',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 16,
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildBadgeCard(
                  title: 'Vine Abider',
                  subtitle: 'Read John 15 in WEB',
                  icon: Icons.eco,
                  isUnlocked: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBadgeCard(
                  title: 'Shepherd Path',
                  subtitle: 'Meditated on Psalm 23',
                  icon: Icons.shield,
                  isUnlocked: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBadgeCard(
                  title: 'Prayer Wall Host',
                  subtitle: authState.isAuthenticated ? 'Shared 10+ Prayers' : 'Sign in to Unlock',
                  icon: Icons.favorite,
                  isUnlocked: authState.isAuthenticated,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Journey Log / Local History
          Text(
            'Recent Journey Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 16,
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),

          GlassCard(
            level: GlassLevel.level1,
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                _ActivityRow(
                  icon: Icons.check_circle_outline,
                  title: 'Completed John 15 Reading',
                  time: 'Today • 20 mins ago',
                ),
                Divider(color: AppTheme.emeraldStrokeAlpha15),
                _ActivityRow(
                  icon: Icons.mic_none,
                  title: 'Took Live Notes on Pastor Kaleb Sermon',
                  time: 'Yesterday • 00:14:32 rec',
                ),
                Divider(color: AppTheme.emeraldStrokeAlpha15),
                _ActivityRow(
                  icon: Icons.star_border,
                  title: 'Earned 4-Day Daily Scripture Streak',
                  time: '3 days ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryContainer),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBadgeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUnlocked,
  }) {
    return GlassCard(
      level: GlassLevel.level1,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                  : AppTheme.surfaceHighest,
              shape: BoxShape.circle,
              border: isUnlocked
                  ? Border.all(color: AppTheme.primaryContainer)
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isUnlocked ? AppTheme.primaryContainer : AppTheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
