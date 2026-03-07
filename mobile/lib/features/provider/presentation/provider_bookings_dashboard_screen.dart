import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ProviderBookingsDashboardScreen extends ConsumerStatefulWidget {
  const ProviderBookingsDashboardScreen({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  ConsumerState<ProviderBookingsDashboardScreen> createState() =>
      _ProviderBookingsDashboardScreenState();
}

class _ProviderBookingsDashboardScreenState
    extends ConsumerState<ProviderBookingsDashboardScreen> {
  int _tab = 0;

  static const _tabs = [
    ('New requests', 'pending'),
    ('Confirmed', 'confirmed'),
    ('In progress', 'ongoing'),
    ('Completed', 'completed'),
    ('Cancelled', 'cancelled'),
  ];

  Future<void> _refresh() async {
    for (final tab in _tabs) {
      ref.invalidate(bookingsByStatusProvider(tab.$2));
    }
    await ref.read(bookingsByStatusProvider(_tabs[_tab].$2).future);
  }

  void _invalidateAllTabs() {
    for (final tab in _tabs) {
      ref.invalidate(bookingsByStatusProvider(tab.$2));
    }
    ref.invalidate(bookingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final status = _tabs[_tab].$2;
    final listAsync = ref.watch(bookingsByStatusProvider(status));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Host bookings'),
        backgroundColor: AppColors.surface,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final selected = _tab == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_tabs[index].$1),
                      selected: selected,
                      onSelected: (_) => setState(() => _tab = index),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: listAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.sizeOf(context).height * 0.42,
                          ),
                          child: const Center(
                            child: Text('No bookings in this section'),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _HostBookingCard(
                      booking: items[index],
                      onActionDone: _invalidateAllTabs,
                    ),
                  );
                },
                loading: () => ListView(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height * 0.42,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                error: (e, _) => ListView(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height * 0.42,
                      ),
                      child: Center(child: Text('Could not load bookings: $e')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostBookingCard extends ConsumerWidget {
  const _HostBookingCard({required this.booking, required this.onActionDone});

  final BookingModel booking;
  final VoidCallback onActionDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(apiRepositoryProvider);
    final status = _hostStatusKey(booking);
    Future<void> runAction(Future<void> Function() action, String ok) async {
      try {
        await action();
        onActionDone();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      } catch (e) {
        if (!context.mounted) return;
        final message = _friendlyActionError(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.serviceTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            _HostStatusBadge(status: status),
            const SizedBox(height: 4),
            Text(
              booking.providerName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text('${booking.scheduledDate} • ${booking.scheduledTime}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'pending') ...[
                  FilledButton(
                    onPressed: () => runAction(
                      () async => repo.acceptBooking(booking.id),
                      'Booking accepted',
                    ),
                    child: const Text('Accept'),
                  ),
                  OutlinedButton(
                    onPressed: () => runAction(
                      () async => repo.declineBooking(booking.id),
                      'Booking declined',
                    ),
                    child: const Text('Decline'),
                  ),
                ],
                if (status == 'confirmed')
                  FilledButton(
                    onPressed: () => runAction(
                      () async => repo.startBooking(booking.id),
                      'Service marked as in progress',
                    ),
                    child: const Text('Start service'),
                  ),
                if (status == 'ongoing')
                  FilledButton(
                    onPressed: () => runAction(
                      () async => repo.completeBooking(booking.id),
                      'Service marked as completed',
                    ),
                    child: const Text('Complete service'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyActionError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final serverMsg = error.response?.data;
    if (status == 404) {
      return 'Action endpoint not available on current server. Please restart backend and try again.';
    }
    if (serverMsg is Map && serverMsg['error'] != null) {
      return serverMsg['error'].toString();
    }
    return 'Request failed (${status ?? 'network error'}). Please try again.';
  }
  return 'Action failed. Please try again.';
}

String _hostStatusKey(BookingModel booking) {
  final status = booking.status.trim().toLowerCase();
  if (status == 'upcoming') {
    final hasHostResponse = booking.respondedAt != null;
    return hasHostResponse ? 'confirmed' : 'pending';
  }
  if (status == 'past') return 'completed';
  return status;
}

class _HostStatusBadge extends StatelessWidget {
  const _HostStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final label = switch (normalized) {
      'pending' => 'Pending confirmation',
      'confirmed' => 'Confirmed',
      'ongoing' => 'In progress',
      'completed' => 'Completed',
      'declined' => 'Declined',
      'cancelled' => 'Cancelled',
      _ => normalized,
    };
    final color = switch (normalized) {
      'pending' => AppColors.warning,
      'confirmed' => AppColors.primary,
      'ongoing' => AppColors.primary,
      'completed' => AppColors.success,
      'declined' => AppColors.textSecondary,
      'cancelled' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
