import 'package:flutter/material.dart';

import '../../models/service_category.dart';
import '../theme/app_colors.dart';

/// Displays the bundled illustration for a service category and gracefully
/// falls back to the category icon when a new category has no local asset yet.
class CategoryImage extends StatelessWidget {
  const CategoryImage({
    super.key,
    required this.category,
    this.size = 56,
  });

  final ServiceCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.04),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withOpacity(0.55),
        borderRadius: borderRadius,
      ),
      child: Image.asset(
        'assets/images/categories/${category.id}.webp',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          category.icon,
          color: AppColors.primaryDark,
          size: size * 0.52,
        ),
      ),
    );
  }
}
