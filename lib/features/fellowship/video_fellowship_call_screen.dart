import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../../core/services/chat_firestore_service.dart';
import '../../core/services/call_signaling_service.dart';

class VideoFellowshipCallScreen extends ConsumerStatefulWidget {
  final String partnerId;
  final String partnerName;
  final bool isIncoming;

  const VideoFellowshipCallScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.isIncoming = false,
  });

  @override
  ConsumerState<VideoFellowshipCallScreen> createState() => _VideoFellowshipCallScreenState();
}

class _VideoFellowshipCallScreenState extends ConsumerState<VideoFellowshipCallScreen> {
  RtcEngine? _engine;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _signalingSubscription;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _callConnected = false;
  bool _isEnding = false;
  int? _remoteUid;
  String? _chatId;
  String _statusText = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    // Request camera & microphone runtime permissions
    await [Permission.camera, Permission.microphone].request();

    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    final chatId = ChatFirestoreService.getChatId(authProfile.id, widget.partnerId);
    _chatId = chatId;

    if (!widget.isIncoming) {
      await CallSignalingService().startCall(
        chatId: chatId,
        callerId: authProfile.id,
        calleeId: widget.partnerId,
        callType: 'video',
      );
    }

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('generateAgoraRtcToken')
          .call({'channelName': chatId});
      final data = result.data as Map;

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: data['appId'] as String));
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) {
            setState(() {
              _callConnected = true;
              _statusText = 'Video Fellowship Connected ✅';
            });
          }
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) {
            setState(() => _remoteUid = remoteUid);
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) {
            setState(() => _remoteUid = null);
          }
          _endCall();
        },
        onError: (err, msg) {
          debugPrint('Agora RTC Error: $err $msg');
        },
      ));

      await engine.enableVideo();
      await engine.startPreview(); // local camera preview before/while connecting
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
      if (mounted) {
        setState(() {});
      }

      // Watch for the other party declining/ending
      _signalingSubscription = CallSignalingService().watchCall(chatId).listen((snap) {
        final status = snap.data()?['status'];
        if (status == 'declined' || status == 'ended') {
          _endCall();
        }
      });
    } catch (e) {
      debugPrint('Exception setting up video call engine: $e');
      if (mounted) {
        setState(() => _statusText = 'Call Connection Error');
      }
    }
  }

  Future<void> _endCall() async {
    if (_isEnding) return;
    _isEnding = true;
    _signalingSubscription?.cancel();
    if (_chatId != null) {
      await CallSignalingService().endCall(_chatId!);
    }
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _signalingSubscription?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video Stream Representation or Connecting Placeholder
          _remoteUid != null && _engine != null && _chatId != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: _chatId!),
                  ),
                )
              : Container(
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
                          widget.partnerName.isNotEmpty ? widget.partnerName[0].toUpperCase() : 'P',
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
                      const SizedBox(height: 12),
                      Text(
                        _callConnected ? 'Waiting for remote video...' : _statusText,
                        style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

          // Picture-in-Picture Local Video Preview
          if (_engine != null)
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
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
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
              onPressed: _endCall,
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
                    onPressed: () async {
                      final newValue = !_isMuted;
                      setState(() => _isMuted = newValue);
                      try {
                        await _engine?.muteLocalAudioStream(newValue);
                      } catch (e) {
                        if (mounted) setState(() => _isMuted = !newValue);
                        debugPrint('muteLocalAudioStream failed: $e');
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam, color: _isVideoOff ? AppTheme.error : AppTheme.onSurface),
                    onPressed: () async {
                      final newValue = !_isVideoOff;
                      setState(() => _isVideoOff = newValue);
                      try {
                        await _engine?.enableLocalVideo(!newValue);
                      } catch (e) {
                        if (mounted) setState(() => _isVideoOff = !newValue);
                        debugPrint('enableLocalVideo failed: $e');
                      }
                    },
                  ),
                  // End Call Button
                  GestureDetector(
                    onTap: _endCall,
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
