import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/service_model.dart';
import 'premium_service_image.dart';
import 'star_rating.dart';

/// Premium card showing a service with hero image, title, rating, and price.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.dense = false,
    this.imageAspectRatio = 16 / 10,
    super.key,
  });

  final ServiceModel service;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  /// Compact layout for grid tiles and small screens.
  final bool dense;

  /// Image ratio for the card header (width / height).
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context) {
    final titleStyle = dense
        ? Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final pad = dense ? 10.0 : AppSpacing.md;
    final titleMaxLines = dense ? 2 : 1;
    final vGap = dense ? 4.0 : 6.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: dense ? 10 : 12,
                offset: dense ? const Offset(0, 3) : const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusLg),
                    ),
                    child: AspectRatio(
                      aspectRatio: imageAspectRatio,
                      child: PremiumServiceImage(
                        width: double.infinity,
                        height: double.infinity,
                        imageUrl: service.imageUrl,
                      ),
                    ),
                  ),
                  if (onFavoriteTap != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onFavoriteTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(dense ? 7 : 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? AppColors.error
                                  : Colors.white,
                              size: dense ? 20 : 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: titleStyle,
                      maxLines: titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: vGap),
                    Row(
                      children: [
                        StarRating(
                          rating: service.rating,
                          size: dense ? 14 : 16,
                          spacing: 0,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          dense
                              ? ' (${service.reviewCount})'
                              : ' (${service.reviewCount} reviews)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    SizedBox(height: vGap),
                    Text(
                      '₱${service.pricePerHour.toStringAsFixed(0)}/hr · ${service.providerName}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
