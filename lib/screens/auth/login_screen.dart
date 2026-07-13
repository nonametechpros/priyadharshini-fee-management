import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../widgets/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final user = await ref.read(authServiceProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (user != null && !user.active) {
        await ref.read(authServiceProvider).signOut();
        setState(() => _errorText = 'This account has been deactivated. Contact your Admin.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = '${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _errorText = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 96),
                      const SizedBox(height: 20),
                      Text(
                        'Priyadarsini Driving School',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fee Management',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
