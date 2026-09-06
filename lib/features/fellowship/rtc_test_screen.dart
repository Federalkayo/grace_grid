import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RtcTestScreen extends StatefulWidget {
  const RtcTestScreen({super.key});
  @override
  State<RtcTestScreen> createState() => _RtcTestScreenState();
}

class _RtcTestScreenState extends State<RtcTestScreen> {
  RtcEngine? _engine;
  String _status = 'Not connected';
  int _remoteUsers = 0;
  bool _isJoining = false;

  static const _testChannel = 'gracegrid_test_room'; // same literal on both devices for this test

  Future<void> _joinTestChannel() async {
    if (_isJoining || _engine != null) return;
    setState(() {
      _isJoining = true;
      _status = 'Requesting token...';
    });
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('generateAgoraRtcToken')
          .call({'channelName': _testChannel});
      final data = result.data as Map;

      setState(() => _status = 'Creating engine...');
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: data['appId'] as String));

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _status = 'Joined channel ✅');
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUsers++);
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUsers = (_remoteUsers - 1).clamp(0, 999));
        },
        onError: (err, msg) {
          setState(() => _status = 'Error: $err $msg');
        },
      ));

      await engine.enableAudio();
      await engine.joinChannel(
        token: data['token'] as String,
        channelId: _testChannel,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine = engine;
    } catch (e) {
      setState(() {
        _status = 'Exception: $e';
        _isJoining = false;
      });
    }
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RTC plumbing test')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_status, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            Text('Other people in channel: $_remoteUsers'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isJoining ? null : _joinTestChannel,
              child: const Text('Join test channel'),
            ),
          ],
        ),
      ),
    );
  }
}
