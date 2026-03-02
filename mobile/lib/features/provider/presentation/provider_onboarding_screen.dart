import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/service_category.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Multi-step wizard: Service basics → Details & pricing → Photos → Review & publish.
class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key, this.existingDraft});

  /// If set, we're editing an existing draft (e.g. from My services).
  final ServiceModel? existingDraft;

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
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  ServiceModel? _draftService;

  @override
  void initState() {
    super.initState();
    final d = widget.existingDraft;
    if (d != null) {
      _draftService = d;
      _categoryId = d.categoryId;
      _titleController.text = d.title;
      _descriptionController.text = d.description ?? '';
      _priceController.text = d.pricePerHour > 0 ? d.pricePerHour.toStringAsFixed(0) : '';
      _imageUrlController.text = d.imageUrl ?? '';
      _step = 1;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
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
      final service = await ref.read(apiRepositoryProvider).createService(
        title: title,
        categoryId: categoryId,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
      if (!mounted) return;
      setState(() { _draftService = service; _step = 1; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('DioException [bad response]:', '').trim();
        if (_error != null && _error!.length > 120) _error = '${_error!.substring(0, 120)}...';
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
      setState(() { _draftService = updated; _step = 2; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('DioException [bad response]:', '').trim();
      });
    }
  }

  Future<void> _savePhoto() async {
    final draft = _draftService;
    if (draft == null) return;
    final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
    setState(() { _loading = true; _error = null; });
    try {
      final updated = await ref.read(apiRepositoryProvider).updateService(
        id: draft.id,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      setState(() { _draftService = updated; _step = 3; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('DioException [bad response]:', '').trim();
      });
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
      ref.invalidate(servicesProvider);
      context.go('/provider/services');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service published! Customers can now find and book it.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('DioException [bad response]:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final stepTitles = ['Service basics', 'Pricing', 'Photo', 'Review & publish'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(stepTitles[_step]),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(currentStep: _step, totalSteps: 4),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 14)),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (_step == 0) _buildStepBasics(categoriesAsync),
              if (_step == 1) _buildStepPricing(),
              if (_step == 2) _buildStepPhoto(),
              if (_step == 3) _buildStepReview(),
              const SizedBox(height: AppSpacing.xl),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: AppColors.primary))
              else
                ElevatedButton(
                  onPressed: () async {
                    if (_step == 0) await _createDraft();
                    if (_step == 1) await _savePricing();
                    if (_step == 2) await _savePhoto();
                    if (_step == 3) await _publish();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    _step == 0 ? 'Continue' : _step == 1 ? 'Continue' : _step == 2 ? 'Continue' : 'Publish service',
                  ),
                ),
            ],
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
              maxLines: 3,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set your rate per hour (₱)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          decoration: const InputDecoration(
            hintText: 'e.g. 350',
            border: OutlineInputBorder(),
            prefixText: '₱ ',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildStepPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo (optional for now)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _imageUrlController,
          decoration: const InputDecoration(
            hintText: 'Image URL',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
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
          Text(d.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(categoryName, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('₱${d.pricePerHour.toStringAsFixed(0)}/hr', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          if (d.description != null && d.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(d.description!, style: Theme.of(context).textTheme.bodyMedium),
          ],
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
