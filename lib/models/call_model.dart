import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether a call is audio-only or audio+video.
enum CallType { audio, video }

/// Lifecycle states a call can be in. This maps directly onto the
/// assignment's required "Call States": calling -> ringing -> connected ->
/// ended, plus rejected / missed / busy / failed.
enum CallStatus { calling, ringing, connected, ended, rejected, missed, busy, failed }

extension CallTypeX on CallType {
  String get value => name; // 'audio' | 'video'

  static CallType fromString(String value) {
    return CallType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallType.audio,
    );
  }
}

extension CallStatusX on CallStatus {
  String get value => name;

  static CallStatus fromString(String value) {
    return CallStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallStatus.ended,
    );
  }

  bool get isTerminal =>
      this == CallStatus.ended ||
      this == CallStatus.rejected ||
      this == CallStatus.missed ||
      this == CallStatus.busy ||
      this == CallStatus.failed;
}

/// Represents one call record — used both for the live "signaling" document
/// while a call is in progress AND, once ended, as a permanent row in
/// call history. Same shape, so no duplicate mapping logic.
class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String calleeId;
  final String calleeName;
  final String? calleePhotoUrl;
  final CallType type;
  final CallStatus status;
  final String? channelName; // Agora channel name for this call
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.calleeId,
    required this.calleeName,
    this.calleePhotoUrl,
    required this.type,
    required this.status,
    this.channelName,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
  });

  /// Call duration — only meaningful once connectedAt and endedAt are both set.
  Duration get duration {
    if (connectedAt == null || endedAt == null) return Duration.zero;
    return endedAt!.difference(connectedAt!);
  }

  bool get wasMissed => status == CallStatus.missed;
  bool get wasRejected => status == CallStatus.rejected;

  /// Given the current user's uid, returns the "other person" in the call —
  /// used by the Call History screen so it doesn't matter whether the
  /// current user was the caller or the callee.
  String otherPartyName(String currentUid) =>
      currentUid == callerId ? calleeName : callerName;

  String? otherPartyPhoto(String currentUid) =>
      currentUid == callerId ? calleePhotoUrl : callerPhotoUrl;

  bool wasOutgoing(String currentUid) => currentUid == callerId;

  factory CallModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CallModel(
      callId: documentId,
      callerId: map['callerId'] as String? ?? '',
      callerName: map['callerName'] as String? ?? '',
      callerPhotoUrl: map['callerPhotoUrl'] as String?,
      calleeId: map['calleeId'] as String? ?? '',
      calleeName: map['calleeName'] as String? ?? '',
      calleePhotoUrl: map['calleePhotoUrl'] as String?,
      type: CallTypeX.fromString(map['type'] as String? ?? 'audio'),
      status: CallStatusX.fromString(map['status'] as String? ?? 'ended'),
      channelName: map['channelName'] as String?,
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      connectedAt: (map['connectedAt'] as Timestamp?)?.toDate(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CallModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return CallModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleePhotoUrl': calleePhotoUrl,
      'type': type.value,
      'status': status.value,
      'channelName': channelName,
      'startedAt': Timestamp.fromDate(startedAt),
      'connectedAt': connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    };
  }

  CallModel copyWith({
    CallStatus? status,
    DateTime? connectedAt,
    DateTime? endedAt,
  }) {
    return CallModel(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      calleeId: calleeId,
      calleeName: calleeName,
      calleePhotoUrl: calleePhotoUrl,
      type: type,
      status: status ?? this.status,
      channelName: channelName,
      startedAt: startedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
