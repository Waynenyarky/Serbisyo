import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Read-only star rating display that supports half stars.
class StarRating extends StatelessWidget {
  const StarRating({
    required this.rating,
    this.maxStars = 5,
    this.size = 16,
    this.spacing = 2,
    this.color = AppColors.warning,
    super.key,
  });

  final double rating;
  final int maxStars;
  final double size;
  final double spacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = rating.clamp(0, maxStars.toDouble());
    final stars = <Widget>[];
    for (var i = 0; i < maxStars; i++) {
      final filled = value >= i + 1;
      final half = !filled && value > i;
      stars.add(
        Icon(
          filled
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_border_rounded,
          size: size,
          color: color,
        ),
      );
      if (i < maxStars - 1) {
        stars.add(SizedBox(width: spacing));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
