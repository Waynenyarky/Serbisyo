import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/favorites_storage.dart';
import '../../../core/api/recently_viewed_storage.dart';
import '../../../core/models/host_profile_model.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/create_favorite_sheet.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({
    required this.serviceId,
    super.key,
  });

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncService = ref.watch(serviceByIdProvider(serviceId));

    return asyncService.when(
      data: (data) {
        final service = data as ServiceModel?;
        if (service == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Service')),
            body: const Center(child: Text('Service not found')),
          );
        }
        return _RecordRecentlyViewed(
          serviceId: service.id,
          child: _ServiceDetailContent(service: service),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => _buildErrorState(context, ref, e),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object e) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load this service.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => ref.invalidate(serviceByIdProvider(serviceId)),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Records service view once when built and invalidates recently viewed provider.
class _RecordRecentlyViewed extends ConsumerStatefulWidget {
  const _RecordRecentlyViewed({required this.serviceId, required this.child});

  final String serviceId;
  final Widget child;

  @override
  ConsumerState<_RecordRecentlyViewed> createState() => _RecordRecentlyViewedState();
}

class _RecordRecentlyViewedState extends ConsumerState<_RecordRecentlyViewed> {
  @override
  void initState() {
    super.initState();
    addRecentlyViewed(widget.serviceId).then((_) {
      if (mounted) ref.invalidate(recentlyViewedIdsProvider);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ServiceDetailContent extends ConsumerWidget {
  const _ServiceDetailContent({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = service.imageUrl != null && service.imageUrl!.trim().isNotEmpty;
    final isFavorite = ref.watch(isFavoriteProvider(service.id));
    final hostAsync = service.providerId != null
        ? ref.watch(hostProfileProvider(service.providerId!))
        : const AsyncValue<HostProfile?>.data(null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.error : Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () async {
                  if (isFavorite) {
                    await removeFavorite(service.id);
                    ref.invalidate(favoritesIdsProvider);
                  } else {
                    await addServiceToFavorites(context, ref, service.id);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _imagePlaceholder(),
                      errorWidget: (context, url, error) => _imagePlaceholder(),
                    )
                  else
                    _imagePlaceholder(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(102),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _OverviewSection(service: service),
                  const SizedBox(height: AppSpacing.md),
                  if ((service.offers ?? service.description)?.isNotEmpty == true)
                    _CardSection(
                      title: 'What this service offers',
                      child: Text(
                        (service.offers ?? service.description)!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if ((service.locationDescription)?.isNotEmpty == true)
                    const SizedBox(height: AppSpacing.md),
                  if ((service.locationDescription)?.isNotEmpty == true)
                    _CardSection(
                      title: 'Where you’ll be',
                      child: Text(
                        service.locationDescription!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  hostAsync.when(
                    data: (host) => host == null
                        ? const SizedBox.shrink()
                        : _MeetYourHostSection(
                            host: host,
                            service: service,
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  if ((service.availability)?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CardSection(
                      title: 'Availability',
                      child: Text(
                        service.availability!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  if ((service.thingsToKnow)?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ThingsToKnowSection(text: service.thingsToKnow!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _ReviewsSummarySection(service: service),
                  const SizedBox(height: AppSpacing.lg),
                  _ActionsSection(service: service),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(51),
            AppColors.primaryLight.withAlpha(25),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.home_repair_service_rounded,
          size: 80,
          color: AppColors.primary.withAlpha(127),
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: service.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 22, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                service.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                ' (${service.reviewCount} reviews)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  service.providerName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                '₱${service.pricePerHour.toStringAsFixed(0)}/hr',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeetYourHostSection extends StatelessWidget {
  const _MeetYourHostSection({required this.host, required this.service});

  final HostProfile host;
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Meet your host',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withAlpha(31),
            backgroundImage: host.avatarUrl != null && host.avatarUrl!.isNotEmpty
                ? NetworkImage(host.avatarUrl!)
                : null,
            child: host.avatarUrl == null || host.avatarUrl!.isEmpty
                ? Text(
                    host.fullName.isNotEmpty ? host.fullName[0].toUpperCase() : '?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        host.fullName.isNotEmpty ? host.fullName : service.providerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (host.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (host.serviceArea.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    host.serviceArea,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (host.bio.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    host.bio,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThingsToKnowSection extends StatelessWidget {
  const _ThingsToKnowSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').where((e) => e.trim().isNotEmpty).toList();
    return _CardSection(
      title: 'Things to know',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      line.trim(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}



class _ReviewsSummarySection extends StatelessWidget {
  const _ReviewsSummarySection({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Reviews',
      child: Row(
        children: [
          Icon(Icons.star_rounded, size: 24, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(
            service.rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(
            '(${service.reviewCount} reviews)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends ConsumerWidget {
  const _ActionsSection({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/booking/flow?nearest=true', extra: service),
                icon: const Icon(Icons.near_me_rounded, size: 20),
                label: const Text('Book nearest'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/booking/flow', extra: service),
                icon: const Icon(Icons.calendar_today_rounded, size: 20),
                label: const Text('Book this provider'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: service.providerId == null
              ? null
              : () async {
                  final repo = ref.read(apiRepositoryProvider);
                  final thread = await repo.createDirectThread(
                    serviceId: service.id,
                    providerId: service.providerId!,
                    serviceTitle: service.title,
                    providerName: service.providerName,
                  );
                  if (thread == null) return;
                  if (!context.mounted) return;
                  context.push('/messages/${thread.id}');
                },
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
          label: const Text('Message host'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.divider),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ],
    );
  }
}
