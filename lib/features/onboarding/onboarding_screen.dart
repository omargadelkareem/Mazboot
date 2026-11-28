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
    ),
    _OnboardingItem(
      title: 'فنيين موثّقين وتقييمات حقيقية',
      description:
          'شاهد خبرة الفني وأعماله السابقة وتقييمات العملاء قبل إرسال الطلب.',
      mainIcon: Icons.verified_user_rounded,
      accentIcon: Icons.star_rounded,
    ),
    _OnboardingItem(
      title: 'تابع طلبك خطوة بخطوة',
      description:
          'من قبول الفني للطلب وحتى وصوله وإتمام الخدمة، ستعرف كل التفاصيل.',
      mainIcon: Icons.route_rounded,
      accentIcon: Icons.handyman_rounded,
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
                label: _index == _pages.length - 1 ? 'ابدأ مع مظبوط' : 'التالي',
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
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              PositionedDirectional(
                top: -54,
                end: -45,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.52),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.ink.withOpacity(0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  item.mainIcon,
                  size: 67,
                  color: AppColors.primaryDark,
                ),
              ),
              Positioned(
                left: 42,
                top: 48,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    item.accentIcon,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
              ),
              const PositionedDirectional(
                start: 24,
                bottom: 24,
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'خدمة موثوقة',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
  });

  final String title;
  final String description;
  final IconData mainIcon;
  final IconData accentIcon;
}
