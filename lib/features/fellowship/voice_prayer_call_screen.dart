import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';

class VoicePrayerCallScreen extends StatefulWidget {
  final String partnerName;

  const VoicePrayerCallScreen({
    super.key,
    required this.partnerName,
  });

  @override
  State<VoicePrayerCallScreen> createState() => _VoicePrayerCallScreenState();
}

class _VoicePrayerCallScreenState extends State<VoicePrayerCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _isMuted = false;
  bool _isSpeaker = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.onSurface, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Column(
                    children: [
                      LiveBadge(label: 'AUDIO SANCTUM'),
                      SizedBox(height: 4),
                      Text(
                        '08:42 • Encrypted Intercession',
                        style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined, color: AppTheme.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Pulsing Audio Visualizer Avatar Center
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceLow,
                      border: Border.all(color: AppTheme.primaryContainer, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.partnerName[0],
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              widget.partnerName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Praying in One Accord',
              style: TextStyle(fontSize: 14, color: AppTheme.primaryContainer),
            ),

            const Spacer(),

            // Shared Scripture Reflection Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassCard(
                level: GlassLevel.level2,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_quote, color: AppTheme.primaryContainer, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Shared Scripture Focus',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '“I am the vine. You are the branches. He who remains in me, and I in him, bears much fruit...”',
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.onSurface, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '— John 15:5 (WEB)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Call Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  GestureDetector(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isMuted ? AppTheme.errorContainer : AppTheme.surfaceHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? AppTheme.error : AppTheme.onSurface,
                        size: 24,
                      ),
                    ),
                  ),

                  // End Call Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorContainer,
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_end, color: AppTheme.error, size: 28),
                    ),
                  ),

                  // Speaker
                  GestureDetector(
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isSpeaker ? AppTheme.primaryContainer.withValues(alpha: 0.2) : AppTheme.surfaceHigh,
                        shape: BoxShape.circle,
                        border: _isSpeaker ? Border.all(color: AppTheme.primaryContainer) : null,
                      ),
                      child: Icon(
                        _isSpeaker ? Icons.volume_up : Icons.volume_down,
                        color: _isSpeaker ? AppTheme.primaryContainer : AppTheme.onSurface,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
