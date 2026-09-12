import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_model.dart';
import '../services/call_service.dart';
import 'auth_provider.dart';

final callServiceProvider = Provider<CallService>((ref) => CallService());

/// Live stream of any call where the current user is being called right
/// now (status still 'ringing'). HomeScreen watches this globally so the
/// Incoming Call screen can pop up no matter which tab the user is
/// currently looking at.
final incomingCallProvider = StreamProvider<CallModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);

  final callService = ref.watch(callServiceProvider);
  return callService.watchIncomingCalls(uid);
});

/// Live stream of every past call involving the current user, newest
/// first — powers the Call History screen.
final callHistoryProvider = StreamProvider<List<CallModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(<CallModel>[]);

  final callService = ref.watch(callServiceProvider);
  return callService.watchCallHistory(uid);
});