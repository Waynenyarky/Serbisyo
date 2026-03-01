import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/premium_service_image.dart';

/// Provider's list of services (draft + active). Add service or tap to edit.
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key, this.showBackButton = true});

  /// When false, no leading back button (e.g. when shown as a shell tab).
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(myServicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My services'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
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
                    Icon(Icons.work_outline_rounded, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.6)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No services yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add your first service to start receiving bookings.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/provider/onboarding'),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                );
              }
              final service = services[index];
              final isDraft = service.status == 'draft';
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                child: InkWell(
                  onTap: () => context.push('/provider/onboarding', extra: service),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppSpacing.radiusLg)),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: PremiumServiceImage(
                              width: 100,
                              height: 100,
                              imageUrl: service.imageUrl,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        service.title,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isDraft)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        ),
                                        child: Text(
                                          'Draft',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: AppColors.warning,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₱${service.pricePerHour.toStringAsFixed(0)}/hr',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 8, top: 8),
                          child: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load services', style: TextStyle(color: AppColors.error)),
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
}
