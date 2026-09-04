import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';

class VideoFellowshipCallScreen extends StatefulWidget {
  final String partnerName;

  const VideoFellowshipCallScreen({
    super.key,
    required this.partnerName,
  });

  @override
  State<VideoFellowshipCallScreen> createState() => _VideoFellowshipCallScreenState();
}

class _VideoFellowshipCallScreenState extends State<VideoFellowshipCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video Stream Representation
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1C14), Color(0xFF042014), Color(0xFF08120C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                  child: Text(
                    widget.partnerName[0],
                    style: const TextStyle(fontSize: 48, color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.partnerName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                ),
                const SizedBox(height: 6),
                const LiveBadge(label: 'VIDEO FELLOWSHIP'),
              ],
            ),
          ),

          // Picture-in-Picture Local Video Preview
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 110,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.emeraldStrokeAlpha40, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _isVideoOff
                    ? const Center(
                        child: Icon(Icons.videocam_off, color: AppTheme.onSurfaceVariant),
                      )
                    : Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            color: const Color(0xFF15261D),
                            child: const Center(
                              child: Icon(Icons.person, color: AppTheme.primaryContainer, size: 36),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.black54,
                            width: double.infinity,
                            child: const Text(
                              'You',
                              style: TextStyle(fontSize: 10, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Top Header & Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Bottom Control Overlay
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: GlassCard(
              level: GlassLevel.level3,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? AppTheme.error : AppTheme.onSurface),
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                  ),
                  IconButton(
                    icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam, color: _isVideoOff ? AppTheme.error : AppTheme.onSurface),
                    onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                  ),
                  // End Call Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: AppTheme.error, size: 24),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.screen_share, color: AppTheme.secondary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu_book, color: AppTheme.primaryContainer),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
