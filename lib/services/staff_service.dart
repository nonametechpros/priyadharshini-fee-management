import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/app_user.dart';
import 'activity_log_service.dart';

/// Admin-only staff account management.
///
/// Creating a Firebase Auth user with the client SDK signs in as that new
/// user on the default app instance. To avoid kicking the Admin out of their
/// own session, the new account is created on a short-lived secondary
/// [FirebaseApp] and then immediately discarded.
class StaffService {
  StaffService({FirebaseFirestore? firestore, ActivityLogService? activityLogService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _activityLogService = activityLogService ?? ActivityLogService();

  final FirebaseFirestore _firestore;
  final ActivityLogService _activityLogService;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Stream<List<AppUser>> watchStaff() {
    return _users
        .where('role', isEqualTo: 'staff')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  Future<AppUser> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String createdByUid,
    required String createdByName,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'staffCreation_${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      final appUser = AppUser(
        uid: uid,
        name: name,
        email: email.trim(),
        role: UserRole.staff,
        active: true,
        createdAt: DateTime.now(),
      );
      // Written through the secondary app's Firestore instance (still
      // authenticated as the brand-new staff user) so the write satisfies
      // the security rule's self-create check (request.auth.uid == uid) --
      // the Admin's own auth context can never match the new staff uid.
      final secondaryFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);
      await secondaryFirestore.collection('users').doc(uid).set(appUser.toMap());
      await secondaryAuth.signOut();

      await _activityLogService.log(
        action: 'staff_created',
        entity: 'user',
        entityId: uid,
        performedBy: createdByUid,
        performedByName: createdByName,
        details: 'Created staff account for $name ($email)',
      );

      return appUser;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> setStaffActive({
    required String uid,
    required bool active,
    required String performedByUid,
    required String performedByName,
  }) async {
    await _users.doc(uid).update({'active': active});
    await _activityLogService.log(
      action: active ? 'staff_activated' : 'staff_deactivated',
      entity: 'user',
      entityId: uid,
      performedBy: performedByUid,
      performedByName: performedByName,
      details: active ? 'Staff account reactivated' : 'Staff account deactivated',
    );
  }

  Future<void> updateStaffName({required String uid, required String name}) async {
    await _users.doc(uid).update({'name': name});
  }
}
