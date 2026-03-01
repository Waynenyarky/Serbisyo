import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/service_category.dart';

/// Premium horizontal chip with gradient and icon per category.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.category,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final ServiceCategory category;
  final VoidCallback onTap;
  final bool isSelected;

  static const Map<String, IconData> _categoryIcons = {
    'Plumbing': Icons.plumbing_rounded,
    'Gardening': Icons.eco_rounded,
    'Housekeeping': Icons.cleaning_services_rounded,
    'Repairs': Icons.build_rounded,
    'Electrical': Icons.electrical_services_rounded,
    'Moving': Icons.local_shipping_rounded,
    'Pet Care': Icons.pets_rounded,
    'Beauty & Wellness': Icons.spa_rounded,
  };

  static const Map<String, List<Color>> _categoryGradients = {
    'Plumbing': [Color(0xFF0D9488), Color(0xFF14B8A6)],
    'Gardening': [Color(0xFF059669), Color(0xFF10B981)],
    'Housekeeping': [Color(0xFF0891B2), Color(0xFF06B6D4)],
    'Repairs': [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    'Electrical': [Color(0xFFEAB308), Color(0xFFFACC15)],
    'Moving': [Color(0xFFEA580C), Color(0xFFF97316)],
    'Pet Care': [Color(0xFFDB2777), Color(0xFFEC4899)],
    'Beauty & Wellness': [Color(0xFFBE185D), Color(0xFFD946EF)],
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category.name] ?? Icons.category_rounded;
    final gradientColors = _categoryGradients[category.name] ??
        [AppColors.primary, AppColors.primaryLight];
    final colors = isSelected
        ? [
            gradientColors[0].withValues(alpha: 0.9),
            gradientColors[1].withValues(alpha: 0.9),
          ]
        : [
            gradientColors[0].withValues(alpha: 0.12),
            gradientColors[1].withValues(alpha: 0.06),
          ];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppColors.primary : Colors.black)
                        .withValues(alpha: isSelected ? 0.2 : 0.06),
                    blurRadius: isSelected ? 10 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 36,
                        color: isSelected
                            ? Colors.white
                            : AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
