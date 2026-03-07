import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/premium_service_image.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({required this.bookingId, super.key});

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
        appBar: AppBar(
          title: const Text('Booking details'),
          backgroundColor: AppColors.surface,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load this booking.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => ref.invalidate(bookingByIdProvider(bookingId)),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDetailContent extends ConsumerWidget {
  const _BookingDetailContent({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledLabel = _formatSchedule(booking);
    final statusType = _statusType(booking);
    final statusLabel = _statusLabel(statusType);
    final statusColor = _statusColor(statusType);
    final statusBg = _statusBackground(statusType);
    final appMode = ref.watch(appExperienceModeProvider);
    final isHostMode = appMode == 'host';
    final canCancel =
        !isHostMode &&
        (statusType == _BookingStatusType.pending ||
            statusType == _BookingStatusType.confirmed ||
            statusType == _BookingStatusType.ongoing);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking details'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: PremiumServiceImage(
                            width: 84,
                            height: 84,
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.providerName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MetaLine(
                    icon: Icons.calendar_today_rounded,
                    title: 'Schedule',
                    value: scheduledLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Service details',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Date',
                    value: booking.scheduledDate,
                  ),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: booking.scheduledTime,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: booking.address,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Payment summary',
              child: Column(
                children: [
                  _AmountRow(
                    label: 'Service fee',
                    value: '₱${booking.totalAmount.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 6),
                  _AmountRow(
                    label: 'Total',
                    value: '₱${booking.totalAmount.toStringAsFixed(0)}',
                    emphasize: true,
                  ),
                  const SizedBox(height: 6),
                  _AmountRow(
                    label: 'Payment status',
                    value: booking.paymentStatus,
                  ),
                  if (booking.refundAmount > 0) ...[
                    const SizedBox(height: 6),
                    _AmountRow(
                      label: 'Refund amount',
                      value: '₱${booking.refundAmount.toStringAsFixed(0)}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Reference',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Booking ID',
                    value: booking.id,
                  ),
                  _DetailRow(
                    icon: Icons.miscellaneous_services_rounded,
                    label: 'Service ID',
                    value: booking.serviceId,
                  ),
                  if ((booking.providerId ?? '').isNotEmpty)
                    _DetailRow(
                      icon: Icons.person_pin_rounded,
                      label: 'Provider ID',
                      value: booking.providerId!,
                    ),
                  if ((booking.statusReason ?? '').isNotEmpty)
                    _DetailRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Status note',
                      value: booking.statusReason!,
                    ),
                  _DetailRow(
                    icon: Icons.policy_rounded,
                    label: 'Cancellation policy',
                    value: booking.cancellationPolicy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _BookingActions(
              booking: booking,
              isHostMode: isHostMode,
              statusType: statusType,
              canCancel: canCancel,
            ),
            if (!isHostMode &&
                (statusType == _BookingStatusType.pending ||
                    statusType == _BookingStatusType.confirmed ||
                    statusType == _BookingStatusType.ongoing) &&
                (booking.providerId ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _MessageProviderButton(booking: booking),
            ],
            if (!isHostMode && statusType == _BookingStatusType.completed) ...[
              const SizedBox(height: AppSpacing.sm),
              _LeaveReviewButton(booking: booking),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageProviderButton extends ConsumerWidget {
  const _MessageProviderButton({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            final thread = await ref
                .read(apiRepositoryProvider)
                .createDirectThread(
                  serviceId: booking.serviceId,
                  providerId: booking.providerId!,
                  serviceTitle: booking.serviceTitle,
                  providerName: booking.providerName,
                );
            if (thread == null || !context.mounted) return;
            ref.invalidate(threadsProvider);
            context.push('/messages/${thread.id}');
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not open chat right now. Please try again.',
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
        label: const Text('Message provider'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _BookingActions extends ConsumerWidget {
  const _BookingActions({
    required this.booking,
    required this.isHostMode,
    required this.statusType,
    required this.canCancel,
  });

  final BookingModel booking;
  final bool isHostMode;
  final _BookingStatusType statusType;
  final bool canCancel;

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref, {
    required Future<void> Function() action,
    required String success,
    required String errorPrefix,
  }) async {
    try {
      await action();
      ref.invalidate(bookingsProvider);
      for (final status in const <String>[
        'pending',
        'confirmed',
        'ongoing',
        'completed',
        'cancelled',
      ]) {
        ref.invalidate(bookingsByStatusProvider(status));
      }
      ref.invalidate(bookingByIdProvider(booking.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      if (!context.mounted) return;
      final message = _friendlyActionError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$errorPrefix: $message')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(apiRepositoryProvider);
    final isCustomer = !isHostMode;
    final buttons = <Widget>[];

    if (isHostMode && statusType == _BookingStatusType.pending) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _runAction(
            context,
            ref,
            action: () async => repo.acceptBooking(booking.id),
            success: 'Booking accepted.',
            errorPrefix: 'Could not accept',
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Accept request'),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _runAction(
            context,
            ref,
            action: () async => repo.declineBooking(booking.id),
            success: 'Booking declined.',
            errorPrefix: 'Could not decline',
          ),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Decline'),
        ),
      );
    }

    if (isHostMode && statusType == _BookingStatusType.confirmed) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _runAction(
            context,
            ref,
            action: () async => repo.startBooking(booking.id),
            success: 'Service marked as in progress.',
            errorPrefix: 'Could not start',
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start service'),
        ),
      );
    }

    if (isCustomer &&
        statusType == _BookingStatusType.confirmed &&
        booking.paymentStatus == 'unpaid') {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _runAction(
            context,
            ref,
            action: () async {
              await repo.createPaymentIntent(bookingId: booking.id);
            },
            success: 'Payment captured.',
            errorPrefix: 'Could not process payment',
          ),
          icon: const Icon(Icons.credit_card_rounded),
          label: const Text('Pay now'),
        ),
      );
    }

    if (isHostMode && statusType == _BookingStatusType.ongoing) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _runAction(
            context,
            ref,
            action: () async => repo.completeBooking(booking.id),
            success: 'Service marked as completed.',
            errorPrefix: 'Could not complete',
          ),
          icon: const Icon(Icons.flag_rounded),
          label: const Text('Complete service'),
        ),
      );
    }

    if (canCancel) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _runAction(
            context,
            ref,
            action: () async => repo.cancelBooking(booking.id),
            success: 'Booking cancelled.',
            errorPrefix: 'Could not cancel',
          ),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel booking'),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Actions',
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }
}

class _LeaveReviewButton extends ConsumerWidget {
  const _LeaveReviewButton({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserId = ref.watch(currentUserProvider).valueOrNull?.id ?? '';
    final reviews =
        ref.watch(bookingReviewsProvider(booking.id)).valueOrNull ?? const [];
    final alreadyReviewed =
        myUserId.isNotEmpty &&
        reviews.any((review) => review.reviewerId == myUserId);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: alreadyReviewed
            ? null
            : () async {
                final reviewDraft = await _openReviewComposer(context);
                if (reviewDraft == null) return;
                try {
                  final mode = ref.read(appExperienceModeProvider);
                  final asRole = mode == 'host' ? 'provider' : 'customer';
                  await ref
                      .read(apiRepositoryProvider)
                      .createReview(
                        bookingId: booking.id,
                        ratingOverall: reviewDraft.overall,
                        ratings: {
                          'quality': reviewDraft.quality,
                          'communication': reviewDraft.communication,
                          'punctuality': reviewDraft.punctuality,
                          'value': reviewDraft.value,
                        },
                        comment: reviewDraft.comment,
                        asRole: asRole,
                      );
                  ref.invalidate(bookingReviewsProvider(booking.id));
                  ref.invalidate(serviceReviewsProvider(booking.serviceId));
                  ref.invalidate(serviceByIdProvider(booking.serviceId));
                  // Refresh all cached service lists so updated rating/reviewCount
                  // appears across Home, Search, Favorites, and Recent sections.
                  ref.invalidate(servicesProvider);
                  ref.invalidate(searchResultsProvider);
                  ref.invalidate(searchServicesProvider);
                  ref.invalidate(favoriteServicesProvider);
                  ref.invalidate(recentlyViewedServicesProvider);
                  ref.invalidate(latestServicesProvider);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review submitted. Thank you!'),
                    ),
                  );
                } on DioException catch (e) {
                  if (!context.mounted) return;
                  final status = e.response?.statusCode;
                  final msg = e.response?.data is Map
                      ? (e.response?.data['error']?.toString() ?? '')
                      : '';
                  if (status == 409 || msg.toLowerCase().contains('already')) {
                    ref.invalidate(bookingReviewsProvider(booking.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You already submitted a review for this booking.',
                        ),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not submit review: ${msg.isEmpty ? e.message : msg}',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not submit review: $e')),
                  );
                }
              },
        icon: Icon(
          alreadyReviewed ? Icons.verified_rounded : Icons.rate_review_rounded,
        ),
        label: Text(alreadyReviewed ? 'Review submitted' : 'Rate this service'),
      ),
    );
  }
}

Future<_ReviewDraft?> _openReviewComposer(BuildContext context) async {
  return showModalBottomSheet<_ReviewDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (sheetContext) => const _ReviewComposerSheet(),
  );
}

class _ReviewDraft {
  const _ReviewDraft({
    required this.overall,
    required this.quality,
    required this.communication,
    required this.punctuality,
    required this.value,
    required this.comment,
  });

  final double overall;
  final double quality;
  final double communication;
  final double punctuality;
  final double value;
  final String comment;
}

class _ReviewComposerSheet extends StatefulWidget {
  const _ReviewComposerSheet();

  @override
  State<_ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<_ReviewComposerSheet> {
  double overall = 5;
  double quality = 5;
  double communication = 5;
  double punctuality = 5;
  double value = 5;
  late final TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Rate this completed service',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Your feedback helps customers choose better services.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              _StarRatingRow(
                label: 'Overall',
                value: overall,
                onChanged: (v) => setState(() => overall = v),
              ),
              _StarRatingRow(
                label: 'Quality',
                value: quality,
                onChanged: (v) => setState(() => quality = v),
              ),
              _StarRatingRow(
                label: 'Communication',
                value: communication,
                onChanged: (v) => setState(() => communication = v),
              ),
              _StarRatingRow(
                label: 'Punctuality',
                value: punctuality,
                onChanged: (v) => setState(() => punctuality = v),
              ),
              _StarRatingRow(
                label: 'Value',
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Share your experience with this service.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _ReviewDraft(
                        overall: overall,
                        quality: quality,
                        communication: communication,
                        punctuality: punctuality,
                        value: value,
                        comment: commentController.text.trim(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final fullStars = value.round().clamp(1, 5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: isNarrow ? 2 : 4,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    onPressed: () => onChanged(starValue.toDouble()),
                    icon: Icon(
                      starValue <= fullStars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.warning,
                    ),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 18,
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    final valueStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          )
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}

enum _BookingStatusType {
  pending,
  confirmed,
  ongoing,
  completed,
  cancelled,
  declined,
}

_BookingStatusType _statusType(BookingModel booking) {
  if (booking.completedAt != null) return _BookingStatusType.completed;
  if (booking.cancelledAt != null) return _BookingStatusType.cancelled;
  final status = booking.status.trim().toLowerCase();
  if (status == 'pending') return _BookingStatusType.pending;
  if (status == 'upcoming') {
    final hasHostResponse = booking.respondedAt != null;
    return hasHostResponse
        ? _BookingStatusType.confirmed
        : _BookingStatusType.pending;
  }
  if (status == 'confirmed') return _BookingStatusType.confirmed;
  if (status == 'ongoing') return _BookingStatusType.ongoing;
  if (status == 'completed' || status == 'past') {
    return _BookingStatusType.completed;
  }
  if (status == 'declined') return _BookingStatusType.declined;
  if (status == 'cancelled') return _BookingStatusType.cancelled;
  return _BookingStatusType.cancelled;
}

String _statusLabel(_BookingStatusType type) {
  return switch (type) {
    _BookingStatusType.pending => 'Pending',
    _BookingStatusType.confirmed => 'Confirmed',
    _BookingStatusType.ongoing => 'Ongoing',
    _BookingStatusType.completed => 'Completed',
    _BookingStatusType.cancelled => 'Cancelled',
    _BookingStatusType.declined => 'Declined',
  };
}

Color _statusColor(_BookingStatusType type) {
  return switch (type) {
    _BookingStatusType.pending => AppColors.warning,
    _BookingStatusType.confirmed => AppColors.primary,
    _BookingStatusType.ongoing => AppColors.primary,
    _BookingStatusType.completed => AppColors.success,
    _BookingStatusType.cancelled => AppColors.error,
    _BookingStatusType.declined => AppColors.textSecondary,
  };
}

Color _statusBackground(_BookingStatusType type) {
  return switch (type) {
    _BookingStatusType.pending => AppColors.warning.withValues(alpha: 0.12),
    _BookingStatusType.confirmed => AppColors.primary.withValues(alpha: 0.12),
    _BookingStatusType.ongoing => AppColors.primary.withValues(alpha: 0.12),
    _BookingStatusType.completed => AppColors.success.withValues(alpha: 0.12),
    _BookingStatusType.cancelled => AppColors.error.withValues(alpha: 0.12),
    _BookingStatusType.declined => AppColors.textTertiary.withValues(
      alpha: 0.12,
    ),
  };
}

String _formatSchedule(BookingModel booking) {
  final scheduledAt = booking.scheduledAt;
  if (scheduledAt != null) {
    return DateFormat('EEE, MMM d • h:mm a').format(scheduledAt.toLocal());
  }
  return '${booking.scheduledDate} • ${booking.scheduledTime}';
}

String _friendlyActionError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final serverMsg = error.response?.data;
    if (status == 404) {
      return 'Action endpoint not available on current server.';
    }
    if (serverMsg is Map && serverMsg['error'] != null) {
      return serverMsg['error'].toString();
    }
    return 'request failed (${status ?? 'network error'})';
  }
  return 'request failed';
}
