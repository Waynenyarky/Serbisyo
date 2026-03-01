import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({
    required this.bookingId,
    super.key,
  });

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBooking = ref.watch(bookingByIdProvider(bookingId));

    return asyncBooking.when(
      data: (data) {
        final booking = data as BookingModel?;
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking')),
            body: const Center(child: Text('Booking not found')),
          );
        }
        return _BookingDetailContent(booking: booking);
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Booking details'), backgroundColor: AppColors.surface),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => _buildErrorState(context, ref, e),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object e) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load this booking.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => ref.invalidate(bookingByIdProvider(bookingId)),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDetailContent extends StatelessWidget {
  const _BookingDetailContent({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking details'),
        backgroundColor: AppColors.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(booking.providerName, style: Theme.of(context).textTheme.bodyMedium),
                    const Divider(height: 24),
                    _DetailRow(icon: Icons.calendar_today_rounded, label: 'Date', value: booking.scheduledDate),
                    _DetailRow(icon: Icons.access_time_rounded, label: 'Time', value: booking.scheduledTime),
                    _DetailRow(icon: Icons.location_on_rounded, label: 'Address', value: booking.address),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: Theme.of(context).textTheme.titleMedium),
                        Text('₱${booking.totalAmount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: booking.status == 'upcoming' ? AppColors.primary.withValues(alpha: 0.12) : AppColors.textTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: booking.status == 'upcoming' ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (booking.status == 'upcoming') ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                  label: const Text('Message provider'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
