import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/service_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/async_value_view.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AsyncValueView(
        value: appUserAsync,
        data: (context, appUser) {
          if (appUser == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Center(child: AppLogo(size: 72)),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appUser.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(appUser.email, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      Chip(label: Text(appUser.isAdmin ? 'Admin' : 'Staff')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: _ChangePasswordForm(),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChangePasswordForm extends ConsumerStatefulWidget {
  const _ChangePasswordForm();

  @override
  ConsumerState<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _formKey.currentState!.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'Current password is incorrect.'
          : 'Could not update password: ${e.message}');
    } catch (e) {
      setState(() => _errorText = 'Could not update password. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Change Password', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          TextFormField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm new password'),
            validator: (v) => (v != _newPasswordController.text) ? 'Passwords do not match' : null,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Update Password'),
          ),
        ],
      ),
    );
  }
}
