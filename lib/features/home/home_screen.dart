import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/remote_image.dart';
import '../../core/widgets/section_header.dart';
import '../../models/service_category.dart';
import '../../models/technician.dart';
import '../notifications/notifications_cubit.dart';
import '../profile/profile_cubit.dart';
import 'home_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedRoom = 0;

  static const _rooms = <_RoomOption>[
    _RoomOption(id: 'bathroom', label: 'الحمام', icon: Icons.bathroom_rounded),
    _RoomOption(id: 'kitchen', label: 'المطبخ', icon: Icons.kitchen_rounded),
    _RoomOption(id: 'living', label: 'غرفة', icon: Icons.weekend_rounded),
    _RoomOption(
      id: 'appliances',
      label: 'أجهزة',
      icon: Icons.devices_other_rounded,
    ),
  ];

  void _openCategory(ServiceCategory category) {
    context.push('/technicians/${category.id}');
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeCubit>().state;
    final profile = context.watch<ProfileCubit>().state.profile;
    final unreadCount = context.watch<NotificationsCubit>().state.unreadCount;
    final location = profile?.locationLabel ?? 'حدد موقعك';
    final roomId = _rooms[_selectedRoom].id;
    final matchingCategories = homeState.categories
        .where((category) => category.roomIds.contains(roomId))
        .toList();
    final otherCategories = homeState.categories
        .where((category) => !category.roomIds.contains(roomId))
        .toList();
    final categories = [...matchingCategories, ...otherCategories];

    if (homeState.loading && categories.isEmpty) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 112),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: _TopBar(
                location: location,
                customerName: profile?.name ?? 'عميل Mazboot',
                unreadCount: unreadCount,
              ),
            ),
            const _ProblemHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'المشكلة فين؟',
                    actionLabel: 'عرض الكل',
                    onAction: () => context.push('/categories'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 106,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (_, index) {
                        final selected = _selectedRoom == index;
                        return _RoomCard(
                          option: _rooms[index],
                          selected: selected,
                          onTap: () => setState(() => _selectedRoom = index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'اختار الحرفة',
                    actionLabel: 'كل الحرف',
                    onAction: () => context.push('/categories'),
                  ),
                  const SizedBox(height: 12),
                  if (categories.length >= 6)
                    SizedBox(
                      height: 324,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _BentoCategoryTile(
                              category: categories[1],
                              largeIcon: true,
                              onTap: () => _openCategory(categories[1]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _BentoCategoryTile(
                                    category: categories[0],
                                    dark: true,
                                    horizontal: true,
                                    onTap: () => _openCategory(categories[0]),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _BentoCategoryTile(
                                          category: categories[2],
                                          compact: true,
                                          onTap: () =>
                                              _openCategory(categories[2]),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _BentoCategoryTile(
                                          category: categories[3],
                                          compact: true,
                                          onTap: () =>
                                              _openCategory(categories[3]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _BentoCategoryTile(
                                          category: categories[4],
                                          compact: true,
                                          onTap: () =>
                                              _openCategory(categories[4]),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _BentoCategoryTile(
                                          category: categories[5],
                                          compact: true,
                                          onTap: () =>
                                              _openCategory(categories[5]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _CompactCategories(
                      categories: categories,
                      onTap: _openCategory,
                    ),
                  const SizedBox(height: 24),
                  _NearbyCard(
                    technicians: homeState.technicians,
                    onTap: () => context.push('/categories'),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.location,
    required this.customerName,
    required this.unreadCount,
  });

  final String location;
  final String customerName;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandLogo(compact: true, markSize: 40),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => context.push('/location'),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.navy,
                    size: 21,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.push('/notifications'),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.navy,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.powderPeach,
          child: Text(
            customerName.trim().isEmpty ? 'ح' : customerName.trim()[0],
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProblemHero extends StatelessWidget {
  const _ProblemHero();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeroClipper(),
      child: CustomPaint(
        painter: _BlueprintPainter(),
        child: Container(
          height: 264,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
          color: AppColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'إيه اللي محتاج '),
                    TextSpan(
                      text: 'يتظبط؟',
                      style: TextStyle(color: AppColors.orange),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () => context.push('/categories'),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/categories'),
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.navy,
                        ),
                      ),
                      Container(width: 1, height: 28, color: AppColors.border),
                      const Expanded(
                        child: Text(
                          'اكتب، اتكلم أو صوّر المشكلة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => UiUtils.showSnackBar(
                          context,
                          'اختار الحرفة والفني الأول، وبعدها اكتب أو صوّر المشكلة.',
                        ),
                        icon: const Icon(
                          Icons.mic_none_rounded,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: FilledButton.icon(
                  onPressed: () => context.push('/technicians/electricity'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 19),
                  label: const Text('طلب عاجل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _RoomOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.orangeSoft : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                color: selected ? AppColors.orange : AppColors.navy,
                size: 34,
              ),
              const SizedBox(height: 7),
              Text(
                option.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCategoryTile extends StatelessWidget {
  const _BentoCategoryTile({
    required this.category,
    required this.onTap,
    this.dark = false,
    this.compact = false,
    this.horizontal = false,
    this.largeIcon = false,
  });

  final ServiceCategory category;
  final VoidCallback onTap;
  final bool dark;
  final bool compact;
  final bool horizontal;
  final bool largeIcon;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppColors.navy;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: dark ? AppColors.navy : category.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: dark
                ? null
                : Border.all(color: AppColors.border.withOpacity(0.7)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -12,
                bottom: -18,
                child: Icon(
                  category.icon,
                  size: largeIcon
                      ? 142
                      : compact
                          ? 74
                          : 102,
                  color: foreground.withOpacity(dark ? 0.12 : 0.13),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 10 : 15),
                child: horizontal
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              category.icon,
                              color: AppColors.orange,
                              size: 27,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            category.icon,
                            color: foreground,
                            size: compact ? 24 : 33,
                          ),
                          const Spacer(),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: foreground,
                              fontSize: compact ? 13 : 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!compact)
                            Text(
                              category.subtitle,
                              style: TextStyle(
                                color: foreground.withOpacity(0.65),
                                fontSize: 10,
                              ),
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

class _CompactCategories extends StatelessWidget {
  const _CompactCategories({required this.categories, required this.onTap});

  final List<ServiceCategory> categories;
  final ValueChanged<ServiceCategory> onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        height: 126,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'لسه مفيش خدمات منشورة. استورد ملف البيانات التجريبية في Firebase.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (_, index) {
        final category = categories[index];
        return _BentoCategoryTile(
          category: category,
          compact: true,
          onTap: () => onTap(category),
        );
      },
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.technicians, required this.onTap});

  final List<Technician> technicians;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visibleTechnicians = technicians
        .where((item) => item.isAvailable && item.canReceiveOrders)
        .take(3)
        .toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${visibleTechnicians.length} ',
                          style: const TextStyle(color: AppColors.orange),
                        ),
                        const TextSpan(text: 'فنيين متاحين\nحوالين بيتك'),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.success),
                      SizedBox(width: 5),
                      Text(
                        'متاح الآن',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text(
                        'شوفهم على الخريطة',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 11,
                        color: AppColors.navy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 155,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(painter: _MiniMapPainter()),
                    ),
                  ),
                  for (var index = 0;
                      index < visibleTechnicians.length;
                      index++)
                    Positioned(
                      left: 18 + (index * 36),
                      top: 46,
                      child: Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            RemoteImage(
                              url: visibleTechnicians[index].imageUrl,
                              base64Data: visibleTechnicians[index].imageBase64,
                              width: 50,
                              height: 50,
                              borderRadius: 30,
                            ),
                            const Positioned(
                              bottom: -2,
                              right: -2,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _RoomOption {
  const _RoomOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class _HeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 30)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 22,
        0,
        size.height - 30,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final orange = Paint()
      ..color = AppColors.orange.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var index = 0; index < 7; index++) {
      final offset = index * 48.0;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + 70, size.height),
        blue,
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width - offset - 90, 18 + (index * 10), 62, 44),
        orange,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final streets = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final route = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = -2; i < 8; i++) {
      canvas.drawLine(
        Offset(0, i * 26.0),
        Offset(size.width, (i * 26.0) + 62),
        streets,
      );
      canvas.drawLine(
        Offset(i * 36.0, 0),
        Offset((i * 36.0) + 48, size.height),
        streets,
      );
    }
    final path = Path()
      ..moveTo(12, size.height - 20)
      ..lineTo(46, size.height - 45)
      ..lineTo(78, size.height - 38)
      ..lineTo(110, 30)
      ..lineTo(size.width - 12, 20);
    canvas.drawPath(path, route);
    canvas.drawCircle(
      Offset(size.width - 12, 20),
      6,
      Paint()..color = AppColors.orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
