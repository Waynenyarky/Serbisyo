import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/create_favorite_sheet.dart';
import '../../../shared/widgets/service_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final servicesAsync = ref.watch(servicesProvider(_selectedCategoryId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _PremiumHeader(onSearchTap: () => context.push('/search')),
            ),
            // Section: Categories (horizontal scroll)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Categories',
                onSeeAllTap: () => context.push('/explore'),
              ),
            ),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 128,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == categories.length) {
                        return _SeeAllChip(
                          onTap: () => context.push('/explore'),
                        );
                      }
                      final cat = categories[index];
                      return CategoryChip(
                        category: cat,
                        isSelected: _selectedCategoryId == cat.id,
                        onTap: () => setState(() {
                          _selectedCategoryId = _selectedCategoryId == cat.id ? null : cat.id;
                        }),
                      );
                    },
                  ),
                ),
                loading: () => const SizedBox(
                  height: 128,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (err, stack) => SizedBox(
                  height: 128,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _SeeAllChip(onTap: () => context.push('/explore'));
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
            // Section: Near you (grid layout)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Near you',
                onSeeAllTap: () => context.push('/explore'),
                trailing: TextButton.icon(
                  onPressed: () => context.go('/favorites'),
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: const Text('Favorites'),
                ),
              ),
            ),
            servicesAsync.when(
              data: (services) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: services.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: Text('No services available')),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final service = services[index];
                            final isFav = ref.watch(isFavoriteProvider(service.id));
                            return ServiceCard(
                              service: service,
                              dense: true,
                              onTap: () => context.push('/service/${service.id}'),
                              isFavorite: isFav,
                              onFavoriteTap: () async {
                                final repo = ref.read(apiRepositoryProvider);
                                if (isFav) {
                                  await repo.removeFavoriteService(service.id);
                                  ref.invalidate(favoriteServicesProvider);
                                  ref.invalidate(favoritesIdsProvider);
                                } else {
                                  await addServiceToFavorites(context, ref, service.id);
                                }
                              },
                            );
                          },
                          childCount: services.length,
                        ),
                      ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              ),
              error: (err, stack) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: Text('Could not load services')),
                ),
              ),
            ),
            // "See all" button below the grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/explore'),
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('See all services'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// Tappable "See all" chip at the end of the categories row.
class _SeeAllChip extends StatelessWidget {
  const _SeeAllChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_rounded, size: 32, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              'See all',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Section header with title and "See all" arrow (like Airbnb).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAllTap,
    this.trailing,
  });

  final String title;
  final VoidCallback onSeeAllTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
          IconButton(
            onPressed: onSeeAllTap,
            icon: const Icon(Icons.arrow_forward_rounded),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.primaryLight.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.appTagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search services or providers',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
