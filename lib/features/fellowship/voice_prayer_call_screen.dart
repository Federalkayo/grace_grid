import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../../core/services/agora_token_service.dart';
import '../../core/services/chat_firestore_service.dart';
import '../../core/services/call_signaling_service.dart';
import '../../core/services/ringtone_service.dart';

class VoicePrayerCallScreen extends ConsumerStatefulWidget {
  final String partnerId;
  final String partnerName;
  final bool isIncoming;

  const VoicePrayerCallScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.isIncoming = false,
  });

  @override
  ConsumerState<VoicePrayerCallScreen> createState() => _VoicePrayerCallScreenState();
}

class _VoicePrayerCallScreenState extends ConsumerState<VoicePrayerCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  RtcEngine? _engine;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _signalingSubscription;
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _callConnected = false;
  bool _isEnding = false;
  String _statusText = 'Connecting...';

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

    _startCall();
  }

  Future<void> _startCall() async {
    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    final chatId = ChatFirestoreService.getChatId(authProfile.id, widget.partnerId);

    if (!widget.isIncoming) {
      await CallSignalingService().startCall(
        chatId: chatId,
        callerId: authProfile.id,
        calleeId: widget.partnerId,
      );
      await RingtoneService.instance.playOutgoing();
    }

    try {
      final data = await fetchAgoraRtcToken(chatId);

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: data['appId'] as String));
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) {
            setState(() {
              _callConnected = true;
              _statusText = 'Encrypted Intercession Connected ✅';
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) => _endCall(),
        onError: (err, msg) {
          debugPrint('Agora RTC Error: $err $msg');
        },
      ));

      await engine.enableAudio();
      await engine.joinChannel(
        token: data['token'] as String,
        channelId: chatId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      _engine = engine;

      // Watch for the other party accepting/declining/ending
      _signalingSubscription = CallSignalingService().watchCall(chatId).listen((snap) {
        final status = snap.data()?['status'];
        if (status == 'accepted') {
          RingtoneService.instance.stop();
        } else if (status == 'declined' || status == 'ended') {
          _endCall();
        }
      });
    } catch (e) {
      debugPrint('Exception setting up call engine: $e');
      if (mounted) {
        setState(() => _statusText = 'Call Connection Error');
      }
    }
  }

  Future<void> _endCall() async {
    if (_isEnding) return;
    _isEnding = true;
    RingtoneService.instance.stop();
    _signalingSubscription?.cancel();
    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    final chatId = ChatFirestoreService.getChatId(authProfile.id, widget.partnerId);
    await CallSignalingService().endCall(chatId);
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    RingtoneService.instance.stop();
    _pulseController.dispose();
    _signalingSubscription?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
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
                    onPressed: _endCall,
                  ),
                  Column(
                    children: [
                      const LiveBadge(label: 'AUDIO SANCTUM'),
                      const SizedBox(height: 4),
                      Text(
                        _statusText,
                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // Spacer balance for header
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
                        widget.partnerName.isNotEmpty ? widget.partnerName[0].toUpperCase() : 'P',
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
            Text(
              _callConnected ? 'Praying in One Accord' : 'Ringing...',
              style: const TextStyle(fontSize: 14, color: AppTheme.primaryContainer),
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
                    onTap: () async {
                      setState(() => _isMuted = !_isMuted);
                      await _engine?.muteLocalAudioStream(_isMuted);
                    },
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
                    onTap: _endCall,
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
                    onTap: () async {
                      setState(() => _isSpeaker = !_isSpeaker);
                      await _engine?.setEnableSpeakerphone(_isSpeaker);
                    },
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
