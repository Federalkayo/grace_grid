import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/data/mock_community_data.dart';
import 'voice_prayer_call_screen.dart';
import 'video_fellowship_call_screen.dart';

class FellowshipChatScreen extends StatefulWidget {
  final String partnerName;

  const FellowshipChatScreen({
    super.key,
    this.partnerName = 'Pastor Kaleb',
  });

  @override
  State<FellowshipChatScreen> createState() => _FellowshipChatScreenState();
}

class _FellowshipChatScreenState extends State<FellowshipChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(MockCommunityData.mockChatMessages);
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'You',
          text: _msgController.text.trim(),
          timestamp: 'Just now',
          isMe: true,
        ),
      );
      _msgController.clear();
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text(
                widget.partnerName[0],
                style: const TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partnerName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.primaryContainer, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Active in Sanctuary', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ],
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
                  builder: (context) => VoicePrayerCallScreen(partnerName: widget.partnerName),
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
                  builder: (context) => VideoFellowshipCallScreen(partnerName: widget.partnerName),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Encrypted Prayer Focus Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryContainer),
                SizedBox(width: 6),
                Text(
                  'Encrypted 1:1 Fellowship & Intercession Room',
                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      level: msg.isMe ? GlassLevel.level2 : GlassLevel.level1,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      customSurfaceColor: msg.isMe
                          ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                          : AppTheme.surfaceLow.withValues(alpha: 0.8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: msg.isMe ? AppTheme.primary : AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              msg.timestamp,
                              style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
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
                      decoration: const InputDecoration(
                        hintText: 'Send encrypted prayer note...',
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
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
