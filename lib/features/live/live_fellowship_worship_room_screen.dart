import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/agora_config.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../../core/services/live_session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../auth/login_signup_modal.dart';

class LiveFellowshipWorshipRoomScreen extends ConsumerStatefulWidget {
  final String? roomId;
  final String? hostId;
  final String? hostName;
  final bool isHostStarting;
  final bool hasVideo;

  const LiveFellowshipWorshipRoomScreen({
    super.key,
    this.roomId,
    this.hostId,
    this.hostName,
    this.isHostStarting = false,
    this.hasVideo = false,
  });

  @override
  ConsumerState<LiveFellowshipWorshipRoomScreen> createState() =>
      _LiveFellowshipWorshipRoomScreenState();
}

class _LiveFellowshipWorshipRoomScreenState
    extends ConsumerState<LiveFellowshipWorshipRoomScreen> {
  final LiveSessionService _sessionService = LiveSessionService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  RtcEngine? _engine;

  String? _currentRoomId;
  String? _hostId;
  String? _hostName;
  bool _hasVideo = false;
  bool _isLive = false;
  bool _isHost = false;
  bool _connected = false;
  bool _isMuted = false;
  int? _remoteHostUid;
  List<String> _likedUserIds = [];

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.roomId ?? AgoraConfig.liveWorshipRoomId;
    _hostId = widget.hostId;
    _hostName = widget.hostName;
    _hasVideo = widget.hasVideo;

    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    _isHost = widget.isHostStarting || (_hostId != null && _hostId == authProfile.id);

    _listenToRoomState();

    if (widget.isHostStarting) {
      _startHostStream(withVideo: widget.hasVideo);
    }
  }

  void _listenToRoomState() {
    final roomId = _currentRoomId;
    if (roomId == null) return;

    _roomSubscription = _sessionService.watchRoom(roomId).listen((snapshot) async {
      if (!mounted) return;
      if (!snapshot.exists) {
        if (_connected && !_isHost) {
          await _leaveAndReleaseEngine();
          if (mounted) setState(() => _isLive = false);
        }
        return;
      }

      final data = snapshot.data();
      if (data == null) return;

      final bool isLive = data['isLive'] as bool? ?? false;
      final String? hostId = data['hostId'] as String?;
      final String? hostName = data['hostName'] as String?;
      final bool hasVideo = data['hasVideo'] as bool? ?? false;
      final List<dynamic> likes = data['likedUserIds'] as List<dynamic>? ?? [];

      final authProfile = ref.read(mockAuthNotifierProvider).profile;
      final bool isMeHost = hostId != null && hostId == authProfile.id;

      setState(() {
        _isLive = isLive;
        _hostId = hostId;
        _hostName = hostName ?? _hostName;
        _hasVideo = hasVideo;
        _likedUserIds = likes.cast<String>();
        _isHost = isMeHost || widget.isHostStarting;
      });

      // Audience auto-join logic
      if (isLive && !_isHost && _engine == null && !_connected) {
        await _joinAsRole(ClientRoleType.clientRoleAudience, withVideo: hasVideo);
      } else if (!isLive && _connected && !_isHost) {
        await _leaveAndReleaseEngine();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The worship stream has ended.')),
          );
        }
      }
    });
  }

  Future<void> _startHostStream({required bool withVideo}) async {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: 'go live as host');
      return;
    }

    final authProfile = authState.profile;
    setState(() {
      _isHost = true;
      _hostId = authProfile.id;
      _hostName = authProfile.name;
      _hasVideo = withVideo;
    });

    if (widget.roomId == null) {
      _currentRoomId = await _sessionService.goLive(
        hostId: authProfile.id,
        hostName: authProfile.name,
        hostAvatar: authProfile.avatarUrl,
        hasVideo: withVideo,
      );
      _listenToRoomState();
    }

    await _joinAsRole(ClientRoleType.clientRoleBroadcaster, withVideo: withVideo);
  }

  Future<void> _joinAsRole(ClientRoleType role, {required bool withVideo}) async {
    final roomId = _currentRoomId;
    if (roomId == null) return;

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('generateAgoraRtcToken')
          .call({'channelName': roomId});
      final data = result.data as Map;

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: data['appId'] as String));

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _connected = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (role == ClientRoleType.clientRoleAudience) {
            if (mounted) setState(() => _remoteHostUid = remoteUid);
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (remoteUid == _remoteHostUid) {
            if (mounted) setState(() => _remoteHostUid = null);
          }
        },
        onError: (err, msg) {
          debugPrint('Agora RTC Error ($err): $msg');
        },
      ));

      await engine.enableAudio();

      if (withVideo) {
        await engine.enableVideo();
        if (role == ClientRoleType.clientRoleBroadcaster) {
          await engine.startPreview();
        }
      }

      await engine.joinChannel(
        token: data['token'] as String,
        channelId: roomId,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: role,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      _engine = engine;
    } catch (e) {
      debugPrint('Failed to join Agora channel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect to stream channel: $e')),
        );
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_engine == null || !_isHost) return;
    final newValue = !_isMuted;
    try {
      await _engine?.muteLocalAudioStream(newValue);
      if (mounted) setState(() => _isMuted = newValue);
    } catch (e) {
      if (mounted) setState(() => _isMuted = _isMuted);
      debugPrint('muteLocalAudioStream failed: $e');
    }
  }

  Future<void> _endLive() async {
    final roomId = _currentRoomId;
    if (roomId != null && _isHost) {
      await _sessionService.endLive(roomId);
    }
    await _leaveAndReleaseEngine();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _leaveAndReleaseEngine() async {
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } catch (e) {
        debugPrint('Engine release error: $e');
      }
    }
    if (mounted) {
      setState(() {
        _connected = false;
        _remoteHostUid = null;
      });
    }
  }

  Future<void> _handleToggleLike() async {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: 'like this live worship stream');
      return;
    }

    final roomId = _currentRoomId;
    if (roomId == null) return;

    await _sessionService.toggleLike(roomId: roomId, userId: authState.profile.id);
  }

  Future<void> _handleSendComment() async {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: 'comment on live room');
      return;
    }

    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final roomId = _currentRoomId;
    if (roomId == null) return;

    _chatController.clear();

    await _sessionService.addComment(
      roomId: roomId,
      authorId: authState.profile.id,
      authorName: authState.profile.name,
      text: text,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();

    if (_isHost && _isLive && _currentRoomId != null) {
      _sessionService.endLive(_currentRoomId!);
    }

    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProfile = ref.watch(mockAuthNotifierProvider).profile;
    final bool isLikedByMe = _likedUserIds.contains(authProfile.id);
    final String roomId = _currentRoomId ?? AgoraConfig.liveWorshipRoomId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        title: Row(
          children: [
            LiveBadge(label: _isLive ? 'AGORA LIVE' : 'ROOM'),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _hostName != null ? 'Live with $_hostName' : 'Sanctuary Worship Sanctuary',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isLikedByMe ? Icons.favorite : Icons.favorite_border,
              color: isLikedByMe ? Colors.redAccent : AppTheme.onSurfaceVariant,
            ),
            onPressed: _handleToggleLike,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                '${_likedUserIds.length}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Video / Audio Broadcast Viewport
          Container(
            height: 230,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              children: [
                // Video Stream View or Audio Visualizer Background
                if (_hasVideo && _engine != null) ...[
                  if (_isHost)
                    AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  else if (_remoteHostUid != null)
                    AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine!,
                        canvas: VideoCanvas(uid: _remoteHostUid),
                        connection: RtcConnection(channelId: roomId),
                      ),
                    )
                  else
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryContainer),
                          SizedBox(height: 12),
                          Text(
                            'Connecting Video Stream...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  // Audio Gradient representation
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF07120C), Color(0xFF00391E), Color(0xFF051D14)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isMuted ? Colors.redAccent : AppTheme.primaryContainer,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isMuted ? Colors.redAccent : AppTheme.primaryContainer)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.surfaceLow,
                            child: Icon(
                              _isMuted ? Icons.mic_off : Icons.mic,
                              color: _isMuted ? Colors.redAccent : AppTheme.primaryContainer,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _hostName != null ? '$_hostName Leading' : 'Live Host',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          _isLive
                              ? 'Live Audio Stream • Psalms & Intercession'
                              : 'Stream Offline',
                          style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],

                // Top Controls & Status Bar Overlay
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasVideo ? Icons.videocam : Icons.graphic_eq,
                              color: AppTheme.primaryContainer,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isLive
                                  ? (_hasVideo ? 'Live Video Stream' : 'Live Audio Stream')
                                  : 'Offline',
                              style: const TextStyle(fontSize: 11, color: AppTheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      if (_isHost)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleMute,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isMuted
                                      ? Colors.redAccent.withValues(alpha: 0.8)
                                      : Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isMuted ? Icons.mic_off : Icons.mic,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _endLive,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.call_end, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'End',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (!_isLive)
                        GestureDetector(
                          onTap: () => _startHostStream(withVideo: _hasVideo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: const Text(
                              'Go Live',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Firestore-Backed Live Comments Stream
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _sessionService.watchComments(roomId),
                    builder: (context, snapshot) {
                      final comments = snapshot.data?.docs ?? [];

                      return Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.forum_outlined, size: 16, color: AppTheme.primaryContainer),
                                    SizedBox(width: 6),
                                    Text(
                                      'Live Fellowship Chat',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${comments.length} Comments',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: comments.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No comments yet. Share an encouragement!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      itemCount: comments.length,
                                      itemBuilder: (context, index) {
                                        final d = comments[index].data();
                                        final authorName = d['authorName'] as String? ?? 'Believer';
                                        final authorId = d['authorId'] as String? ?? '';
                                        final text = d['text'] as String? ?? '';
                                        final isMe = authorId == authProfile.id;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: GlassCard(
                                            level: GlassLevel.level1,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            customSurfaceColor: isMe
                                                ? AppTheme.primaryContainer.withValues(alpha: 0.15)
                                                : AppTheme.surfaceLow.withValues(alpha: 0.6),
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '$authorName: ',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primaryContainer,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: text,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: isMe
                                                          ? AppTheme.primary
                                                          : AppTheme.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Quick Reaction Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['🙏 Amen!', '🔥 Hallelujah', '❤️ Praying', '📖 Glory'].map((reaction) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ActionChip(
                            backgroundColor: AppTheme.surfaceHigh,
                            label: Text(reaction, style: const TextStyle(fontSize: 12, color: AppTheme.onSurface)),
                            onPressed: () {
                              _chatController.text = reaction;
                              _handleSendComment();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Chat Input Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLowest,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                          ),
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                            onSubmitted: (_) => _handleSendComment(),
                            decoration: const InputDecoration(
                              hintText: 'Share a prayer or encouragement...',
                              hintStyle: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleSendComment,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: AppTheme.onPrimary, size: 18),
                        ),
                      ),
                    ],
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
