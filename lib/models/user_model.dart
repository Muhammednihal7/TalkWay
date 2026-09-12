import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one user document stored at /users/{uid} in Firestore.
///
/// Why a model class instead of passing raw Maps around the app?
/// - Compile-time safety: `user.name` fails to compile if you typo it,
///   `map['nmae']` silently returns null at runtime.
/// - One place to change if a field is renamed or added.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final List<String> blockedUsers;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    this.blockedUsers = const [],
  });

  /// Builds a UserModel from a Firestore document snapshot.
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      blockedUsers: List<String>.from(map['blockedUsers'] as List? ?? []),
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.data() ?? {}, doc.id);
  }

  /// Converts this model back into a Map for writing to Firestore.
  /// `uid` is intentionally excluded — it's the document ID, not a field.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'blockedUsers': blockedUsers,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}
