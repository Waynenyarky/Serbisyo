import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/recent_searches_storage.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/responsive.dart';
import '../../../shared/widgets/create_favorite_sheet.dart';
import '../../../shared/widgets/premium_service_image.dart';
import '../../../shared/widgets/service_card.dart';

/// Sort option for search results.
enum _SortOption {
  newest('newest', 'desc', 'Newest'),
  topRated('rating', 'desc', 'Top rated'),
  priceLow('price', 'asc', 'Price: Low–High'),
  priceHigh('price', 'desc', 'Price: High–Low');

  const _SortOption(this.sortBy, this.sortOrder, this.label);
  final String sortBy;
  final String sortOrder;
  final String label;
}

enum _ViewMode { grid, list }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryController;
  late final FocusNode _searchFocusNode;
  String? _selectedCategoryId;
  _SortOption _sort = _SortOption.topRated;
  _ViewMode _viewMode = _ViewMode.grid;
  Timer? _debounce;
  static const _debounceMs = 350;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery ?? '');
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  SearchFilter get _filter => SearchFilter(
        query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
        categoryId: _selectedCategoryId,
        sortBy: _sort.sortBy,
        sortOrder: _sort.sortOrder,
      );

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (mounted) setState(() {});
    });
  }

  void _clearSearch() {
    _queryController.clear();
    setState(() {});
  }

  Future<void> _runSearch(String query) async {
    _queryController.text = query;
    _queryController.selection = TextSelection.collapsed(offset: query.length);
    if (query.trim().isNotEmpty) {
      await addRecentSearch(query.trim());
      ref.invalidate(recentSearchesProvider);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pageHorizontalPadding(context);
    final cols = Responsive.marketplaceGridColumns(context);
    final hasQueryOrCategory = _filter.query != null || _filter.categoryId != null;
    final showRecentSearches = !hasQueryOrCategory && _queryController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildModernAppBar(pad),
      body: Column(
        children: [
          _buildCategoryChips(pad),
          _buildSortRow(pad),
          if (!showRecentSearches) const Divider(height: 1),
          Expanded(
            child: showRecentSearches
                ? _buildRecentSearchesAndBrowse(context, pad)
                : _buildResults(context, pad, cols),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(double pad) {
    final hasText = _queryController.text.isNotEmpty;
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => context.pop(),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(right: pad),
        child: TextField(
            controller: _queryController,
            focusNode: _searchFocusNode,
            onChanged: _onQueryChanged,
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) {
                addRecentSearch(q.trim()).then((_) => ref.invalidate(recentSearchesProvider));
              }
              setState(() {});
            },
            textInputAction: TextInputAction.search,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
            decoration: InputDecoration(
              hintText: 'Search services or providers',
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.divider, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(double pad) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        return Container(
          padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, AppSpacing.sm),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ModernChip(
                  label: 'All',
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() => _selectedCategoryId = null),
                ),
                const SizedBox(width: 10),
                ...categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _ModernChip(
                      label: c.name,
                      isSelected: _selectedCategoryId == c.id,
                      onTap: () => setState(() => _selectedCategoryId = c.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 52),
      error: (err, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildSortRow(double pad) {
    final hasQueryOrCategory = _filter.query != null || _filter.categoryId != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _SortOption.values.map((opt) {
                  final selected = _sort == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ModernChip(
                      label: opt.label,
                      isSelected: selected,
                      compact: true,
                      onTap: () => setState(() => _sort = opt),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (hasQueryOrCategory) _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _viewMode = _viewMode == _ViewMode.grid ? _ViewMode.list : _ViewMode.grid;
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _viewMode == _ViewMode.grid ? Icons.grid_view_rounded : Icons.view_list_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _viewMode == _ViewMode.grid ? 'Grid' : 'List',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchesAndBrowse(BuildContext context, double pad) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final recentAsync = ref.watch(recentSearchesProvider);
    final servicesAsync = ref.watch(searchServicesProvider(_filter));

    return servicesAsync.when(
      data: (services) {
        if (services.isNotEmpty) {
          return _buildResultsContent(context, pad, services);
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              recentAsync.when(
                data: (recent) {
                  if (recent.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent searches',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await clearRecentSearches();
                              ref.invalidate(recentSearchesProvider);
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recent.map((q) {
                          return GestureDetector(
                            onTap: () => _runSearch(q),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_rounded, size: 18, color: AppColors.textTertiary),
                                  const SizedBox(width: 8),
                                  Text(
                                    q,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stackTrace) => const SizedBox.shrink(),
              ),
              Text(
                'Browse by category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) => Column(
                  children: categories.map((c) => _CategoryTile(
                    name: c.name,
                    onTap: () => setState(() => _selectedCategoryId = c.id),
                  )).toList(),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                ),
                error: (err, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stackTrace) => _buildErrorState(),
    );
  }

  Widget _buildResults(BuildContext context, double pad, int cols) {
    final servicesAsync = ref.watch(searchServicesProvider(_filter));
    return servicesAsync.when(
      data: (services) => _buildResultsContent(context, pad, services),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stackTrace) => _buildErrorState(),
    );
  }

  Widget _buildResultsContent(BuildContext context, double pad, List<ServiceModel> services) {
    if (services.isEmpty) return _buildEmptyState();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  '${services.length} result${services.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_viewMode == _ViewMode.grid)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.marketplaceGridColumns(context),
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
                    onFavoriteTap: () => _toggleFavorite(context, service.id, isFav),
                  );
                },
                childCount: services.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = services[index];
                  final isFav = ref.watch(isFavoriteProvider(service.id));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceListTile(
                      service: service,
                      isFavorite: isFav,
                      onTap: () => context.push('/service/${service.id}'),
                      onFavoriteTap: () => _toggleFavorite(context, service.id, isFav),
                    ),
                  );
                },
                childCount: services.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Could not load results',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, String serviceId, bool isFav) async {
    final repo = ref.read(apiRepositoryProvider);
    if (isFav) {
      await repo.removeFavoriteService(serviceId);
    } else {
      await addServiceToFavorites(context, ref, serviceId);
    }
    ref.invalidate(favoriteServicesProvider);
    ref.invalidate(favoritesIdsProvider);
  }
}

class _ModernChip extends StatelessWidget {
  const _ModernChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal list tile for search results.
class _ServiceListTile extends StatelessWidget {
  const _ServiceListTile({
    required this.service,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final ServiceModel service;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: PremiumServiceImage(
                    width: 96,
                    height: 96,
                    imageUrl: service.imageUrl,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${service.rating} (${service.reviewCount})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${service.pricePerHour.toStringAsFixed(0)}/hr',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onFavoriteTap,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.error : AppColors.textTertiary,
                    size: 22,
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
