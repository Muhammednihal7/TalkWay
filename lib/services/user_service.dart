import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// All reads/writes to the /users collection that AREN'T part of the
/// login/register flow (that stays in AuthService) live here — fetching
/// the contact list, searching, editing a profile, presence updates.
class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Live stream of every user except the current one, ordered so online
  /// users float to the top (nice touch, not required, cheap to do since
  /// we're already sorting client-side).
  /// A StreamProvider watching this is what makes the Contacts screen
  /// update in real time when someone comes online — no pull-to-refresh
  /// needed anywhere in the app.
  Stream<List<UserModel>> watchAllUsers(String currentUid) {
    return _usersRef.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .where((user) => user.uid != currentUid)
          .toList();
      users.sort((a, b) {
        if (a.isOnline == b.isOnline) return a.name.compareTo(b.name);
        return a.isOnline ? -1 : 1; // online users first
      });
      return users;
    });
  }

  /// Live stream of a single user's profile — used to watch the current
  /// user's own profile (so Profile screen updates instantly after an edit)
  /// and to watch a specific contact's online status during a call.
  Stream<UserModel?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) updates['name'] = name.trim();
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isEmpty) return;
    await _usersRef.doc(uid).update(updates);
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    await _usersRef.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.now(),
    });
  }

  /// Simple client-side search by name (case-insensitive, "contains").
  /// Firestore doesn't support arbitrary substring queries natively, and
  /// this app's user count is small enough that filtering the already-
  /// fetched list client-side is simpler and cheaper than standing up
  /// something like Algolia for a contacts search box.
  List<UserModel> filterByName(List<UserModel> users, String query) {
    if (query.trim().isEmpty) return users;
    final lowerQuery = query.trim().toLowerCase();
    return users.where((u) => u.name.toLowerCase().contains(lowerQuery)).toList();
  }
}
