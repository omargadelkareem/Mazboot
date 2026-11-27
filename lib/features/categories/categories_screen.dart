import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/service_category.dart';
import '../home/home_cubit.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCubit>().state;
    final query = _query.trim();
    final categories = query.isEmpty
        ? home.categories
        : home.categories.where((category) {
            return category.name.contains(query) ||
                category.subtitle.contains(query);
          }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('كل الحرف والخدمات')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 13),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'دور على سباك، نجار، صيانة أجهزة…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  '${categories.length} خدمة متاحة',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'فنيون موثّقون',
                      style: TextStyle(color: AppColors.success, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Expanded(
            child: categories.isEmpty
                ? const _EmptySearch()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: categories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.13,
                        ),
                    itemBuilder: (_, index) {
                      final category = categories[index];
                      final count = home.technicians
                          .where(
                            (technician) =>
                                technician.categoryId == category.id &&
                                technician.canReceiveOrders,
                          )
                          .length;
                      return _CategoryCard(
                        category: category,
                        techniciansCount: count,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.techniciansCount});

  final ServiceCategory category;
  final int techniciansCount;

  @override
  Widget build(BuildContext context) {
    final dark = category.backgroundColor == AppColors.navy;
    final foreground = dark ? Colors.white : AppColors.navy;
    return InkWell(
      onTap: () => context.push('/technicians/${category.id}'),
      borderRadius: BorderRadius.circular(21),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: category.backgroundColor,
          borderRadius: BorderRadius.circular(21),
          border: dark ? null : Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -16,
              bottom: -18,
              child: Icon(
                category.icon,
                size: 98,
                color: foreground.withOpacity(0.1),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    category.icon,
                    color: dark ? AppColors.orange : foreground,
                    size: 23,
                  ),
                ),
                const Spacer(),
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  category.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withOpacity(0.62),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$techniciansCount فني متاح',
                  style: TextStyle(
                    color: dark ? AppColors.orange : AppColors.success,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 62, color: AppColors.textMuted),
          SizedBox(height: 9),
          Text('مفيش خدمة بالاسم ده حاليًا'),
        ],
      ),
    );
  }
}
