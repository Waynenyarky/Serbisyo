import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class HostHomeScreen extends ConsumerWidget {
  const HostHomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(bookingsByStatusProvider('pending'));
    ref.invalidate(bookingsByStatusProvider('confirmed'));
    ref.invalidate(myServicesProvider);
    await Future.wait([
      ref.read(bookingsByStatusProvider('pending').future),
      ref.read(bookingsByStatusProvider('confirmed').future),
      ref.read(myServicesProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(bookingsByStatusProvider('pending'));
    final confirmedAsync = ref.watch(bookingsByStatusProvider('confirmed'));
    final servicesAsync = ref.watch(myServicesProvider);

    final pending = pendingAsync.valueOrNull ?? const <BookingModel>[];
    final confirmed = confirmedAsync.valueOrNull ?? const <BookingModel>[];
    final services = servicesAsync.valueOrNull ?? const <ServiceModel>[];
    final activeServices = services.where((s) => s.status == 'active').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _HostHeader(
                  pendingCount: pending.length,
                  confirmedCount: confirmed.length,
                  activeServicesCount: activeServices,
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Quick actions',
                  actionLabel: 'Open all',
                  onActionTap: () => context.push('/provider/bookings'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 370;
                      final buttonWidth = stack
                          ? constraints.maxWidth
                          : (constraints.maxWidth - AppSpacing.sm) / 2;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          SizedBox(
                            width: buttonWidth,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  context.push('/provider/onboarding'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create service'),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/provider/services'),
                              icon: const Icon(Icons.work_outline_rounded),
                              label: const Text('My services'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Today\'s requests',
                  actionLabel: 'Manage',
                  onActionTap: () => context.push('/provider/bookings'),
                ),
              ),
              pendingAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _EmptyBlock(
                        icon: Icons.inbox_outlined,
                        title: 'No pending requests',
                        subtitle: 'New booking requests will appear here.',
                      ),
                    );
                  }
                  final preview = items.take(3).toList();
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final booking = preview[index];
                      return _BookingPreviewCard(booking: booking);
                    }, childCount: preview.length),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: _BlockLoading()),
                error: (_, _) => const SliverToBoxAdapter(
                  child: _EmptyBlock(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load requests',
                    subtitle: 'Pull to refresh and try again.',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'My services',
                  actionLabel: 'View all',
                  onActionTap: () => context.push('/provider/services'),
                ),
              ),
              servicesAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _EmptyBlock(
                        icon: Icons.design_services_outlined,
                        title: 'No services yet',
                        subtitle:
                            'Create your first service to receive bookings.',
                      ),
                    );
                  }
                  final preview = items.take(3).toList();
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final service = preview[index];
                      return _ServicePreviewCard(service: service);
                    }, childCount: preview.length),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: _BlockLoading()),
                error: (_, _) => const SliverToBoxAdapter(
                  child: _EmptyBlock(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load services',
                    subtitle: 'Pull to refresh and try again.',
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostHeader extends StatelessWidget {
  const _HostHeader({
    required this.pendingCount,
    required this.confirmedCount,
    required this.activeServicesCount,
  });

  final int pendingCount;
  final int confirmedCount;
  final int activeServicesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primaryLight.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Host dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage bookings and services in one place.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppSpacing.sm * 2) / 3;
              final compact = cardWidth < 95;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: compact
                        ? (constraints.maxWidth - AppSpacing.sm) / 2
                        : cardWidth,
                    child: _KpiCard(
                      label: 'Pending',
                      value: '$pendingCount',
                      icon: Icons.mark_email_unread_outlined,
                    ),
                  ),
                  SizedBox(
                    width: compact
                        ? (constraints.maxWidth - AppSpacing.sm) / 2
                        : cardWidth,
                    child: _KpiCard(
                      label: 'Confirmed',
                      value: '$confirmedCount',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  SizedBox(
                    width: compact
                        ? (constraints.maxWidth - AppSpacing.sm) / 2
                        : cardWidth,
                    child: _KpiCard(
                      label: 'Active',
                      value: '$activeServicesCount',
                      icon: Icons.work_outline_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: onActionTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _BookingPreviewCard extends StatelessWidget {
  const _BookingPreviewCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => context.push('/booking/${booking.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.scheduledDate} • ${booking.scheduledTime}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicePreviewCard extends StatelessWidget {
  const _ServicePreviewCard({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final isActive = service.status == 'active';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${service.pricePerHour.toStringAsFixed(0)}/hr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                isActive ? 'Active' : 'Draft',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockLoading extends StatelessWidget {
  const _BlockLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: 96,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}
