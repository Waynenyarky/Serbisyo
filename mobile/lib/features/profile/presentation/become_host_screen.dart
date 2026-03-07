import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class BecomeHostScreen extends ConsumerStatefulWidget {
  const BecomeHostScreen({super.key});

  @override
  ConsumerState<BecomeHostScreen> createState() => _BecomeHostScreenState();
}

class _BecomeHostScreenState extends ConsumerState<BecomeHostScreen> {
  int _step = 0; // 0: overview, 1: confirm, 2: success
  bool _submitting = false;
  String? _error;

  String get _appBarTitle {
    if (_step == 1) return 'Confirm host setup';
    if (_step == 2) return 'Host mode ready';
    return 'Become a host';
  }

  Future<bool> _onWillPop() async {
    if (_submitting) return false;
    if (_step == 1) {
      setState(() => _step = 0);
      return false;
    }
    if (_step == 2) {
      if (!mounted) return false;
      context.go('/profile');
      return false;
    }
    return true;
  }

  Future<void> _onLeadingBackPressed() async {
    final shouldPop = await _onWillPop();
    if (!mounted || !shouldPop) return;
    context.pop();
  }

  Future<void> _confirmUpgrade() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(apiRepositoryProvider).becomeProvider();
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      ref.invalidate(providerStatusProvider);
      setState(() => _step = 2);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildStepBody() {
    if (_step == 0) {
      return const _StepScrollable(
        key: ValueKey('step-overview'),
        child: _OverviewStep(),
      );
    }
    if (_step == 1) {
      return const _StepScrollable(
        key: ValueKey('step-confirm'),
        child: _ConfirmStep(),
      );
    }
    return const _StepScrollable(
      key: ValueKey('step-success'),
      child: _SuccessStep(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0 && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_appBarTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _onLeadingBackPressed,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepHeader(step: _step),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildStepBody(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoFooter(step: _step),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _BottomActions(
                  step: _step,
                  submitting: _submitting,
                  onContinue: () => setState(() => _step = 1),
                  onBackStep: () => setState(() => _step = 0),
                  onConfirm: _confirmUpgrade,
                  onGoHostDashboard: () => context.go('/favorites'),
                  onCompleteOnboarding: () => context.go('/provider/onboarding'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _dot(active: true),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 2,
                color: step > 0 ? AppColors.primary : AppColors.divider,
              ),
            ),
            _dot(active: step > 0),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 2,
                color: step > 1 ? AppColors.primary : AppColors.divider,
              ),
            ),
            _dot(active: step > 1),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _label(context, text: 'Overview', active: step == 0)),
            Expanded(child: _label(context, text: 'Confirm', active: step == 1)),
            Expanded(child: _label(context, text: 'Ready', active: step == 2)),
          ],
        ),
      ],
    );
  }

  Widget _dot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.divider,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _label(BuildContext context, {required String text, required bool active}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: active ? AppColors.primary : AppColors.textTertiary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          ),
    );
  }
}

class _StepScrollable extends StatelessWidget {
  const _StepScrollable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: child,
    );
  }
}

class _OverviewStep extends StatelessWidget {
  const _OverviewStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start hosting with your existing account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set up host tools, publish services, and receive bookings while keeping customer access.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _BenefitTile(
          icon: Icons.calendar_today_rounded,
          title: 'Receive bookings',
          subtitle: 'Get discovered and booked by customers in your area.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _BenefitTile(
          icon: Icons.tune_rounded,
          title: 'Manage host tools',
          subtitle: 'Control pricing, schedules, and service details in one place.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _BenefitTile(
          icon: Icons.chat_bubble_rounded,
          title: 'Handle client messages',
          subtitle: 'Respond quickly to chats and booking questions.',
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Setup usually takes around 2-3 minutes before your first service can go live.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm host upgrade',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your account will add host access while keeping all customer features available.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChecklistRow(text: 'Customer account stays active'),
              SizedBox(height: 8),
              _ChecklistRow(text: 'Host tools will be enabled'),
              SizedBox(height: 8),
              _ChecklistRow(text: 'Next step: complete host profile setup'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'By continuing, you agree to host standards and service quality guidelines.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are now a host',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host mode is enabled. Continue to your dashboard or finish onboarding.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'What changed',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _ChecklistRow(text: 'Host tools are now available in your account'),
        const SizedBox(height: 8),
        const _ChecklistRow(text: 'You can still browse and book as a customer'),
        const SizedBox(height: 8),
        const _ChecklistRow(text: 'You can publish your first service after setup'),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.step,
    required this.submitting,
    required this.onContinue,
    required this.onBackStep,
    required this.onConfirm,
    required this.onGoHostDashboard,
    required this.onCompleteOnboarding,
  });

  final int step;
  final bool submitting;
  final VoidCallback onContinue;
  final VoidCallback onBackStep;
  final VoidCallback onConfirm;
  final VoidCallback onGoHostDashboard;
  final VoidCallback onCompleteOnboarding;

  @override
  Widget build(BuildContext context) {
    if (step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onGoHostDashboard,
            icon: const Icon(Icons.dashboard_customize_rounded),
            label: const Text('Open host dashboard'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onCompleteOnboarding,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Complete host setup now'),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (step == 1)
          Expanded(
            child: OutlinedButton(
              onPressed: submitting ? null : onBackStep,
              child: const Text('Back'),
            ),
          ),
        if (step == 1) const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: submitting
                ? null
                : () {
                    if (step == 0) {
                      onContinue();
                    } else {
                      onConfirm();
                    }
                  },
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(step == 0 ? 'Continue' : 'Confirm and continue'),
          ),
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _InfoFooter extends StatelessWidget {
  const _InfoFooter({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final text = step == 0
        ? 'No new account is needed. We only upgrade your existing account.'
        : step == 1
            ? 'Pressing back returns to the previous step before confirmation.'
            : 'Host mode is active. You can switch between customer and host tools anytime.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyError(Object e) {
  if (e is DioException) {
    if (e.response?.statusCode == 404) {
      return 'Upgrade endpoint not found on server. Please restart/update backend and try again.';
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['error']?.toString();
      if (msg != null && msg.trim().isNotEmpty) return msg;
    }
    final direct = e.message?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
  }
  final raw = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '').trim();
  if (raw.isEmpty) return 'Could not complete this action. Please try again.';
  return raw.length > 160 ? '${raw.substring(0, 160)}...' : raw;
}
