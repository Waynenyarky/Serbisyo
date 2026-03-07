import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

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

  String _friendlyAuthError(Object e, {required bool providerSignup}) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final server = data['error']?.toString();
        if (server != null && server.trim().isNotEmpty) {
          if (providerSignup &&
              server.toLowerCase() == 'email already registered') {
            return 'Email already registered. Log in first, then use "Become a host" in Profile.';
          }
          return server;
        }
      }
      final raw = e.error?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
      final message = e.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    final fallback = e.toString().replaceFirst('Exception:', '').trim();
    if (fallback.isNotEmpty) {
      if (providerSignup &&
          fallback.toLowerCase().contains('email already registered')) {
        return 'Email already registered. Log in first, then use "Become a host" in Profile.';
      }
      return fallback;
    }
    return 'Could not create account. Please try again.';
  }

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
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = widget.initialRole == 'provider' ? 'provider' : 'customer';
      await ref
          .read(apiRepositoryProvider)
          .register(email, password, fullName, role: role);
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      if (role == 'provider') {
        context.go('/provider/onboarding');
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyAuthError(
          e,
          providerSignup: widget.initialRole == 'provider',
        );
        if (_error != null && _error!.length > 160) {
          _error = '${_error!.substring(0, 160)}...';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProviderFlow = widget.initialRole == 'provider';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPad = screenWidth < 360 ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = constraints.maxHeight * 0.42;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: heroHeight,
                child: _SignUpVisualPanel(isProviderFlow: isProviderFlow),
              ),
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: heroHeight - 28,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        AppSpacing.lg,
                        horizontalPad,
                        AppSpacing.lg +
                            MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Join ${AppConstants.appName}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.35,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isProviderFlow
                                ? 'Create your premium host profile and start receiving bookings.'
                                : 'Create an account and book trusted services in minutes.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_error != null) ...[
                            _SignUpErrorBanner(message: _error!),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          TextField(
                            controller: _nameController,
                            decoration: _signUpInputDecoration(
                              context,
                              label: 'Full name',
                              hint: 'Juan Dela Cruz',
                              icon: Icons.person_outline_rounded,
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _emailController,
                            decoration: _signUpInputDecoration(
                              context,
                              label: 'Email',
                              hint: 'you@example.com',
                              icon: Icons.email_outlined,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _passwordController,
                            decoration:
                                _signUpInputDecoration(
                                  context,
                                  label: 'Create password',
                                  hint: 'At least 8 characters',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration:
                                _signUpInputDecoration(
                                  context,
                                  label: 'Confirm password',
                                  hint: 'Re-enter your password',
                                  icon: Icons.verified_user_outlined,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                ),
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: _loading ? null : _register,
                            icon: _loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    isProviderFlow
                                        ? Icons.storefront_rounded
                                        : Icons.person_add_alt_1_rounded,
                                  ),
                            label: Text(
                              _loading
                                  ? 'Creating account...'
                                  : 'Create account',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text(
                              'Already have an account? Log in',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

InputDecoration _signUpInputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.textTertiary),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: AppColors.primary, width: 1.7),
    ),
    labelStyle: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
  );
}

class _SignUpErrorBanner extends StatelessWidget {
  const _SignUpErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpVisualPanel extends StatelessWidget {
  const _SignUpVisualPanel({required this.isProviderFlow});

  final bool isProviderFlow;

  @override
  Widget build(BuildContext context) {
    final imageUrl = isProviderFlow
        ? 'https://images.unsplash.com/photo-1521791136064-7986c2920216?auto=format&fit=crop&w=1200&q=80'
        : 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=1200&q=80';
    final title = isProviderFlow
        ? 'Host premium services'
        : 'Book quality home services';
    final subtitle = isProviderFlow
        ? 'Show your expertise and grow your service business.'
        : 'Discover trusted providers with clear pricing and reviews.';
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              color: AppColors.primary.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.primary.withValues(alpha: 0.35),
            alignment: Alignment.center,
            child: Icon(
              isProviderFlow
                  ? Icons.workspace_premium_rounded
                  : Icons.home_repair_service_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.56),
                Colors.black.withValues(alpha: 0.12),
              ],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  isProviderFlow ? 'Host mode' : 'Customer mode',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
