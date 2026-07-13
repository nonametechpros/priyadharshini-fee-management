import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import 'service_providers.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The signed-in user's Firestore profile (role, active flag, etc). `null`
/// while signed out or if no profile document exists yet.
final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final firebaseUser = ref.watch(authStateChangesProvider).valueOrNull;
  if (firebaseUser == null) {
    return Stream<AppUser?>.value(null);
  }
  return ref.watch(authServiceProvider).watchAppUser(firebaseUser.uid);
});
