import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = <_OnboardingItem>[
    _OnboardingItem(
      title: 'خدمات بيتك أقرب إليك',
      description:
          'اطلب أفضل الفنيين في الكهرباء والسباكة والنجارة والتنظيف والمزيد.',
      mainIcon: Icons.home_work_rounded,
      accentIcon: Icons.location_on_rounded,
      color: AppColors.powderBlue,
    ),
    _OnboardingItem(
      title: 'فنيين موثّقين وتقييمات حقيقية',
      description:
          'شاهد خبرة الفني وأعماله السابقة وتقييمات العملاء قبل إرسال الطلب.',
      mainIcon: Icons.verified_user_rounded,
      accentIcon: Icons.star_rounded,
      color: AppColors.powderGreen,
    ),
    _OnboardingItem(
      title: 'تابع طلبك خطوة بخطوة',
      description:
          'من قبول الفني للطلب وحتى وصوله وإتمام الخدمة، ستعرف كل التفاصيل.',
      mainIcon: Icons.route_rounded,
      accentIcon: Icons.handyman_rounded,
      color: AppColors.powderPeach,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _finish();
  }

  void _finish() {
    GetStorage().write('onboarding_done', true);
    final authService = context.read<AuthService>();
    if (authService.hasProviderSession) {
      context.go('/provider-login');
    } else {
      context.go(authService.hasCustomerSession ? '/main' : '/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const BrandLogo(compact: true, markSize: 40),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _finish();
                    },
                    child: const Text(
                      'تخطي',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) =>
                      _OnboardingPage(item: _pages[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (dotIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: dotIndex == _index ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotIndex == _index
                          ? AppColors.orange
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _index == _pages.length - 1 ? 'ابدأ مع Mazboot' : 'التالي',
                icon: Icons.arrow_back_rounded,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(item.mainIcon, size: 116, color: AppColors.navy),
              Positioned(
                left: 34,
                top: 42,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.accentIcon,
                    color: AppColors.orange,
                    size: 34,
                  ),
                ),
              ),
              Positioned(
                right: 25,
                bottom: 48,
                child: Container(
                  width: 32,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          item.description,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.mainIcon,
    required this.accentIcon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData mainIcon;
  final IconData accentIcon;
  final Color color;
}
