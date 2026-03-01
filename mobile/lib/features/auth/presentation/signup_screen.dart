import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    setState(() => _error = null);
    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Fill all fields');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = 'Password and Confirm password do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final role = widget.initialRole == 'provider' ? 'provider' : 'customer';
      await ref.read(apiRepositoryProvider).register(email, password, fullName, role: role);
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      if (role == 'provider') {
        context.go('/provider/onboarding');
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _loading = false;
        _error = msg.replaceFirst('DioException [bad response]:', '').replaceFirst('DioException [connection error]:', '').trim();
        if (_error != null && _error!.length > 120) _error = '${_error!.substring(0, 120)}...';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Join ${AppConstants.appName}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                widget.initialRole == 'provider'
                    ? 'Offer your services and get booked by customers.'
                    : 'Book home services with trusted providers.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error)),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name', hintText: 'Juan Dela Cruz'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Create Password',
                  hintText: 'At least 8 characters',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: () => context.pop(), child: const Text('Already have an account? Log in')),
            ],
          ),
        ),
      ),
    );
  }
}
