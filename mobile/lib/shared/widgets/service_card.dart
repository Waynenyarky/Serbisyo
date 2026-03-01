import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/service_model.dart';
import 'premium_service_image.dart';

/// Premium card showing a service with hero image, title, rating, and price.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    super.key,
  });

  final ServiceModel service;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
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
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                      aspectRatio: 16 / 10,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? AppColors.error : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.rating}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          ' (${service.reviewCount} reviews)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
