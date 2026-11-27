import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.primary,
            size: 15,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            const Text(
              'موثّق',
              style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
            ),
          ],
        ],
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.reviews});

  final double rating;
  final int? reviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppColors.warning, size: 17),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        if (reviews != null)
          Text(
            ' ($reviews)',
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
      ],
    );
  }
}

class AvailabilityChip extends StatelessWidget {
  const AvailabilityChip({super.key, required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            available ? 'متاح الآن' : 'متاح غدًا',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
