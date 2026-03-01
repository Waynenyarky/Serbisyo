import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Premium service image: network with cache, or gradient placeholder with icon.
class PremiumServiceImage extends StatelessWidget {
  const PremiumServiceImage({
    required this.width,
    required this.height,
    this.imageUrl,
    this.icon = Icons.home_repair_service_rounded,
    this.fit = BoxFit.cover,
    super.key,
  });

  final double width;
  final double height;
  final String? imageUrl;
  final IconData icon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    if (hasValidUrl) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _gradientPlaceholder(),
        errorWidget: (context, url, error) => _gradientPlaceholder(),
      );
    }
    return _gradientPlaceholder();
  }

  Widget _gradientPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primaryLight.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 56, color: AppColors.primary.withValues(alpha: 0.6)),
      ),
    );
  }
}
