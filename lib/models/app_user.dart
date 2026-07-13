import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, staff }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.staff,
  );
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: userRoleFromString(data['role'] as String? ?? 'staff'),
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'active': active,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
