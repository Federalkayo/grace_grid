import 'package:cloud_firestore/cloud_firestore.dart';

enum CallStatus { none, ringing, accepted, declined, ended }

class CallSignalingService {
  CollectionReference<Map<String, dynamic>> get _callsRef =>
      FirebaseFirestore.instance.collection('calls');

  Future<void> startCall({
    required String chatId,
    required String callerId,
    required String calleeId,
  }) async {
    await _callsRef.doc(chatId).set({
      'callerId': callerId,
      'calleeId': calleeId,
      'status': 'ringing',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String chatId, CallStatus status) async {
    await _callsRef.doc(chatId).update({'status': status.name});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCall(String chatId) {
    return _callsRef.doc(chatId).snapshots();
  }

  Future<void> endCall(String chatId) async {
    await _callsRef.doc(chatId).update({'status': 'ended'});
  }
}
