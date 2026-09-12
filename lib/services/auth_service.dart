import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// All direct communication with Firebase Auth + the Firestore /users
/// collection lives here. Screens and providers never call FirebaseAuth or
/// Firestore directly — they call this service. That's the "business logic
/// lives in services/" rule from the architecture.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of the current Firebase user — null when logged out.
  /// This is what Riverpod will listen to, to decide Splash -> Login vs Home.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Logs in with email + password.
  /// Throws a FirebaseAuthException on failure — the UI layer catches it
  /// and turns the error code into a human-readable message.
  Future<UserModel> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    await _setOnlineStatus(uid, true);
    return _fetchUserProfile(uid);
  }

  /// Creates a new Firebase Auth account AND a matching Firestore profile
  /// document. These are two separate systems (Auth handles credentials,
  /// Firestore holds app data) — this method keeps them in sync so the rest
  /// of the app only ever has to think about one "user."
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;

    // Keep the display name on the Auth record too, useful for push
    // notifications later and as a fallback if Firestore read ever fails.
    await credential.user!.updateDisplayName(name.trim());

    final newUser = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      isOnline: true,
      createdAt: DateTime.now(),
    );

    await _usersRef.doc(uid).set(newUser.toMap());
    return newUser;
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _setOnlineStatus(uid, false);
    }
    await _auth.signOut();
  }

  Future<UserModel> _fetchUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) {
      throw Exception(
        'No profile found for this account. It may have been created '
        'before the profile system, or the Firestore write failed at signup.',
      );
    }
    return UserModel.fromDocument(doc);
  }

  Future<void> _setOnlineStatus(String uid, bool isOnline) async {
    await _usersRef.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.now(),
    });
  }

  /// Converts Firebase's cryptic error codes into messages a user can
  /// actually understand. This is the "Error Handling" requirement in the
  /// assignment — never show 'FirebaseAuthException: [firebase_auth/...]'
  /// to a real user.
  static String readableError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak — use at least 6 characters.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
