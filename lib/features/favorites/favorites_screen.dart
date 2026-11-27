import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_chips.dart';
import '../../core/widgets/remote_image.dart';
import '../../models/technician.dart';
import '../home/home_cubit.dart';
import 'favorites_cubit.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteIds = context.watch<FavoritesCubit>().state.ids;
    final technicians = context
        .watch<HomeCubit>()
        .state
        .technicians
        .where((item) => favoriteIds.contains(item.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('الفنيون المفضّلون')),
      body: technicians.isEmpty
          ? const _EmptyFavorites()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: technicians.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) =>
                  _FavoriteCard(technician: technicians[index]),
            ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.technician});

  final Technician technician;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/technician/${technician.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            RemoteImage(
              url: technician.imageUrl,
              base64Data: technician.imageBase64,
              width: 76,
              height: 82,
              borderRadius: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          technician.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (technician.isVerified) ...<Widget>[
                        const SizedBox(width: 4),
                        const VerifiedBadge(),
                      ],
                    ],
                  ),
                  Text(
                    technician.profession,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: <Widget>[
                      RatingBadge(
                        rating: technician.rating,
                        reviews: technician.reviewsCount,
                      ),
                      const Spacer(),
                      AvailabilityChip(available: technician.isAvailable),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  context.read<FavoritesCubit>().toggle(technician.id),
              icon: const Icon(Icons.favorite_rounded, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.favorite_border_rounded,
            size: 68,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text('احفظ الفنيين اللي ارتحت في التعامل معاهم'),
        ],
      ),
    );
  }
}
