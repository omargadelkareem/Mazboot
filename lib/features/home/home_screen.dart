import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/category_image.dart';
import '../../core/widgets/remote_image.dart';
import '../../core/widgets/section_header.dart';
import '../../models/service_category.dart';
import '../../models/technician.dart';
import '../notifications/notifications_cubit.dart';
import '../profile/profile_cubit.dart';
import 'home_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCubit>().state;
    final profile = context.watch<ProfileCubit>().state.profile;
    final unreadCount = context.watch<NotificationsCubit>().state.unreadCount;
    final categories = home.categories.take(8).toList();
    final technicians = home.technicians
        .where((item) => item.isAvailable && item.canReceiveOrders)
        .take(6)
        .toList();

    if (home.loading && categories.isEmpty && technicians.isEmpty) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
        children: <Widget>[
          _TopBar(
            location: profile?.locationLabel ?? 'حدد موقعك',
            unreadCount: unreadCount,
          ),
          const SizedBox(height: 26),
          const Text(
            'بيتك دايمًا مظبوط',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 29,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'كل خدمات البيت الموثوقة في مكان واحد',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _SearchBox(onTap: () => context.push('/categories')),
          const SizedBox(height: 14),
          _QuickRequestCard(onTap: () => context.push('/categories')),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'الخدمات الأكثر طلبًا',
            actionLabel: 'عرض الكل',
            onAction: () => context.push('/categories'),
          ),
          const SizedBox(height: 13),
          _ServicesGrid(
            categories: categories,
            onTap: (category) =>
                context.push('/technicians/${category.id}'),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'فنيين موثوقين',
            actionLabel: 'عرض الكل',
            onAction: () => context.push('/categories'),
          ),
          const SizedBox(height: 13),
          _TechniciansStrip(technicians: technicians),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.location, required this.unreadCount});

  final String location;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const BrandLogo(compact: true, markSize: 36),
        const Spacer(),
        InkWell(
          onTap: () => context.push('/location'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 105),
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => context.push('/notifications'),
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.text,
                  size: 22,
                ),
              ),
              if (unreadCount > 0)
                PositionedDirectional(
                  end: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.ink.withOpacity(0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بتدور على إيه؟',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.tune_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRequestCard extends StatelessWidget {
  const _QuickRequestCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'طلب خدمة سريع',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'اختار الخدمة وحدد الموعد المناسب ليك',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.categories, required this.onTap});

  final List<ServiceCategory> categories;
  final ValueChanged<ServiceCategory> onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.home_repair_service_outlined,
        message: 'الخدمات هتظهر هنا بعد نشرها من لوحة التحكم.',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemBuilder: (_, index) {
        final category = categories[index];
        return _ServiceCard(
          category: category,
          onTap: () => onTap(category),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.category, required this.onTap});

  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 11, 7, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CategoryImage(category: category, size: 54),
              const SizedBox(height: 8),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechniciansStrip extends StatelessWidget {
  const _TechniciansStrip({required this.technicians});

  final List<Technician> technicians;

  @override
  Widget build(BuildContext context) {
    if (technicians.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.engineering_outlined,
        message: 'هنعرض لك الفنيين المتاحين فور اعتماد حساباتهم.',
      );
    }
    return SizedBox(
      height: 244,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: technicians.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) =>
            _TechnicianPreviewCard(technician: technicians[index]),
      ),
    );
  }
}

class _TechnicianPreviewCard extends StatelessWidget {
  const _TechnicianPreviewCard({required this.technician});

  final Technician technician;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 218,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/technician/${technician.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    RemoteImage(
                      url: technician.imageUrl,
                      base64Data: technician.imageBase64,
                      width: double.infinity,
                      height: 116,
                      borderRadius: 17,
                    ),
                    if (technician.isVerified)
                      PositionedDirectional(
                        end: 10,
                        top: 10,
                        child: Container(
                          width: 27,
                          height: 27,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          technician.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          technician.profession,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              technician.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              technician.visitFee > 0
                                  ? 'من ${technician.visitFee} ج.م'
                                  : 'السعر بالاتفاق',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.primary, size: 34),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
