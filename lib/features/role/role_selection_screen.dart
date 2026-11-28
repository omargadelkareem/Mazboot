import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../auth/auth_cubit.dart';
import '../provider/provider_auth_cubit.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectCustomer(BuildContext context) async {
    if (context.read<AuthService>().hasProviderSession) {
      await context.read<ProviderAuthCubit>().signOut();
    }
    await context.read<AuthService>().prepareForCustomer();
    if (context.mounted) context.go('/login');
  }

  Future<void> _selectProvider(BuildContext context) async {
    if (context.read<AuthService>().hasCustomerSession) {
      await context.read<AuthCubit>().signOut();
    }
    await context.read<AuthService>().prepareForProvider();
    if (context.mounted) context.go('/provider-login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Align(
                alignment: Alignment.centerRight,
                child: BrandLogo(compact: true, markSize: 44),
              ),
              const Spacer(),
              Text(
                'هتستخدم مظبوط إزاي؟',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'حساب العميل مستقل عن حساب الصنايعي، واختار دلوقتي هتدخل بأنهي واحد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 30),
              _RoleCard(
                title: 'أنا عميل',
                subtitle: 'عايز أطلب صنايعي وأتابع الخدمة',
                icon: Icons.home_rounded,
                onTap: () => _selectCustomer(context),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                title: 'أنا صنايعي',
                subtitle: 'دخول برقم الموبايل وكلمة المرور أو طلب انضمام',
                icon: Icons.handyman_rounded,
                onTap: () => _selectProvider(context),
              ),
              const Spacer(flex: 2),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'بياناتك مؤمّنة ومراجعة الصنايعية إلزامية',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
