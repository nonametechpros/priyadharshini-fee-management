import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<AppUser?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    final uid = credential.user!.uid;
    return fetchAppUser(uid);
  }

  Future<void> signOut() => _auth.signOut();

  /// Re-authenticates with the current password (Firebase requires a recent
  /// sign-in before allowing a password change) then sets the new one.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw StateError('Not signed in');
    final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Lets Admin trigger a reset for a staff member who forgot their password,
  /// without ever knowing or handling that staff member's credentials.
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<AppUser?> fetchAppUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Stream<AppUser?> watchAppUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(uid, doc.data()!);
    });
  }
}
