import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Bookings'),
          backgroundColor: AppColors.surface,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingList(asyncBookings: bookingsAsync, filterUpcoming: true),
            _BookingList(asyncBookings: bookingsAsync, filterUpcoming: false),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.asyncBookings, required this.filterUpcoming});

  final AsyncValue<List<BookingModel>> asyncBookings;
  final bool filterUpcoming;

  @override
  Widget build(BuildContext context) {
    return asyncBookings.when(
      data: (bookings) {
        final list = filterUpcoming
            ? bookings.where((b) => b.status == 'upcoming').toList()
            : bookings.where((b) => b.status != 'upcoming').toList();
        final emptyLabel = filterUpcoming ? 'No upcoming bookings' : 'No past bookings';
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text(emptyLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final booking = list[index];
            return _BookingCard(
              booking: booking,
              onTap: () => context.push('/booking/${booking.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Could not load bookings: $e')),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(Icons.home_repair_service_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceTitle, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${booking.scheduledDate} · ${booking.scheduledTime}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('₱${booking.totalAmount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: booking.status == 'upcoming' ? AppColors.primary.withValues(alpha: 0.12) : AppColors.textTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: booking.status == 'upcoming' ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
