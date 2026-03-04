import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/favorites_storage.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/create_favorite_sheet.dart';
import '../../../shared/widgets/premium_service_image.dart';
import '../../../shared/widgets/service_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteServicesProvider);
    final recentlyViewedAsync = ref.watch(recentlyViewedServicesProvider);
    final listNameAsync = ref.watch(favoriteListNameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      'Edit',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          return recentlyViewedAsync.when(
            data: (recentlyViewed) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionCard(
                      title: 'Recently viewed',
                      subtitle: 'Latest',
                      child: recentlyViewed.isEmpty
                          ? _GridPlaceholder(
                              message: 'Services you view will appear here.',
                              onTap: () => context.push('/'),
                            )
                          : _RecentlyViewedGrid(
                              services: recentlyViewed,
                              ref: ref,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: listNameAsync.valueOrNull ?? 'Saved',
                      subtitle: favorites.isEmpty ? '0 saved' : '${favorites.length} saved',
                      child: favorites.isEmpty
                          ? _GridPlaceholder(
                              message: 'Tap the heart on any service to save it here.',
                              onTap: () => context.push('/'),
                            )
                          : _SavedList(favorites: favorites, ref: ref),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, st) => _buildContent(context, ref, favorites, [], listNameAsync.valueOrNull ?? 'Saved'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Could not load favorites', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(favoriteServicesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ServiceModel> favorites,
    List<ServiceModel> recentlyViewed,
    String savedSectionTitle,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Recently viewed',
            subtitle: 'Latest',
            child: _RecentlyViewedGrid(services: recentlyViewed, ref: ref),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: savedSectionTitle,
            subtitle: '${favorites.length} saved',
            child: _SavedList(favorites: favorites, ref: ref),
          ),
        ],
      ),
    );
  }
}

/// Rounded card for a section (Recently viewed / Saved).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// 2x2 grid of recently viewed service thumbnails.
class _RecentlyViewedGrid extends StatelessWidget {
  const _RecentlyViewedGrid({required this.services, required this.ref});

  final List<ServiceModel> services;
  final WidgetRef ref;

  static const int _gridCount = 4;

  @override
  Widget build(BuildContext context) {
    final items = services.take(_gridCount).toList();

    if (items.isEmpty) {
      return _GridPlaceholder(message: 'Services you view will appear here.', onTap: () => context.push('/'));
    }

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final service = items[index];
          final isFav = ref.watch(isFavoriteProvider(service.id));
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/service/${service.id}'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: PremiumServiceImage(
                      width: double.infinity,
                      height: double.infinity,
                      imageUrl: service.imageUrl,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (isFav) {
                            await removeFavorite(service.id);
                            ref.invalidate(favoritesIdsProvider);
                          } else {
                            await addServiceToFavorites(context, ref, service.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.error : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder when a section is empty.
class _GridPlaceholder extends StatelessWidget {
  const _GridPlaceholder({required this.message, this.onTap});

  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: 140,
          alignment: Alignment.center,
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// List of saved (favorite) services inside the Saved card.
class _SavedList extends StatelessWidget {
  const _SavedList({required this.favorites, required this.ref});

  final List<ServiceModel> favorites;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favorites.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final service = favorites[index];
        final isFav = ref.watch(isFavoriteProvider(service.id));
        return ServiceCard(
          service: service,
          onTap: () => context.push('/service/${service.id}'),
          isFavorite: isFav,
          onFavoriteTap: () async {
            final repo = ref.read(apiRepositoryProvider);
            await repo.removeFavoriteService(service.id);
            ref.invalidate(favoriteServicesProvider);
            ref.invalidate(favoritesIdsProvider);
          },
        );
      },
    );
  }
}
