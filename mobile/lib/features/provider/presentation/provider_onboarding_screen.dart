import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/service_category.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ProviderOnboardingArgs {
  const ProviderOnboardingArgs({
    required this.existingDraft,
    required this.initialStep,
  });

  final ServiceModel existingDraft;
  final int initialStep;
}

/// Multi-step wizard: Service basics → Details & pricing → Photos → Review & publish.
class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({
    super.key,
    this.existingDraft,
    this.initialStep = 0,
  });

  /// If set, we're editing an existing draft (e.g. from My services).
  final ServiceModel? existingDraft;
  final int initialStep;

  @override
  ConsumerState<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends ConsumerState<ProviderOnboardingScreen> {
  int _step = 0;
  bool _loading = false;
  String? _error;

  String? _categoryId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _offersController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _thingsToKnowController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedImage;

  ServiceModel? _draftService;

  static const List<_StepMeta> _steps = [
    _StepMeta(
      title: 'Service basics',
      subtitle: 'Choose a category and create a clear service title.',
      ctaLabel: 'Save and continue',
    ),
    _StepMeta(
      title: 'Service details',
      subtitle: 'Fill the same sections customers will see before booking.',
      ctaLabel: 'Save details',
    ),
    _StepMeta(
      title: 'Pricing',
      subtitle: 'Set a competitive hourly rate customers can trust.',
      ctaLabel: 'Save pricing',
    ),
    _StepMeta(
      title: 'Photo',
      subtitle: 'Add a photo to improve trust and booking conversion.',
      ctaLabel: 'Save photo',
    ),
    _StepMeta(
      title: 'Review & publish',
      subtitle: 'Check your service details before going live.',
      ctaLabel: 'Publish service',
    ),
  ];

  void _onFieldChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
    _offersController.addListener(_onFieldChanged);
    _locationDescriptionController.addListener(_onFieldChanged);
    _availabilityController.addListener(_onFieldChanged);
    _thingsToKnowController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _imageUrlController.addListener(_onFieldChanged);
    _restoreLostPickerData();
    final d = widget.existingDraft;
    if (d != null) {
      _draftService = d;
      _categoryId = d.categoryId;
      _titleController.text = d.title;
      _descriptionController.text = d.description ?? '';
      _offersController.text = d.offers ?? '';
      _locationDescriptionController.text = d.locationDescription ?? '';
      _availabilityController.text = d.availability ?? '';
      _thingsToKnowController.text = d.thingsToKnow ?? '';
      _priceController.text = d.pricePerHour > 0 ? d.pricePerHour.toStringAsFixed(0) : '';
      _imageUrlController.text = d.imageUrl ?? '';
      _step = _normalizeStep(widget.initialStep);
    } else {
      _step = 0;
    }
  }

  int _normalizeStep(int step) {
    if (step < 0) return 0;
    if (step >= _steps.length) return _steps.length - 1;
    return step;
  }

  Future<void> _restoreLostPickerData() async {
    try {
      final lost = await _picker.retrieveLostData();
      if (!mounted || lost.isEmpty) return;
      if (lost.file != null) {
        setState(() {
          _pickedImage = lost.file;
          _error = null;
        });
      } else if (lost.exception != null) {
        setState(() => _error = 'Could not recover selected image. Please try again.');
      }
    } catch (_) {
      // Ignore; user can pick again.
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _offersController.removeListener(_onFieldChanged);
    _locationDescriptionController.removeListener(_onFieldChanged);
    _availabilityController.removeListener(_onFieldChanged);
    _thingsToKnowController.removeListener(_onFieldChanged);
    _priceController.removeListener(_onFieldChanged);
    _imageUrlController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _offersController.dispose();
    _locationDescriptionController.dispose();
    _availabilityController.dispose();
    _thingsToKnowController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  bool get _canContinueCurrentStep {
    if (_loading) return false;
    if (_step == 0) {
      return (_categoryId?.isNotEmpty ?? false) && _titleController.text.trim().isNotEmpty;
    }
    if (_step == 1) {
      return _offersController.text.trim().isNotEmpty &&
          _locationDescriptionController.text.trim().isNotEmpty &&
          _availabilityController.text.trim().isNotEmpty &&
          _thingsToKnowController.text.trim().isNotEmpty;
    }
    if (_step == 2) {
      final price = double.tryParse(_priceController.text.trim());
      return price != null && price > 0;
    }
    if (_step == 3) return true; // Photo is optional.
    if (_step == 4) return (_draftService?.pricePerHour ?? 0) > 0;
    return false;
  }

  Future<bool> _onWillPop() async {
    if (_loading) return false;
    if (_step > 0) {
      setState(() => _step--);
      return false;
    }
    return true;
  }

  Future<void> _createDraft() async {
    final title = _titleController.text.trim();
    final categoryId = _categoryId;
    if (title.isEmpty || categoryId == null || categoryId.isEmpty) {
      setState(() => _error = 'Select a category and enter a title');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final draft = _draftService;
      final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
      final service = draft == null
          ? await ref.read(apiRepositoryProvider).createService(
              title: title,
              categoryId: categoryId,
              description: description,
            )
          : await ref.read(apiRepositoryProvider).updateService(
              id: draft.id,
              title: title,
              categoryId: categoryId,
              description: description,
            );
      if (!mounted) return;
      if (service.status == 'active') _invalidateCustomerServiceFeeds();
      setState(() { _draftService = service; _step = 1; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _savePricing() async {
    final draft = _draftService;
    if (draft == null) return;
    final priceStr = _priceController.text.trim();
    final price = double.tryParse(priceStr);
    if (price == null || price <= 0) {
      setState(() => _error = 'Enter a valid price per hour (e.g. 350)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final updated = await ref.read(apiRepositoryProvider).updateService(
        id: draft.id,
        pricePerHour: price,
      );
      if (!mounted) return;
      if (updated.status == 'active') _invalidateCustomerServiceFeeds();
      setState(() { _draftService = updated; _step = 3; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _savePhoto() async {
    final draft = _draftService;
    if (draft == null) return;
    final manualUrl = _imageUrlController.text.trim();

    // If no image was chosen and no URL entered, allow continuing.
    if (_pickedImage == null && manualUrl.isEmpty) {
      setState(() => _step = 4);
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      ServiceModel updated;
      if (_pickedImage != null) {
        updated = await ref.read(apiRepositoryProvider).uploadServicePhoto(
              id: draft.id,
              filePath: _pickedImage!.path,
            );
      } else {
        updated = await ref.read(apiRepositoryProvider).updateService(
              id: draft.id,
              imageUrl: manualUrl,
            );
      }
      if (!mounted) return;
      if (updated.status == 'active') _invalidateCustomerServiceFeeds();
      setState(() {
        _draftService = updated;
        _step = 4;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (file == null) {
        setState(() {
          _error = 'No image selected. Please choose a photo to continue.';
        });
        return;
      }
      setState(() {
        _pickedImage = file;
        _imageUrlController.clear();
        _error = null;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _error = 'Camera/Gallery plugin is not ready. Please stop app and run it again.';
      });
    } on PlatformException catch (e) {
      debugPrint('Image picker platform error [${e.code}]: ${e.message}');
      if (!mounted) return;
      final code = e.code.toLowerCase();
      if (code.contains('permission')) {
        setState(() => _error = 'Permission denied. Please allow Camera/Photos access in device settings.');
      } else {
        setState(() => _error = 'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not pick image. Please try again.');
    }
  }

  Future<void> _publish() async {
    final draft = _draftService;
    if (draft == null) return;
    if (draft.pricePerHour <= 0) {
      setState(() => _error = 'Set price before publishing');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(apiRepositoryProvider).updateService(id: draft.id, status: 'active');
      if (!mounted) return;
      ref.invalidate(myServicesProvider);
      ref.invalidate(providerStatusProvider);
      _invalidateCustomerServiceFeeds();
      context.go('/provider/services');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service published! Customers can now find and book it.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _saveServiceDetails() async {
    final draft = _draftService;
    if (draft == null) return;
    final offers = _offersController.text.trim();
    final locationDescription = _locationDescriptionController.text.trim();
    final availability = _availabilityController.text.trim();
    final thingsToKnow = _thingsToKnowController.text.trim();

    if (offers.isEmpty || locationDescription.isEmpty || availability.isEmpty || thingsToKnow.isEmpty) {
      setState(() => _error = 'Please complete all service detail sections.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final updated = await ref.read(apiRepositoryProvider).updateService(
        id: draft.id,
        offers: offers,
        locationDescription: locationDescription,
        availability: availability,
        thingsToKnow: thingsToKnow,
      );
      if (!mounted) return;
      if (updated.status == 'active') _invalidateCustomerServiceFeeds();
      setState(() { _draftService = updated; _step = 2; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final raw = e.toString().replaceFirst('DioException [bad response]:', '').trim();
    if (raw.isEmpty) return 'Something went wrong. Please try again.';
    return raw.length > 140 ? '${raw.substring(0, 140)}...' : raw;
  }

  void _invalidateCustomerServiceFeeds() {
    ref.invalidate(servicesProvider);
    ref.invalidate(searchResultsProvider);
    ref.invalidate(searchServicesProvider);
    ref.invalidate(recentlyViewedServicesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final stepMeta = _steps[_step];

    return PopScope(
      canPop: _step == 0 && !_loading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(stepMeta.title),
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_loading) return;
              if (_step > 0) {
                setState(() => _step--);
                return;
              }
              context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(currentStep: _step, totalSteps: _steps.length),
                const SizedBox(height: AppSpacing.md),
                Text(
                  stepMeta.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (_step == 0) _buildStepBasics(categoriesAsync),
                if (_step == 1) _buildStepServiceDetails(),
                if (_step == 2) _buildStepPricing(),
                if (_step == 3) _buildStepPhoto(),
                if (_step == 4) _buildStepReview(),
                const SizedBox(height: AppSpacing.xl),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else ...[
                  ElevatedButton(
                    onPressed: _canContinueCurrentStep
                        ? () async {
                            final actionStep = _step;
                            if (actionStep == 0) {
                              await _createDraft();
                            } else if (actionStep == 1) {
                              await _saveServiceDetails();
                            } else if (actionStep == 2) {
                              await _savePricing();
                            } else if (actionStep == 3) {
                              await _savePhoto();
                            } else if (actionStep == 4) {
                              await _publish();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.divider,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: Text(stepMeta.ctaLabel),
                  ),
                  if (_step == 3) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => setState(() => _step = 4),
                      child: const Text('Skip for now'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBasics(AsyncValue<List<ServiceCategory>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              hint: const Text('Select category'),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Service title',
                hintText: 'e.g. Full House Cleaning',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What do you offer?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 300,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Select category'),
            items: (ref.watch(categoriesProvider).value ?? []).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Service title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStepPricing() {
    final price = double.tryParse(_priceController.text.trim());
    final hasValidPrice = price != null && price > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set your rate per hour (₱)', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          decoration: const InputDecoration(
            hintText: 'e.g. 350',
            border: OutlineInputBorder(),
            prefixText: '₱ ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tip: Competitive rates usually fall between ₱250 and ₱600 per hour depending on service complexity.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [250, 350, 500, 700]
              .map(
                (value) => ActionChip(
                  label: Text('₱$value'),
                  onPressed: () => setState(() => _priceController.text = value.toString()),
                ),
              )
              .toList(),
        ),
        if (hasValidPrice) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Rate preview: ₱${price.toStringAsFixed(0)}/hour',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepServiceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What this service offers', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _offersController,
          decoration: const InputDecoration(
            hintText: 'Installation of outlets, lights, and switches',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          maxLength: 240,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Where you\'ll be', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _locationDescriptionController,
          decoration: const InputDecoration(
            hintText: 'Servicing condos, apartments, and houses within service radius.',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          maxLength: 180,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Availability', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _availabilityController,
          decoration: const InputDecoration(
            hintText: 'Mon–Sat, 9:00 AM – 5:00 PM',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          maxLength: 120,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Things to know', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _thingsToKnowController,
          decoration: const InputDecoration(
            hintText: 'One tip per line (e.g. permits, safety reminders, extra charges).',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: 320,
        ),
      ],
    );
  }

  Widget _buildStepPhoto() {
    final hasPicked = _pickedImage != null;
    final imageUrl = _imageUrlController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Upload a real photo of your service so customers can trust your listing.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _imageUrlController,
          decoration: const InputDecoration(
            hintText: 'Or paste image URL (optional)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasPicked
              ? 'Selected image will be uploaded when you continue.'
              : 'You may upload now or skip and add a photo later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (hasPicked) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                File(_pickedImage!.path),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ] else if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.divider,
                  alignment: Alignment.center,
                  child: const Text('Could not preview image URL'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepReview() {
    final d = _draftService;
    if (d == null) return const SizedBox();
    final categories = ref.watch(categoriesProvider).value ?? [];
    String categoryName = d.categoryId;
    for (final c in categories) {
      if (c.id == d.categoryId) {
        categoryName = c.name;
        break;
      }
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to publish',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(d.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(categoryName, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('₱${d.pricePerHour.toStringAsFixed(0)}/hr', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          if (d.description != null && d.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(d.description!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          const _ReviewRow(label: 'Category selected', done: true),
          const SizedBox(height: 6),
          _ReviewRow(
            label: 'Service details completed',
            done: (d.offers ?? '').trim().isNotEmpty &&
                (d.locationDescription ?? '').trim().isNotEmpty &&
                (d.availability ?? '').trim().isNotEmpty &&
                (d.thingsToKnow ?? '').trim().isNotEmpty,
          ),
          const SizedBox(height: 6),
          const _ReviewRow(label: 'Pricing set', done: true),
          const SizedBox(height: 6),
          _ReviewRow(label: 'Photo added', done: (d.imageUrl ?? '').trim().isNotEmpty),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isPast = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive || isPast ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _StepMeta {
  const _StepMeta({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: done ? AppColors.success : AppColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? AppColors.textPrimary : AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
