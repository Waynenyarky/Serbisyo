import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/favorites_storage.dart';
import '../../core/providers/api_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

const int _kNameMaxLength = 50;

/// If the user has no favorite list yet, shows the "Create a favorite" sheet. Otherwise adds the service to the existing list and shows a snackbar.
Future<void> addServiceToFavorites(
  BuildContext context,
  WidgetRef ref,
  String serviceId,
) async {
  final noListYet = await hasNoFavoriteListYet();
  if (noListYet) {
    await showCreateFavoriteSheet(
      context,
      serviceId: serviceId,
      onCreated: () {
        ref.invalidate(favoritesIdsProvider);
        ref.invalidate(favoriteListNameProvider);
      },
    );
  } else {
    await addFavorite(serviceId);
    ref.invalidate(favoritesIdsProvider);
    if (context.mounted) {
      final name = await getFavoriteListName();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to ${name ?? 'Favorites'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Shows a bottom sheet with curved top: "Create a favorite", Name field (50 chars), Cancel and Create.
/// Only call this when the user has no favorite list yet; otherwise use [addServiceToFavorites].
Future<void> showCreateFavoriteSheet(
  BuildContext context, {
  required String serviceId,
  required VoidCallback onCreated,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CreateFavoriteSheetContent(
      serviceId: serviceId,
      onCreated: onCreated,
    ),
  );
}

class _CreateFavoriteSheetContent extends StatefulWidget {
  const _CreateFavoriteSheetContent({
    required this.serviceId,
    required this.onCreated,
  });

  final String serviceId;
  final VoidCallback onCreated;

  @override
  State<_CreateFavoriteSheetContent> createState() => _CreateFavoriteSheetContentState();
}

class _CreateFavoriteSheetContentState extends State<_CreateFavoriteSheetContent> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final name = _nameController.text.trim();
    final listName = name.isEmpty ? 'Saved' : name;
    await setFavoriteListName(listName);
    await addFavorite(widget.serviceId);
    if (!mounted) return;
    widget.onCreated();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Create a favorite',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameController,
            focusNode: _focusNode,
            maxLength: _kNameMaxLength,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Plumbers to call',
              counterText: '${_nameController.text.length}/$_kNameMaxLength',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    side: BorderSide(color: AppColors.divider),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
