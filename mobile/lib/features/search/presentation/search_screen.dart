import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/favorites_storage.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/create_favorite_sheet.dart';
import '../../../shared/widgets/service_card.dart';

/// Suggested category tile (from API) for Search.
class _SuggestedCategoryTile extends StatelessWidget {
  const _SuggestedCategoryTile({
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.category_rounded, color: AppColors.textSecondary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with TickerProviderStateMixin {
  final _whereController = TextEditingController();
  String _whenText = 'Add dates';
  String _whoText = 'Add guests';
  bool _showResults = false;
  /// When user taps a suggested category, filter results by this category (from API).
  String? _selectedCategoryId;
  late final AnimationController _entranceController;
  late final Animation<double> _appBarAnimation;
  late final Animation<double> _whereAnimation;
  late final Animation<double> _suggestedAnimation;
  late final Animation<double> _whenAnimation;
  late final Animation<double> _whoAnimation;
  late final Animation<double> _bottomBarAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    const curve = Curves.easeOutCubic;
    _appBarAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.38, curve: curve),
    );
    _whereAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.06, 0.44, curve: curve),
    );
    _suggestedAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.52, curve: curve),
    );
    _whenAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.22, 0.58, curve: curve),
    );
    _whoAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.64, curve: curve),
    );
    _bottomBarAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.36, 0.72, curve: curve),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _whereController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _whereController.clear();
      _whenText = 'Add dates';
      _whoText = 'Add guests';
      _showResults = false;
      _selectedCategoryId = null;
    });
  }

  void _onSearch() {
    // If dates or guests are not set yet, run the guided flow first.
    final needsWhen = _whenText.startsWith('Add');
    final needsWho = _whoText.startsWith('Add');
    if (needsWhen || needsWho) {
      _startGuidedFlow();
    } else {
      setState(() => _showResults = true);
    }
  }

  /// Opens the date range picker. Returns true when the user selects a range.
  Future<bool> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _whenText = '${range.start.day}/${range.start.month} – ${range.end.day}/${range.end.month}';
      });
      return true;
    }
    return false;
  }

  /// Opens the guests dialog. Returns true when the user confirms a value.
  Future<bool> _pickGuests() async {
    int count = 1;
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add guests'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Guests'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: count <= 1 ? null : () => setDialogState(() => count--),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        IconButton(
                          onPressed: () => setDialogState(() => count++),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, count),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _whoText = picked == 1 ? '1 guest' : '$picked guests');
      return true;
    }
    return false;
  }

  /// Guided flow: When the user finishes \"Where?\", move them through When → Who → Results.
  Future<void> _startGuidedFlow() async {
    final pickedDates = await _pickDates();
    if (!mounted || !pickedDates) return;

    final pickedGuests = await _pickGuests();
    if (!mounted || !pickedGuests) return;

    setState(() {
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAnimatedAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _buildAnimatedSection(
                    animation: _whereAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Where?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _whereController,
                          onChanged: (_) => setState(() => _selectedCategoryId = null),
                          onSubmitted: (_) => _startGuidedFlow(),
                          decoration: InputDecoration(
                            hintText: 'Search services or providers',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildAnimatedSection(
                    animation: _suggestedAnimation,
                    child: _SuggestedCategoriesSection(
                      onCategoryTap: (categoryId, name) {
                        setState(() {
                          _selectedCategoryId = categoryId;
                          _whereController.text = name;
                        });
                        _startGuidedFlow();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAnimatedSection(
                    animation: _whenAnimation,
                    child: _FormRow(
                      label: 'When',
                      value: _whenText,
                      onTap: _pickDates,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAnimatedSection(
                    animation: _whoAnimation,
                    child: _FormRow(
                      label: 'Who',
                      value: _whoText,
                      onTap: _pickGuests,
                    ),
                  ),
                  if (_showResults) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _SearchResultsSection(
                      whereQuery: _whereController.text.trim(),
                      selectedCategoryId: _selectedCategoryId,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildAnimatedBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: FadeTransition(
        opacity: _appBarAnimation,
        child: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      title: FadeTransition(
        opacity: _appBarAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(_appBarAnimation),
          child: Text(
            'Services',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: FadeTransition(
          opacity: _appBarAnimation,
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  Widget _buildAnimatedBottomBar() {
    return FadeTransition(
      opacity: _bottomBarAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(_bottomBarAnimation),
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'Clear all',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _onSearch,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text('Search'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loads categories from API and shows "Suggested categories" with taps to filter by category.
class _SuggestedCategoriesSection extends ConsumerWidget {
  const _SuggestedCategoriesSection({required this.onCategoryTap});

  final void Function(String categoryId, String name) onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested categories',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...categories.map((c) => _SuggestedCategoryTile(
                  name: c.name,
                  onTap: () => onCategoryTap(c.id, c.name),
                )),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested categories',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Center(child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          )),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: value.startsWith('Add') ? AppColors.textTertiary : AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultsSection extends ConsumerWidget {
  const _SearchResultsSection({
    required this.whereQuery,
    this.selectedCategoryId,
  });

  final String whereQuery;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When a category was tapped in suggestions, filter by category from API; otherwise search by query (API).
    final servicesAsync = selectedCategoryId != null
        ? ref.watch(servicesProvider(selectedCategoryId))
        : ref.watch(searchResultsProvider(whereQuery.isEmpty ? null : whereQuery));
    return servicesAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'No results found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final service = results[index];
                final isFav = ref.watch(isFavoriteProvider(service.id));
                return ServiceCard(
                  service: service,
                  onTap: () => context.push('/service/${service.id}'),
                  isFavorite: isFav,
                  onFavoriteTap: () async {
                    if (isFav) {
                      await removeFavorite(service.id);
                      ref.invalidate(favoritesIdsProvider);
                    } else {
                      await addServiceToFavorites(context, ref, service.id);
                    }
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('Could not load results', style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}
