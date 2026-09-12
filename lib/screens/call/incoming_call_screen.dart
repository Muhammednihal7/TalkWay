import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../providers/call_provider.dart';
import '../call/call_screen.dart';

/// Shown to the CALLEE the moment someone calls them — pushed
/// automatically by the global incoming-call listener on HomeScreen, not
/// something the user navigates to themselves. Matches the PDF's
/// "Incoming Call Screen" spec: caller name/photo, call type, Decline
/// (red) / Accept (green).
class IncomingCallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  bool _responded = false;

  @override
  void initState() {
    super.initState();
    // If the caller gave up waiting (their own ringingTimeout fired and
    // marked this call 'missed'), this screen should dismiss itself
    // instead of sitting there ringing forever with a dead call record.
    final callService = ref.read(callServiceProvider);
    callService.watchCall(widget.call.callId).listen((updated) {
      if (!mounted || _responded || updated == null) return;
      if (updated.status == CallStatus.missed || updated.status == CallStatus.ended) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _accept() async {
    if (_responded) return;
    _responded = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(call: widget.call, isCaller: false),
      ),
    );
  }

  Future<void> _decline() async {
    if (_responded) return;
    _responded = true;
    final callService = ref.read(callServiceProvider);
    await callService.markRejected(widget.call.callId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.call.type == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),
            Column(
              children: [
                Text(
                  isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  child: Text(
                    widget.call.callerName.isNotEmpty
                        ? widget.call.callerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.call.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'decline',
                        backgroundColor: AppColors.callDecline,
                        onPressed: _decline,
                        child: const Icon(Icons.call_end),
                      ),
                      const SizedBox(height: 8),
                      const Text('Decline', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'accept',
                        backgroundColor: AppColors.callAccept,
                        onPressed: _accept,
                        child: Icon(isVideo ? Icons.videocam : Icons.call),
                      ),
                      const SizedBox(height: 8),
                      const Text('Accept', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}