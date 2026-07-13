import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/service_providers.dart';
import '../../widgets/app_logo.dart';
import '../shell/admin_shell.dart';
import '../shell/staff_shell.dart';
import 'login_screen.dart';

/// Root widget: routes between the login screen, a blocked-access screen,
/// and the Admin/Staff shell based on Firebase auth state and the signed-in
/// user's Firestore role/active flag.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => _ErrorScreen(message: '$error'),
      data: (firebaseUser) {
        if (firebaseUser == null) return const LoginScreen();

        final appUserAsync = ref.watch(currentAppUserProvider);
        return appUserAsync.when(
          loading: () => const _SplashScreen(),
          error: (error, stackTrace) => _ErrorScreen(message: '$error'),
          data: (appUser) {
            if (appUser == null) {
              return const _BlockedScreen(
                message: 'No profile was found for this account. Contact your Admin.',
              );
            }
            if (!appUser.active) {
              return const _BlockedScreen(
                message: 'This account has been deactivated. Contact your Admin.',
              );
            }
            return appUser.isAdmin ? const AdminShell() : const StaffShell();
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 80),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Something went wrong: $message', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _BlockedScreen extends ConsumerWidget {
  const _BlockedScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 72),
              const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
