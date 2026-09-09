import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/token_server_config.dart';

/// Fetches an Agora RTC token + App ID for [channelName] from the token
/// server (see token_server_config.dart for which backend is in use).
///
/// Requires the user to be signed in via Firebase Auth — the server
/// verifies the ID token before issuing a call token, same check the
/// original Cloud Function performed.
///
/// Returns a map shaped like: { token, appId, channelName, uid }
/// Throws an [Exception] with a descriptive message on any failure.
Future<Map<String, dynamic>> fetchAgoraRtcToken(String channelName) async {
  final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (idToken == null) {
    throw Exception('Not signed in — cannot request an Agora token.');
  }

  final response = await http.post(
    Uri.parse(kAgoraTokenServerUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({'channelName': channelName}),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to get Agora token (${response.statusCode}): ${response.body}',
    );
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}
