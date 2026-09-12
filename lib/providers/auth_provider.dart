import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// A single shared instance of AuthService, available to any provider or
/// widget via `ref.watch(authServiceProvider)`. This is the ONLY place
/// `AuthService()` gets constructed in the whole app.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Live stream of Firebase's auth state (logged in / logged out).
/// Splash screen watches this to decide where to send the user.
/// Riverpod's StreamProvider automatically rebuilds any listening widget
/// the instant this stream emits a new value — no manual setState needed.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Holds the result of a login/register action: idle, loading, or error.
/// AsyncValue is Riverpod's built-in "this could be loading/data/error"
/// wrapper, so the UI can do `state.isLoading` / `state.hasError` directly
/// instead of you hand-rolling three boolean flags.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.data(null));

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authService.login(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(AuthService.readableError(e), st);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.register(name: name, email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(AuthService.readableError(e), st);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});

// NOTE: a `currentUserProvider` that exposes the full Firestore UserModel
// (name, photo, online status) is added in Phase 4 alongside UserService —
// it needs a Firestore read method that doesn't exist yet. Deliberately not
// stubbing it here with fake logic.
