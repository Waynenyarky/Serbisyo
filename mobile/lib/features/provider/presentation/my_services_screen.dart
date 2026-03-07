import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/premium_service_image.dart';
import 'provider_onboarding_screen.dart';

/// Provider's list of services (draft + active). Add service or tap to edit.
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key, this.showBackButton = true});

  /// When false, no leading back button (e.g. when shown as a shell tab).
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(myServicesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final categoryNameById = {for (final c in categories) c.id: c.name};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My services'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Booking requests',
            onPressed: () => context.push('/provider/bookings'),
            icon: const Icon(Icons.assignment_turned_in_outlined),
          ),
        ],
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    context.go('/favorites');
                  }
                },
              )
            : null,
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 64,
                      color: AppColors.textTertiary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No services yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add your first service to start receiving bookings.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/provider/onboarding'),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: services.length + 1,
            itemBuilder: (context, index) {
              if (index == services.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/provider/onboarding'),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add another service'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                );
              }
              final service = services[index];
              final isDraft = service.status == 'draft';
              final categoryName =
                  categoryNameById[service.categoryId] ?? 'Category';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Dismissible(
                  key: ValueKey('service-${service.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete service'),
                        content: Text(
                          'Delete "${service.title}"? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete != true) return false;

                    try {
                      await ref
                          .read(apiRepositoryProvider)
                          .deleteService(service.id);
                      ref.invalidate(myServicesProvider);
                      ref.invalidate(providerStatusProvider);
                      ref.invalidate(servicesProvider(null));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Service deleted.')),
                        );
                      }
                      return true;
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not delete service: $e'),
                          ),
                        );
                      }
                      return false;
                    }
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: _ServiceCardContent(
                      service: service,
                      isDraft: isDraft,
                      categoryName: categoryName,
                      onDetails: () => _showServiceDetailsSheet(
                        context: context,
                        service: service,
                        categoryName: categoryName,
                      ),
                      onEdit: () => _openEditStepPicker(context, service),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load services',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(myServicesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceDetailsSheet({
    required BuildContext context,
    required ServiceModel service,
    required String categoryName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 360;
                        final image = ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          child: PremiumServiceImage(
                            width: 110,
                            height: 110,
                            imageUrl: service.imageUrl,
                          ),
                        );
                        final details = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              categoryName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₱${service.pricePerHour.toStringAsFixed(0)}/hr',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StatusPill(isDraft: service.status == 'draft'),
                          ],
                        );
                        if (stacked) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              image,
                              const SizedBox(height: AppSpacing.md),
                              details,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            image,
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: details),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DetailLine(
                      label: 'Description',
                      value: service.description,
                    ),
                    _DetailLine(label: 'Offers', value: service.offers),
                    _DetailLine(
                      label: 'Location',
                      value: service.locationDescription,
                    ),
                    _DetailLine(
                      label: 'Availability',
                      value: service.availability,
                    ),
                    _DetailLine(
                      label: 'Things to know',
                      value: service.thingsToKnow,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final rootContext = context;
                          Navigator.of(context).pop();
                          await _openEditStepPicker(rootContext, service);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit service'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditStepPicker(
    BuildContext context,
    ServiceModel service,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.86),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
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
                    'Choose what to edit',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.title,
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView(
                      children: [
                        _EditStepTile(
                          icon: Icons.tune_rounded,
                          title: 'Service basics',
                          subtitle: 'Title, category, and description',
                          onTap: () => Navigator.of(sheetContext).pop(0),
                        ),
                        _EditStepTile(
                          icon: Icons.list_alt_rounded,
                          title: 'Service details',
                          subtitle:
                              'Offers, location, availability, things to know',
                          onTap: () => Navigator.of(sheetContext).pop(1),
                        ),
                        _EditStepTile(
                          icon: Icons.payments_outlined,
                          title: 'Pricing',
                          subtitle: 'Hourly rate and price preview',
                          onTap: () => Navigator.of(sheetContext).pop(2),
                        ),
                        _EditStepTile(
                          icon: Icons.photo_camera_back_outlined,
                          title: 'Photo',
                          subtitle: 'Gallery, camera, or image URL',
                          onTap: () => Navigator.of(sheetContext).pop(3),
                        ),
                        _EditStepTile(
                          icon: Icons.fact_check_outlined,
                          title: 'Review & publish',
                          subtitle: 'Check status and publish updates',
                          onTap: () => Navigator.of(sheetContext).pop(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;
    context.push(
      '/provider/onboarding',
      extra: ProviderOnboardingArgs(
        existingDraft: service,
        initialStep: selected,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isDraft});

  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final bg = isDraft
        ? AppColors.warning.withValues(alpha: 0.16)
        : AppColors.success.withValues(alpha: 0.16);
    final fg = isDraft ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        isDraft ? 'Draft' : 'Active',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ServiceCardContent extends StatelessWidget {
  const _ServiceCardContent({
    required this.service,
    required this.isDraft,
    required this.categoryName,
    required this.onDetails,
    required this.onEdit,
  });

  final ServiceModel service;
  final bool isDraft;
  final String categoryName;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  String get _description {
    final text = service.description?.trim();
    if (text == null || text.isEmpty) return 'No description yet.';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: PremiumServiceImage(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth * 9 / 16,
                  imageUrl: service.imageUrl,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _ServiceCardBody(
                  service: service,
                  isDraft: isDraft,
                  categoryName: categoryName,
                  description: _description,
                  onDetails: onDetails,
                  onEdit: onEdit,
                ),
              ),
            ],
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 172),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 118,
                child: PremiumServiceImage(
                  width: 118,
                  height: 172,
                  imageUrl: service.imageUrl,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _ServiceCardBody(
                    service: service,
                    isDraft: isDraft,
                    categoryName: categoryName,
                    description: _description,
                    onDetails: onDetails,
                    onEdit: onEdit,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceCardBody extends StatelessWidget {
  const _ServiceCardBody({
    required this.service,
    required this.isDraft,
    required this.categoryName,
    required this.description,
    required this.onDetails,
    required this.onEdit,
  });

  final ServiceModel service;
  final bool isDraft;
  final String categoryName;
  final String description;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(isDraft: isDraft),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              categoryName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₱${service.pricePerHour.toStringAsFixed(0)}/hr',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, actionConstraints) {
            final stackButtons = actionConstraints.maxWidth < 280;
            final buttonWidth = stackButtons
                ? actionConstraints.maxWidth
                : (actionConstraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: buttonWidth,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(normalized, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EditStepTile extends StatelessWidget {
  const _EditStepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
