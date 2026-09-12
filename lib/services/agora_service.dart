import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_token_generator/agora_token_generator.dart';

/// NOTE: appId and appCertificate are hardcoded here for local
/// development/assignment purposes only. Generating tokens on the CLIENT
/// using the App Certificate is NOT how a real production app should
/// work — the certificate is a secret, and embedding it in the APK means
/// anyone who decompiles the app can forge tokens for your project. A
/// real app generates tokens on a trusted server instead.
///
/// This is a deliberate, documented tradeoff for this assignment: it
/// avoids needing to stand up and host a separate backend service just
/// to hand out tokens, while still using real per-channel token
/// authentication instead of leaving the project wide open. Flag this
/// explicitly in the README's "Known limitations" section.
class AgoraService {
  static const String appId = '355ee9a6d31945ae860f8abc3aea511a';

  // Get this from the Agora console: Projects > (your project) >
  // Security > click the copy icon under "Primary Certificate".
  static const String appCertificate = 'YOUR_AGORA_APP_CERTIFICATE';

  late final RtcEngine _engine;

  RtcEngine get engine => _engine;

  Future<void> initialize({
    required RtcEngineEventHandler eventHandler,
  }) async {
    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine.registerEventHandler(eventHandler);

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await _engine.enableAudio();
    await _engine.enableLocalAudio(true);
    await _engine.muteLocalAudioStream(false);
  }

  /// Builds a fresh token scoped to this exact channel + uid, valid for
  /// 1 hour — generated locally instead of pulled from the console. This
  /// is what makes dynamic, per-call channel names actually work, since
  /// a console-generated temp token can only ever cover one fixed
  /// channel name.
  String _generateToken({required String channelName, required int uid}) {
    return RtcTokenBuilder.buildTokenWithUid(
      appId: appId,
      appCertificate: appCertificate,
      channelName: channelName,
      uid: uid,
      tokenExpireSeconds: 3600,
    );
  }

  Future<void> joinChannel({
    required String channelName,
    required int uid,
  }) async {
    final token = _generateToken(channelName: channelName, uid: uid);

    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        publishCameraTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        enableAudioRecordingOrPlayout: true,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
  }

  Future<void> dispose() async {
    await _engine.release();
  }
}