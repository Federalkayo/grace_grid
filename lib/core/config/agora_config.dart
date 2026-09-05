/// Agora Chat Configuration for GraceGrid
/// 
/// To connect to your Agora Chat project:
/// 1. Sign up/log in to [Agora Console](https://console.agora.io/).
/// 2. Create a project with **Agora Chat** enabled.
/// 3. Copy your **App Key** (formatted as `OrgName#AppName`, e.g., `411234567#gracegrid`)
///    and paste it below in [agoraAppKey].
class AgoraConfig {
  /// Replace this with your actual Agora App Key from Agora Console.
  /// Example: '411200000#1234567' or 'your_org#your_app'
  static const String agoraAppKey = '71200067891#200095442';

  /// Default Chat Room ID for the Live Worship Sanctuary Room.
  static const String liveWorshipRoomId = 'sanctuary_worship_room_1';

  /// Whether the Agora App Key is configured with custom credentials.
  static bool get isConfigured =>
      agoraAppKey.isNotEmpty &&
      agoraAppKey.contains('#') &&
      !agoraAppKey.contains('411000000#gracegrid');
}
