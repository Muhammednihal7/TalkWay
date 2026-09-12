import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

/// The current logged-in user's full Firestore profile (name, photo, online
/// status) — this is the provider that was deliberately left unbuilt at the
/// end of Phase 3. It depends on authStateProvider (Firebase Auth) to know
/// WHO the current user is, then watches that user's Firestore document.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firebaseUser = authState.value;

  if (firebaseUser == null) {
    return Stream.value(null);
  }

  final userService = ref.watch(userServiceProvider);
  return userService.watchUser(firebaseUser.uid);
});

/// Live list of every other user, already sorted online-first by the
/// service layer. Contacts screen and Home screen's "recent contacts"
/// both read from this single stream.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firebaseUser = authState.value;

  if (firebaseUser == null) {
    return Stream.value(<UserModel>[]);
  }

  final userService = ref.watch(userServiceProvider);
  return userService.watchAllUsers(firebaseUser.uid);
});

/// Holds the current text typed into the Contacts search box.
/// A plain StateProvider is enough here — search text doesn't need the
/// loading/error handling that AsyncValue gives you.
final contactsSearchQueryProvider = StateProvider<String>((ref) => '');

/// The actual filtered list the Contacts screen renders — derived from
/// allUsersProvider + the search query. Because this is a `Provider` (not
/// a StateProvider), it recomputes automatically whenever either of its
/// two dependencies change, and nothing else needs to manually combine them.
final filteredContactsProvider = Provider<List<UserModel>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final query = ref.watch(contactsSearchQueryProvider);
  final userService = ref.watch(userServiceProvider);

  return usersAsync.when(
    data: (users) => userService.filterByName(users, query),
    loading: () => [],
    error: (_, __) => [],
  );
});
