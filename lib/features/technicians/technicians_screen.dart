import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_chips.dart';
import '../../core/widgets/remote_image.dart';
import '../../models/technician.dart';
import '../favorites/favorites_cubit.dart';
import '../home/home_cubit.dart';
import '../profile/profile_cubit.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  int _sortIndex = 0;
  bool _availableOnly = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCubit>().state;
    final category = home.categoryById(widget.categoryId);
    final location =
        context.watch<ProfileCubit>().state.profile?.locationLabel ??
        'حدد موقعك';
    var technicians = home.technicians
        .where((item) => item.categoryId == widget.categoryId)
        .where((item) => item.canReceiveOrders)
        .where((item) => !_availableOnly || item.isAvailable)
        .where(
          (item) =>
              _query.isEmpty ||
              item.name.contains(_query) ||
              item.profession.contains(_query),
        )
        .toList();
    technicians.sort((first, second) {
      if (_sortIndex == 1) return second.rating.compareTo(first.rating);
      return first.distanceKm.compareTo(second.distanceKm);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == null ? 'الفنيون' : 'فنيين ${category.name}',
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 11),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'ابحث باسم الفني أو تخصصه',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _FilterButton(
                    label: 'الأقرب',
                    selected: _sortIndex == 0,
                    icon: Icons.near_me_outlined,
                    onTap: () => setState(() => _sortIndex = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'الأعلى تقييمًا',
                    selected: _sortIndex == 1,
                    icon: Icons.star_outline_rounded,
                    onTap: () => setState(() => _sortIndex = 1),
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  label: 'متاح',
                  selected: _availableOnly,
                  icon: Icons.tune_rounded,
                  onTap: () => setState(() => _availableOnly = !_availableOnly),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  '${technicians.length} فني',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: home.loading
                ? const Center(child: CircularProgressIndicator())
                : technicians.isEmpty
                ? const _EmptyTechnicians()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: technicians.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 11),
                    itemBuilder: (_, index) =>
                        _TechnicianCard(technician: technicians[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.primaryDark,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.technician});

  final Technician technician;

  @override
  Widget build(BuildContext context) {
    final favorite = context.watch<FavoritesCubit>().state.contains(
      technician.id,
    );
    return InkWell(
      onTap: () => context.push('/technician/${technician.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RemoteImage(
              url: technician.imageUrl,
              base64Data: technician.imageBase64,
              width: 96,
              height: 116,
              borderRadius: 15,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          technician.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        onPressed: () => context.read<FavoritesCubit>().toggle(
                          technician.id,
                        ),
                        icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite
                              ? AppColors.danger
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      if (technician.isVerified) const VerifiedBadge(),
                    ],
                  ),
                  Text(
                    technician.profession,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: <Widget>[
                      RatingBadge(
                        rating: technician.rating,
                        reviews: technician.reviewsCount,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.work_outline_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${technician.completedJobs}+ عمل',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          technician.area.isNotEmpty
                              ? technician.area
                              : '${technician.distanceKm} كم',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      AvailabilityChip(available: technician.isAvailable),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          technician.visitFee > 0
                              ? 'يبدأ من ${technician.visitFee} ج.م'
                              : 'السعر بالاتفاق',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Text(
                          'عرض الملف',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTechnicians extends StatelessWidget {
  const _EmptyTechnicians();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.person_search_rounded,
            size: 70,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text('لا يوجد فنيون متاحون بهذا الفلتر'),
        ],
      ),
    );
  }
}
