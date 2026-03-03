import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

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
  int _step = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController(text: '');
  final String _paymentMethod = 'Card ending in **** 4242';
  bool _loadingNearest = false;
  String? _nearestError;
  List<NearestProviderCandidate> _nearestCandidates = const [];
  String? _selectedNearestProviderId;

  @override
  void initState() {
    super.initState();
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
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to find nearest providers.');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final nearest = await ref.read(apiRepositoryProvider).getNearestProviders(
            lat: pos.latitude,
            lng: pos.longitude,
            limit: 10,
            categoryId: widget.service.categoryId.isEmpty ? null : widget.service.categoryId,
          );

      if (!mounted) return;
      if (!nearest.matched || nearest.candidates.isEmpty) {
        setState(() {
          _loadingNearest = false;
          _nearestCandidates = const [];
          _nearestError = 'No available providers nearby right now. Please try a different address or time.';
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

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _confirmBooking();
    }
  }

  void _confirmBooking() async {
    final date = _selectedDate;
    final time = _selectedTime;
    final address = _addressController.text.trim();
    if (date == null || time == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill date, time and address')),
      );
      return;
    }
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr = '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
    final total = widget.service.pricePerHour * 2;
    final nearestProvider = _selectedNearestProvider();
    try {
      await ref.read(apiRepositoryProvider).createBooking(
            serviceId: widget.service.id,
            serviceTitle: widget.service.title,
            providerName: nearestProvider?.fullName ?? widget.service.providerName,
            scheduledDate: dateStr,
            scheduledTime: timeStr,
            address: address,
            totalAmount: total,
            providerId: nearestProvider?.id ?? widget.service.providerId,
            imageUrl: widget.service.imageUrl,
          );
      if (!mounted) return;
      ref.invalidate(bookingsProvider);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking confirmed'),
          content: Text(
            'Your ${widget.service.title} booking has been confirmed. '
            'You will receive a notification with details.',
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
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Select date & time' : _step == 1 ? 'Address' : 'Payment'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _step > 0 ? setState(() => _step--) : context.pop(),
        ),
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _step,
          onStepContinue: _nextStep,
          onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_step < 2 ? 'Continue' : 'Confirm booking'),
                  ),
                  if (_step > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Date & time'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Tap to select',
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                  ),
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Tap to select',
                    ),
                    trailing: const Icon(Icons.access_time_rounded),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) setState(() => _selectedTime = time);
                    },
                  ),
                ],
              ),
              isActive: _step >= 0,
              state: _step > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Address'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Service address',
                      hintText: 'Enter your address',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loadingNearest ? null : _useCurrentLocationAndFindNearest,
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
                    const SizedBox(height: 12),
                    Text(
                      _nearestError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ],
                  if (_nearestCandidates.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Nearest providers',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._nearestCandidates.map(
                      (candidate) => ListTile(
                        onTap: () => setState(() => _selectedNearestProviderId = candidate.id),
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
                        subtitle: Text('${candidate.distanceMeters}m away • ${candidate.services.length} service(s)'),
                        trailing: candidate.isVerified
                            ? const Icon(Icons.verified_rounded, color: AppColors.primary)
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
              isActive: _step >= 1,
              state: _step > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Payment'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      widget.service.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${widget.service.pricePerHour.toStringAsFixed(0)}/hr × 2 hrs = ₱${(widget.service.pricePerHour * 2).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.credit_card_rounded),
                    title: Text(_paymentMethod),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Change payment method'),
                  ),
                ],
              ),
              isActive: _step >= 2,
              state: StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }
}
