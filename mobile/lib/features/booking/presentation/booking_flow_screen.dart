import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/repository/api_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({
    required this.service,
    this.bookNearest = false,
    super.key,
  });

  final ServiceModel service;
  final bool bookNearest;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController(text: '');
  final String _paymentMethod = 'Card ending in **** 4242';
  bool _loadingNearest = false;
  bool _submitting = false;
  String? _nearestError;
  List<NearestProviderCandidate> _nearestCandidates = const [];
  String? _selectedNearestProviderId;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    if (widget.bookNearest) {
      _useCurrentLocationAndFindNearest();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocationAndFindNearest() async {
    setState(() {
      _loadingNearest = true;
      _nearestError = null;
      _nearestCandidates = const [];
      _selectedNearestProviderId = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required to find nearest providers.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final nearest = await ref
          .read(apiRepositoryProvider)
          .getNearestProviders(
            lat: pos.latitude,
            lng: pos.longitude,
            limit: 10,
            categoryId: widget.service.categoryId.isEmpty
                ? null
                : widget.service.categoryId,
          );

      if (!mounted) return;
      if (!nearest.matched || nearest.candidates.isEmpty) {
        setState(() {
          _loadingNearest = false;
          _nearestCandidates = const [];
          _nearestError =
              'No available providers nearby right now. Please try a different address or time.';
        });
        return;
      }

      setState(() {
        _loadingNearest = false;
        _nearestCandidates = nearest.candidates;
        _selectedNearestProviderId = nearest.candidates.first.id;
        _addressController.text =
            'Current location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingNearest = false;
        _nearestError = e.toString().replaceFirst('Exception:', '').trim();
      });
    }
  }

  NearestProviderCandidate? _selectedNearestProvider() {
    final selectedId = _selectedNearestProviderId;
    if (selectedId == null) return null;
    for (final candidate in _nearestCandidates) {
      if (candidate.id == selectedId) {
        return candidate;
      }
    }
    return null;
  }

  String _toDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _toTimeString(TimeOfDay time) {
    return '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _confirmBooking() async {
    final date = _selectedDate;
    final time = _selectedTime;
    final address = _addressController.text.trim();
    if (date == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your schedule first.')),
      );
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your service address.')),
      );
      return;
    }

    final total = widget.service.pricePerHour * 2;
    final nearestProvider = _selectedNearestProvider();
    final providerId = nearestProvider?.id ?? widget.service.providerId;
    if (providerId == null || providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider is unavailable. Please try another service.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final booking = await ref
          .read(apiRepositoryProvider)
          .createBooking(
            serviceId: widget.service.id,
            serviceTitle: widget.service.title,
            providerName:
                nearestProvider?.fullName ?? widget.service.providerName,
            scheduledDate: _toDateString(date),
            scheduledTime: _toTimeString(time),
            address: address,
            totalAmount: total,
            providerId: providerId,
            imageUrl: widget.service.imageUrl,
          );
      if (!mounted) return;
      ref.invalidate(bookingsProvider);
      final isPending = booking.status.trim().toLowerCase() == 'pending';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isPending ? 'Request sent' : 'Booking confirmed'),
          content: Text(
            isPending
                ? 'Your ${widget.service.title} request is now waiting for provider confirmation. You can track updates in Bookings.'
                : 'Your ${widget.service.title} booking is confirmed. You can view full details in Bookings.',
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('OK')),
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.go('/bookings');
              },
              child: const Text('View Bookings'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send booking request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDate;
    final selectedTime = _selectedTime;
    final total = widget.service.pricePerHour * 2;
    final selectedProvider = _selectedNearestProvider();
    final providerName = selectedProvider?.fullName.isNotEmpty == true
        ? selectedProvider!.fullName
        : widget.service.providerName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request booking'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'Service',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      providerName.isEmpty
                          ? 'Provider to be assigned'
                          : providerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Schedule',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(
                        selectedDate == null
                            ? 'Tap to select'
                            : DateFormat(
                                'EEE, MMM d, yyyy',
                              ).format(selectedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(
                            () => _selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time'),
                      subtitle: Text(
                        selectedTime == null
                            ? 'Tap to select'
                            : selectedTime.format(context),
                      ),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              selectedTime ??
                              const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Address',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Service address',
                        hintText: 'Street, barangay, city',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadingNearest
                          ? null
                          : _useCurrentLocationAndFindNearest,
                      icon: const Icon(Icons.near_me_rounded, size: 20),
                      label: _loadingNearest
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Use current location'),
                    ),
                    if (_nearestError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _nearestError!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                    ],
                    if (_nearestCandidates.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Nearest providers',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._nearestCandidates.map(
                        (candidate) => ListTile(
                          onTap: () => setState(
                            () => _selectedNearestProviderId = candidate.id,
                          ),
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _selectedNearestProviderId == candidate.id
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: _selectedNearestProviderId == candidate.id
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          title: Text(candidate.fullName),
                          subtitle: Text(
                            '${candidate.distanceMeters}m away • ${candidate.services.length} service(s)',
                          ),
                          trailing: candidate.isVerified
                              ? const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Payment',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.credit_card_rounded),
                      title: Text(_paymentMethod),
                      subtitle: const Text(
                        'Charge happens after provider confirmation',
                      ),
                      trailing: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Estimated total: ₱${total.toStringAsFixed(0)} (₱${widget.service.pricePerHour.toStringAsFixed(0)}/hr × 2 hrs)',
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
      ),
      bottomNavigationBar: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          10,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ₱${total.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _confirmBooking,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting ? 'Sending request...' : 'Send booking request',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}
