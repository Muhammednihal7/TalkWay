import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/call_model.dart';

/// Owns the Firestore /calls collection: creating a call record when
/// someone taps "call," updating its status as it moves through
/// calling -> ringing -> connected -> ended, and providing the live
/// streams that both CallScreen and an "incoming call" listener watch.
///
/// This is deliberately separate from AgoraService: AgoraService only
/// knows about the live audio/video stream itself. CallService only
/// knows about the call's METADATA (who, when, status). CallScreen uses
/// both together but neither depends on the other directly.
class CallService {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  CallService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _callsRef =>
      _firestore.collection(AppConstants.callsCollection);

  /// Creates a new call record and returns it. Called the moment someone
  /// taps the audio/video call button on a contact. The channel name is
  /// a fresh UUID every time — this is what lets two different pairs of
  /// users call each other simultaneously without colliding on the same
  /// Agora channel.
  Future<CallModel> startCall({
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String calleeId,
    required String calleeName,
    String? calleePhotoUrl,
    required CallType type,
  }) async {
    final channelName = 'call_${_uuid.v4()}';
    final docRef = _callsRef.doc();

    final call = CallModel(
      callId: docRef.id,
      callerId: callerId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      calleeId: calleeId,
      calleeName: calleeName,
      calleePhotoUrl: calleePhotoUrl,
      type: type,
      status: CallStatus.ringing,
      channelName: channelName,
      startedAt: DateTime.now(),
    );

    await docRef.set(call.toMap());
    return call;
  }

  /// Live stream of a single call's record — CallScreen watches this to
  /// know if the OTHER person rejected or ended the call from their side,
  /// so this device can react (e.g. show "Call declined" and go back)
  /// even if the local Agora engine hasn't reported anything yet.
  Stream<CallModel?> watchCall(String callId) {
    return _callsRef.doc(callId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CallModel.fromDocument(doc);
    });
  }

  /// Live stream of any call where the current user is the CALLEE and the
  /// status is still 'ringing' — this is what powers the Incoming Call
  /// screen. A global listener (added in the next phase) watches this
  /// and pushes the Incoming Call screen the moment a new one appears.
  Stream<CallModel?> watchIncomingCalls(String currentUid) {
    return _callsRef
        .where('calleeId', isEqualTo: currentUid)
        .where('status', isEqualTo: CallStatus.ringing.value)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final docs = snapshot.docs.toList()
        ..sort((a, b) => (b.data()['startedAt'] as Timestamp)
            .compareTo(a.data()['startedAt'] as Timestamp));
      final mostRecent = CallModel.fromDocument(docs.first);

      // Ignore anything older than the ringing timeout — a call that's
      // been sitting at "ringing" for longer than that was never
      // properly cleaned up (e.g. the app crashed mid-call during
      // testing) and should not resurrect itself as a new incoming call.
      final age = DateTime.now().difference(mostRecent.startedAt);
      if (age > AppConstants.ringingTimeout) return null;

      return mostRecent;
    });
  }

  Future<void> markConnected(String callId) async {
    await _callsRef.doc(callId).update({
      'status': CallStatus.connected.value,
      'connectedAt': Timestamp.now(),
    });
  }

  Future<void> markEnded(String callId) async {
    await _callsRef.doc(callId).update({
      'status': CallStatus.ended.value,
      'endedAt': Timestamp.now(),
    });
  }

  Future<void> markRejected(String callId) async {
    await _callsRef.doc(callId).update({
      'status': CallStatus.rejected.value,
      'endedAt': Timestamp.now(),
    });
  }

  Future<void> markMissed(String callId) async {
    await _callsRef.doc(callId).update({
      'status': CallStatus.missed.value,
      'endedAt': Timestamp.now(),
    });
  }

  /// Live stream of every call involving the current user (as caller OR
  /// callee), newest first — this is what the Call History screen
  /// (Phase 7) will read from. Building the query now since the
  /// underlying data is being created in this phase anyway.
  Stream<List<CallModel>> watchCallHistory(String currentUid) {
    final asCallerStream = _callsRef
        .where('callerId', isEqualTo: currentUid)
        .snapshots()
        .map((s) => s.docs.map((d) => CallModel.fromDocument(d)).toList());
    final asCalleeStream = _callsRef
        .where('calleeId', isEqualTo: currentUid)
        .snapshots()
        .map((s) => s.docs.map((d) => CallModel.fromDocument(d)).toList());

    // Combine both streams into one merged, sorted list. Firestore can't
    // do an "OR" query across two different fields in one call, so this
    // merges them client-side — fine at this app's scale.
    return asCallerStream.asyncMap((callerCalls) async {
      final calleeCalls = await asCalleeStream.first;
      final all = [...callerCalls, ...calleeCalls];
      // De-duplicate in case a call somehow appears in both (shouldn't).
      final unique = {for (final c in all) c.callId: c}.values.toList();
      unique.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return unique;
    });
  }
}