import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/call_provider.dart';
import '../call/incoming_call_screen.dart';
import '../contacts/contacts_screen.dart';
import '../history/call_history_screen.dart';
import '../profile/profile_screen.dart';
import 'home_tab.dart';

/// The app's main shell after login: bottom navigation switching between
/// Home / Contacts / Calls / Profile — AND a global listener for incoming
/// calls, so the Incoming Call screen pops up no matter which tab is
/// currently open. This is why the listener lives here rather than on
/// any individual tab screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Tracks the callId we've already pushed a screen for, so a rebuild
  // (or the same 'ringing' call still being in Firestore) doesn't push
  // Incoming Call screen on top of itself repeatedly.
  String? _handledCallId;

  static const _tabs = [
    HomeTab(),
    ContactsScreen(),
    CallHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ref.listen runs a side effect (navigation) without rebuilding this
    // widget's own UI on every incoming-call stream tick — exactly what
    // we want, since we only want to act the moment a NEW call appears.
    ref.listen(incomingCallProvider, (previous, next) {
      final call = next.value;
      if (call == null) {
        // No ringing call (anymore) — reset so a future new call can
        // still trigger the listener.
        _handledCallId = null;
        return;
      }
      if (_handledCallId == call.callId) return; // already showing this one
      _handledCallId = call.callId;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(call: call),
          fullscreenDialog: true,
        ),
      );
    });

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.call_outlined), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}