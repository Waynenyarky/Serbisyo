import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/premium_service_image.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  _BookingViewFilter _filter = _BookingViewFilter.all;

  Future<void> _refreshBookings() async {
    ref.invalidate(bookingsProvider);
    await ref.read(bookingsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
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
                children: _BookingViewFilter.values.map((item) {
                  final selected = _filter == item;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = item),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _BookingList(
              asyncBookings: bookingsAsync,
              filter: _filter,
              onRefresh: _refreshBookings,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.asyncBookings,
    required this.filter,
    required this.onRefresh,
  });

  final AsyncValue<List<BookingModel>> asyncBookings;
  final _BookingViewFilter filter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return asyncBookings.when(
      data: (bookings) {
        final list =
            bookings
                .where((b) => _matchesFilter(_statusType(b), filter))
                .toList()
              ..sort((a, b) {
                final aAt =
                    a.scheduledAt ??
                    _parseLegacyBookingDateTime(
                      a.scheduledDate,
                      a.scheduledTime,
                    );
                final bAt =
                    b.scheduledAt ??
                    _parseLegacyBookingDateTime(
                      b.scheduledDate,
                      b.scheduledTime,
                    );
                if (aAt == null || bAt == null) return 0;
                if (filter == _BookingViewFilter.all) {
                  return bAt.compareTo(aAt);
                }
                return (filter == _BookingViewFilter.pending ||
                        filter == _BookingViewFilter.confirmed ||
                        filter == _BookingViewFilter.ongoing)
                    ? aAt.compareTo(bAt)
                    : bAt.compareTo(aAt);
              });

        final emptyLabel = filter == _BookingViewFilter.all
            ? 'No bookings yet'
            : 'No ${filter.label.toLowerCase()} bookings';
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            emptyLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
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
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final booking = list[index];
              return _BookingCard(
                booking: booking,
                onTap: () => context.push('/booking/${booking.id}'),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
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
    final scheduledAt =
        booking.scheduledAt ??
        _parseLegacyBookingDateTime(
          booking.scheduledDate,
          booking.scheduledTime,
        );
    final whenLabel = scheduledAt != null
        ? DateFormat('EEE, MMM d • h:mm a').format(scheduledAt.toLocal())
        : '${booking.scheduledDate} • ${booking.scheduledTime}';
    final bookingType = _statusType(booking);
    final isPriority =
        bookingType == _BookingViewFilter.pending ||
        bookingType == _BookingViewFilter.confirmed;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: PremiumServiceImage(
                    width: 76,
                    height: 76,
                    imageUrl: booking.imageUrl,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      whenLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.providerName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${booking.totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPriority
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.textTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bookingType.label.toLowerCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isPriority
                              ? AppColors.primary
                              : AppColors.textSecondary,
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

DateTime? _parseLegacyBookingDateTime(String date, String time) {
  final raw = '${date.trim()} ${time.trim()}';
  final formats = [
    DateFormat('yyyy-MM-dd h:mm a'),
    DateFormat('yyyy-MM-dd hh:mm a'),
    DateFormat('yyyy-MM-dd HH:mm'),
    DateFormat('MMMM d, yyyy h:mm a'),
    DateFormat('MMM d, yyyy h:mm a'),
    DateFormat('M/d/yyyy h:mm a'),
  ];
  for (final f in formats) {
    try {
      return f.parseLoose(raw);
    } catch (_) {}
  }
  return DateTime.tryParse(raw);
}

enum _BookingViewFilter {
  all('All'),
  pending('Pending'),
  confirmed('Confirmed'),
  ongoing('Ongoing'),
  completed('Completed'),
  cancelled('Cancelled');

  const _BookingViewFilter(this.label);
  final String label;
}

bool _matchesFilter(_BookingViewFilter itemStatus, _BookingViewFilter filter) {
  if (filter == _BookingViewFilter.all) return true;
  return itemStatus == filter;
}

_BookingViewFilter _statusType(BookingModel booking) {
  if (booking.completedAt != null) return _BookingViewFilter.completed;
  if (booking.cancelledAt != null) return _BookingViewFilter.cancelled;
  final status = booking.status.trim().toLowerCase();
  if (status == 'pending') return _BookingViewFilter.pending;
  if (status == 'upcoming') {
    final hasHostResponse = booking.respondedAt != null;
    return hasHostResponse
        ? _BookingViewFilter.confirmed
        : _BookingViewFilter.pending;
  }
  if (status == 'confirmed') {
    return _BookingViewFilter.confirmed;
  }
  if (status == 'ongoing') return _BookingViewFilter.ongoing;
  if (status == 'completed' || status == 'past') {
    return _BookingViewFilter.completed;
  }
  return _BookingViewFilter.cancelled;
}
