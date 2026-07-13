import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/async_value_view.dart';

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: AsyncValueView(
        value: staffAsync,
        data: (context, staff) {
          if (staff.isEmpty) {
            return const Center(child: Text('No staff accounts yet. Tap + to add one.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final member = staff[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')),
                  title: Text(member.name),
                  subtitle: Text(member.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Reset password',
                        icon: const Icon(Icons.lock_reset_outlined),
                        onPressed: () => _resetPassword(context, ref, member),
                      ),
                      Switch(
                        value: member.active,
                        onChanged: (value) => _toggleActive(context, ref, member, value),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-staff-fab',
        onPressed: () => _showAddStaffDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Staff'),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, AppUser member, bool active) async {
    final appUser = ref.read(currentAppUserProvider).valueOrNull;
    if (appUser == null) return;
    await ref.read(staffServiceProvider).setStaffActive(
          uid: member.uid,
          active: active,
          performedByUid: appUser.uid,
          performedByName: appUser.name,
        );
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref, AppUser member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset password?'),
        content: Text('Send a password reset email to ${member.name} (${member.email})?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(member.email);
      messenger.showSnackBar(SnackBar(content: Text('Password reset email sent to ${member.email}.')));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not send reset email. Please try again.')));
    }
  }

  Future<void> _showAddStaffDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _AddStaffDialog(),
    );
  }
}

class _AddStaffDialog extends ConsumerStatefulWidget {
  const _AddStaffDialog();

  @override
  ConsumerState<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends ConsumerState<_AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final appUser = ref.read(currentAppUserProvider).valueOrNull;
    if (appUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref.read(staffServiceProvider).createStaffAccount(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            createdByUid: appUser.uid,
            createdByName: appUser.name,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorText = 'Could not create the account. The email may already be in use.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Staff Account'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Temporary password'),
                validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}
