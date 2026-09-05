import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sanctuary_chips_badges.dart';
import '../../core/providers/mock_auth_provider.dart';
import '../../core/providers/agora_chat_provider.dart';
import '../../core/config/agora_config.dart';
import '../auth/login_signup_modal.dart';

class LiveFellowshipWorshipRoomScreen extends ConsumerStatefulWidget {
  const LiveFellowshipWorshipRoomScreen({super.key});

  @override
  ConsumerState<LiveFellowshipWorshipRoomScreen> createState() => _LiveFellowshipWorshipRoomScreenState();
}

class _LiveFellowshipWorshipRoomScreenState extends ConsumerState<LiveFellowshipWorshipRoomScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSendLiveMessage() {
    final authState = ref.read(mockAuthNotifierProvider);
    if (authState.isGuest) {
      LoginSignupModal.show(context, gatedActionTitle: 'chat in Live Room');
      return;
    }

    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(liveRoomChatProvider(AgoraConfig.liveWorshipRoomId).notifier)
        .sendRoomMessage(text);

    _chatController.clear();
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
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(liveRoomChatProvider(AgoraConfig.liveWorshipRoomId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLow,
        elevation: 0,
        title: const Row(
          children: [
            LiveBadge(label: 'AGORA LIVE ROOM'),
            SizedBox(width: 10),
            Text(
              'Evening Psalm Chant',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighest,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Row(
              children: [
                Icon(Icons.people, size: 14, color: AppTheme.primaryContainer),
                SizedBox(width: 4),
                Text('142', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Video Stream Viewport Mockup
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              children: [
                // Background Gradient Representation
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF07120C), Color(0xFF00391E), Color(0xFF051D14)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Video/Speaker Center Avatar
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryContainer, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.surfaceLow,
                          child: Icon(Icons.mic, color: AppTheme.primaryContainer, size: 36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pastor Kaleb Leading',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const Text(
                        'Live Broadcast • Psalm 91 Chants',
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // Top Overlay Controls
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.graphic_eq, color: AppTheme.primaryContainer, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Agora Live Audio',
                          style: TextStyle(fontSize: 11, color: AppTheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Live Chat Stream Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.forum_outlined, size: 16, color: AppTheme.primaryContainer),
                          SizedBox(width: 6),
                          Text(
                            'Agora Live Room Chat',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${chatMessages.length} Messages',
                        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = chatMessages[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GlassCard(
                            level: GlassLevel.level1,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            customSurfaceColor: msg.isMe
                                ? AppTheme.primaryContainer.withValues(alpha: 0.15)
                                : AppTheme.surfaceLow.withValues(alpha: 0.6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${msg.senderName}: ',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryContainer,
                                          ),
                                        ),
                                        TextSpan(
                                          text: msg.content,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: msg.isMe ? AppTheme.primary : AppTheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  msg.formattedTime,
                                  style: const TextStyle(fontSize: 9, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
                              _handleSendLiveMessage();
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
                            onSubmitted: (_) => _handleSendLiveMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Send a prayer via Agora Chat...',
                              hintStyle: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleSendLiveMessage,
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
