import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../auth/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthCubit>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status != AuthStatus.authenticated &&
            state.status != AuthStatus.unauthenticated) {
          return;
        }
        final box = GetStorage();
        final hasSeenOnboarding = box.read<bool>('onboarding_done') ?? false;
        final authService = context.read<AuthService>();
        if (!hasSeenOnboarding) {
          context.go('/onboarding');
        } else if (authService.hasProviderSession) {
          context.go('/provider-login');
        } else {
          context.go(
            authService.hasCustomerSession ? '/main' : '/role-selection',
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BrandLogo(markSize: 110),
                        SizedBox(height: 28),
                        Text(
                          AppConstants.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        _OrangeDivider(),
                      ],
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'خدمات بيتك في مكان واحد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrangeDivider extends StatelessWidget {
  const _OrangeDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
