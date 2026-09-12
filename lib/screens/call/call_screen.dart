import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../models/call_model.dart';
import '../../providers/call_provider.dart';
import '../../services/agora_service.dart';

/// The real Audio/Video call screen — replaces the earlier hardcoded test
/// version. Takes a CallModel (already created in Firestore by whoever
/// initiated the call) instead of a raw channel name, and keeps that
/// Firestore record in sync with what's actually happening on the Agora
/// side (connected, ended, missed).
class CallScreen extends ConsumerStatefulWidget {
  final CallModel call;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.call,
    required this.isCaller,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final AgoraService _agoraService = AgoraService();

  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOn = true;
  String? _errorMessage;
  String? _statusOverride; // e.g. "Call declined", "Call ended by other user"

  int? _remoteUid;
  bool _hasEnded = false; // guards against double-ending the call

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _listenForRemoteCallEnd();

    // If we're the caller and nobody answers within the timeout, mark
    // the call as missed instead of leaving it "ringing" forever.
    if (widget.isCaller) {
      Future.delayed(AppConstants.ringingTimeout, () {
        if (!mounted || _remoteUid != null) return;
        _endCall(markAs: CallStatus.missed);
      });
    }
  }

  /// Watches the Firestore call record for changes made from the OTHER
  /// device — e.g. the callee tapping Decline. Without this, only local
  /// Agora events could end the call, so a rejection before the callee
  /// ever opens Agora at all would leave the caller stuck.
  void _listenForRemoteCallEnd() {
    final callService = ref.read(callServiceProvider);
    callService.watchCall(widget.call.callId).listen((updatedCall) {
      if (!mounted || _hasEnded || updatedCall == null) return;
      if (updatedCall.status == CallStatus.rejected) {
        _hasEnded = true;
        setState(() => _statusOverride = 'Call declined');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else if (updatedCall.status == CallStatus.ended && _isJoined) {
        _hasEnded = true;
        setState(() => _statusOverride = 'Call ended');
        _agoraService.leaveChannel();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  Future<void> _initializeAgora() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Microphone permission is required to make a call.');
      return;
    }

    if (widget.call.type == CallType.video) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Camera permission is required for a video call.');
        return;
      }
    }

    try {
      await _agoraService.initialize(
        eventHandler: RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) async {
            if (!mounted) return;
            setState(() => _isJoined = true);
            try {
              await _agoraService.engine.setEnableSpeakerphone(_isSpeakerOn);
            } catch (_) {}
          },
          onUserJoined: (connection, remoteUid, elapsed) async {
            if (!mounted) return;
            setState(() => _remoteUid = remoteUid);
            // The moment the other person's audio/video actually joins is
            // the true "connected" moment — this is what call duration
            // and call history should be based on, not just this device
            // opening the app.
            final callService = ref.read(callServiceProvider);
            await callService.markConnected(widget.call.callId);
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted) return;
            setState(() {
              if (_remoteUid == remoteUid) _remoteUid = null;
            });
          },
          onError: (err, msg) {
            if (!mounted) return;
            setState(() => _errorMessage = 'Call error: $err ${msg.isNotEmpty ? '- $msg' : ''}');
          },
          // Detects real network drops mid-call — required by the
          // assignment's "Disconnected" call state and error-handling
          // section. Without this, a dropped connection just leaves the
          // screen frozen with no feedback at all.
          onConnectionStateChanged: (connection, state, reason) {
            if (!mounted) return;
            if (state == ConnectionStateType.connectionStateFailed ||
                state == ConnectionStateType.connectionStateDisconnected) {
              setState(() => _statusOverride = 'Connection lost — check your internet');
            } else if (state == ConnectionStateType.connectionStateConnected) {
              // Clear any stale "connection lost" message on recovery.
              if (_statusOverride == 'Connection lost — check your internet') {
                setState(() => _statusOverride = null);
              }
            }
          },
        ),
      );

      if (widget.call.type == CallType.video) {
        await _agoraService.engine.enableVideo();
      }

      await _agoraService.joinChannel(
        channelName: widget.call.channelName!,
        // uid: 0 tells Agora to auto-assign a unique numeric ID server-side
        // — this removes the need to manually coordinate UIDs between two
        // strangers' devices, which isn't something a real app can do.
        uid: 0,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not start the call: $e');
      // Critical: without this, a crashed/failed call stays stuck at
      // 'ringing' in Firestore forever, and can resurface as a phantom
      // incoming call later. Always close out the record on failure.
      if (!_hasEnded) {
        _hasEnded = true;
        final callService = ref.read(callServiceProvider);
        await callService.markEnded(widget.call.callId);
      }
    }
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _agoraService.engine.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    try {
      await _agoraService.engine.setEnableSpeakerphone(_isSpeakerOn);
    } catch (_) {}
  }

  Future<void> _toggleCamera() async {
    setState(() => _isCameraOn = !_isCameraOn);
    await _agoraService.engine.enableLocalVideo(_isCameraOn);
  }

  Future<void> _switchCamera() async {
    await _agoraService.engine.switchCamera();
  }

  Future<void> _endCall({CallStatus markAs = CallStatus.ended}) async {
    if (_hasEnded) return;
    _hasEnded = true;

    final callService = ref.read(callServiceProvider);
    if (markAs == CallStatus.missed) {
      await callService.markMissed(widget.call.callId);
    } else {
      await callService.markEnded(widget.call.callId);
    }

    await _agoraService.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _agoraService.dispose();
    super.dispose();
  }

  String get _otherPersonName =>
      widget.isCaller ? widget.call.calleeName : widget.call.callerName;

  bool get _isVideoCall => widget.call.type == CallType.video;

  /// Full-screen remote video feed — only rendered once we actually have
  /// a remoteUid to attach to. Before that, video calls fall back to the
  /// same name/status layout as audio calls.
  Widget _buildRemoteVideo() {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _agoraService.engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: widget.call.channelName!),
      ),
    );
  }

  /// Small local camera preview, anchored top-right like every standard
  /// video-calling app — matches the PDF's "Local camera preview" spec.
  Widget _buildLocalPreview() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _agoraService.engine,
        canvas: const VideoCanvas(uid: 0), // 0 = local user
      ),
    );
  }

  Widget _buildStatusText() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      );
    }
    if (_statusOverride != null) {
      return Text(
        _statusOverride!,
        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
      );
    }
    return Text(
      _remoteUid == null ? 'Ringing...' : 'Connected',
      style: const TextStyle(fontSize: 16, color: Colors.white70),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _toggleMute,
          icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
          iconSize: 30,
        ),
        const SizedBox(width: 20),
        if (_isVideoCall) ...[
          IconButton(
            onPressed: _toggleCamera,
            icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off, color: Colors.white),
            iconSize: 30,
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            iconSize: 30,
          ),
          const SizedBox(width: 20),
        ] else ...[
          IconButton(
            onPressed: _toggleSpeaker,
            icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.volume_off, color: Colors.white),
            iconSize: 30,
          ),
          const SizedBox(width: 20),
        ],
        FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: () => _endCall(),
          child: const Icon(Icons.call_end),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Video call, connected: full video layout with remote feed + local
    // preview + floating controls at the bottom.
    if (_isVideoCall && _isJoined && _remoteUid != null && _errorMessage == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildRemoteVideo()),
            Positioned(
              top: 16,
              right: 16,
              child: SizedBox(
                width: 110,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isCameraOn
                      ? _buildLocalPreview()
                      : Container(color: Colors.grey.shade900),
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
          ],
        ),
      );
    }

    // Audio call, OR video call before the remote side has joined yet:
    // same simple name/status layout, with local preview shown early for
    // video calls so the user can see themselves while waiting.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isVideoCall && _isJoined && _isCameraOn && _errorMessage == null)
              Positioned.fill(child: _buildLocalPreview()),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isVideoCall || !_isJoined) ...[
                  const Icon(Icons.person, size: 100, color: Colors.white54),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 300), // push text below the preview
                Text(
                  _otherPersonName,
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatusText(),
                const SizedBox(height: 60),
                _buildControls(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}