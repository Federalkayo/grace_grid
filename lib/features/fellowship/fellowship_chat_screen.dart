import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/agora_chat_provider.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../../core/services/agora_chat_service.dart';
import '../feed/providers/feed_provider.dart';
import 'voice_prayer_call_screen.dart';
import 'video_fellowship_call_screen.dart';

class FellowshipChatScreen extends ConsumerStatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerAvatar;

  const FellowshipChatScreen({
    super.key,
    this.partnerId = 'user_kaleb',
    this.partnerName = 'Pastor Kaleb',
    this.partnerAvatar = '',
  });

  @override
  ConsumerState<FellowshipChatScreen> createState() => _FellowshipChatScreenState();
}

class _FellowshipChatScreenState extends ConsumerState<FellowshipChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;

  String get _effectivePartnerId => widget.partnerId.isNotEmpty ? widget.partnerId : widget.partnerName;
  String get _effectivePartnerName => widget.partnerName.isNotEmpty ? widget.partnerName : widget.partnerId;

  @override
  void initState() {
    super.initState();
    _msgController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _msgController.text;
    if (text.isNotEmpty) {
      ref.read(fellowshipChatProvider(_effectivePartnerId).notifier).sendTypingSignal(true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(milliseconds: 1500), () {
        ref.read(fellowshipChatProvider(_effectivePartnerId).notifier).sendTypingSignal(false);
      });
    }
  }

  void _handleSend() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final authProfile = ref.read(mockAuthNotifierProvider).profile;
    _typingTimer?.cancel();
    ref.read(fellowshipChatProvider(_effectivePartnerId).notifier).sendMessage(
      text,
      senderId: authProfile.id,
      senderName: authProfile.name,
      recipientName: _effectivePartnerName,
    );
    _msgController.clear();
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
    _typingTimer?.cancel();
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _forwardMessage(BuildContext context, String content) {
    final conversations = ref.read(conversationsListProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forward Message To...',
              style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No active conversations to forward to.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: conversations.map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                      backgroundImage: getAvatarImageProvider(c.avatarUrl),
                      child: c.avatarUrl.isEmpty
                          ? Text(
                              c.partnerName.isNotEmpty ? c.partnerName[0].toUpperCase() : 'P',
                              style: const TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(c.partnerName, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
                    subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                    onTap: () {
                      ref.read(fellowshipChatProvider(c.id).notifier).sendMessage(content, isForwarded: true);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Forwarded to ${c.partnerName}'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.surfaceHigh,
                        ),
                      );
                    },
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context, AgoraChatMessageData msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('React to Message', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['❤️', '🙏', '👍', '🔥', '😂', '😮'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    ref.read(fellowshipChatProvider(_effectivePartnerId).notifier).toggleReaction(msg.id, emoji);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.emeraldStrokeAlpha15, height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.forward, color: AppTheme.primaryContainer),
              title: const Text('Forward Message', style: TextStyle(color: AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _forwardMessage(context, msg.content);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(fellowshipChatProvider(_effectivePartnerId).notifier).deleteMessage(msg.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(fellowshipChatProvider(_effectivePartnerId));
    final connStatus = ref.watch(agoraConnectionStatusProvider).value ?? AgoraConnectionStatus.demoMode;
    final authProfile = ref.watch(mockAuthNotifierProvider).profile;
    final conversations = ref.watch(conversationsListProvider);
    final feedState = ref.watch(feedProvider);

    String partnerAvatarUrl = widget.partnerAvatar;
    if (partnerAvatarUrl.isEmpty) {
      for (final c in conversations) {
        if (c.id == _effectivePartnerId || c.partnerName.toLowerCase() == _effectivePartnerName.toLowerCase()) {
          if (c.avatarUrl.isNotEmpty) {
            partnerAvatarUrl = c.avatarUrl;
            break;
          }
        }
      }
    }
    if (partnerAvatarUrl.isEmpty) {
      for (final p in feedState.posts) {
        if ((p.authorId == _effectivePartnerId || p.authorName.toLowerCase() == _effectivePartnerName.toLowerCase()) && (p.authorAvatar ?? '').isNotEmpty) {
          partnerAvatarUrl = p.authorAvatar!;
          break;
        }
      }
    }
    if (partnerAvatarUrl.isEmpty) {
      for (final s in feedState.stories) {
        if (s.userName.toLowerCase() == widget.partnerName.toLowerCase() && (s.userAvatar ?? '').isNotEmpty) {
          partnerAvatarUrl = s.userAvatar!;
          break;
        }
      }
    }

    final partnerAvatarImg = getAvatarImageProvider(partnerAvatarUrl);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
              backgroundImage: partnerAvatarImg,
              child: partnerAvatarImg == null
                  ? Text(
                      _effectivePartnerName.isNotEmpty ? _effectivePartnerName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _effectivePartnerName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          connStatus == AgoraConnectionStatus.connected
                              ? 'Agora Chat • Active'
                              : 'Agora Live Stream',
                          style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Audio Sanctum Call Button
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: AppTheme.primaryContainer),
            tooltip: 'Audio Sanctum Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VoicePrayerCallScreen(partnerName: _effectivePartnerName),
                ),
              );
            },
          ),
          // Video Call Button
          IconButton(
            icon: const Icon(Icons.videocam, color: AppTheme.secondary),
            tooltip: 'Video Fellowship Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoFellowshipCallScreen(partnerName: _effectivePartnerName),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Private Connection Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryContainer),
                SizedBox(width: 6),
                Text(
                  'Private 1:1 Fellowship Room • TLS Secured',
                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                final isMe = (msg.senderId.isNotEmpty && msg.senderId == authProfile.id) ||
                             (msg.senderName.isNotEmpty && msg.senderName.toLowerCase() == authProfile.name.toLowerCase()) ||
                             (msg.isMe && (msg.senderId == authProfile.id || msg.senderId == 'user_me'));

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onLongPress: () => _showMessageActions(context, msg, isMe),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GlassCard(
                            level: isMe ? GlassLevel.level2 : GlassLevel.level1,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            customSurfaceColor: isMe
                                ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                                : AppTheme.surfaceLow.withValues(alpha: 0.8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg.isForwarded)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.forward, size: 12, color: AppTheme.onSurfaceVariant),
                                        SizedBox(width: 4),
                                        Text(
                                          'Forwarded',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryContainer,
                                      ),
                                    ),
                                  ),
                                Text(
                                  msg.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMe ? AppTheme.primary : AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg.formattedTime,
                                      style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        (msg.isRead || msg.isDelivered) ? Icons.done_all : Icons.done,
                                        size: 15,
                                        color: msg.isRead
                                            ? AppTheme.primaryContainer
                                            : AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (msg.reactions.isNotEmpty)
                            Positioned(
                              bottom: -10,
                              right: isMe ? 8 : null,
                              left: isMe ? null : 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg.reactions.values.toSet().map((emoji) {
                                    final count = msg.reactions.values.where((e) => e == emoji).length;
                                    return count > 1 ? '$emoji $count' : emoji;
                                  }).join(' '),
                                  style: const TextStyle(fontSize: 12),
                                ),
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

          // Real-Time Typing Indicator Bubble
          if (chatState.isPartnerTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_effectivePartnerName is typing...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Chat Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLow,
              border: Border(top: BorderSide(color: AppTheme.emeraldStrokeAlpha15)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_book, color: AppTheme.primaryContainer, size: 20),
                  tooltip: 'Share Scripture Verse',
                  onPressed: () {
                    _msgController.text = 'Reflection: John 15:4 "Remain in me, and I in you."';
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: AppTheme.emeraldStrokeAlpha25),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
                      onSubmitted: (_) => _handleSend(),
                      decoration: const InputDecoration(
                        hintText: 'Send a prayer note...',
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSend,
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
          ),
        ],
      ),
    );
  }
}
