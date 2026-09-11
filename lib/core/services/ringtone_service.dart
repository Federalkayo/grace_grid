import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Plays the incoming/outgoing call ringtone (looped) and, for incoming
/// calls, drives phone vibration alongside it — one shared instance so
/// starting a new ringtone always cleanly stops whatever was playing
/// before (e.g. if two call dialogs somehow raced).
///
/// Drop your own sound files in at:
///   assets/sounds/incoming-phone-ringtone.mp3
///   assets/sounds/outgoing-phone-ringtone.mp3
class RingtoneService {
  RingtoneService._internal();
  static final RingtoneService instance = RingtoneService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isVibrating = false;

  /// Ring + vibrate — for the callee, while a call is ringing.
  Future<void> playIncoming() => _play('sounds/incoming-phone-ringtone.mp3', vibrate: true);

  /// Ring only, no vibration — for the caller, while waiting for pickup.
  Future<void> playOutgoing() => _play('sounds/outgoing-phone-ringtone.mp3', vibrate: false);

  Future<void> _play(String assetPath, {required bool vibrate}) async {
    // Always stop whatever was ringing before starting the new one, so
    // switching between incoming/outgoing (or a rapid re-ring) never
    // stacks two loops on top of each other.
    await stop();
    _isPlaying = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('RingtoneService: failed to play $assetPath — $e');
    }

    if (vibrate) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          _isVibrating = true;
          // [wait, vibrate, wait, vibrate...] in ms; repeat:1 loops from
          // the second entry so it doesn't restart with a dead pause.
          Vibration.vibrate(pattern: [0, 800, 400, 800], repeat: 1);
        }
      } catch (e) {
        debugPrint('RingtoneService: vibration error — $e');
      }
    }
  }

  Future<void> stop() async {
    if (_isPlaying) {
      _isPlaying = false;
      try {
        await _player.stop();
      } catch (_) {}
    }
    if (_isVibrating) {
      _isVibrating = false;
      try {
        Vibration.cancel();
      } catch (_) {}
    }
  }
}
