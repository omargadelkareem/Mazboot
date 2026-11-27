import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/provider_application.dart';
import '../home/home_cubit.dart';
import 'provider_application_cubit.dart';
import 'provider_auth_cubit.dart';

class ProviderReviewScreen extends StatefulWidget {
  const ProviderReviewScreen({super.key});

  @override
  State<ProviderReviewScreen> createState() => _ProviderReviewScreenState();
}

class _ProviderReviewScreenState extends State<ProviderReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProviderApplicationCubit>().start();
      context.read<ProviderAuthCubit>().refresh();
    });
  }

  Future<void> _refresh() async {
    await context.read<ProviderApplicationCubit>().start();
    await context.read<ProviderAuthCubit>().refresh();
  }

  Future<void> _otherProviderAccount() async {
    await context.read<ProviderApplicationCubit>().stop();
    await context.read<ProviderAuthCubit>().signOut();
    if (mounted) context.go('/provider-login');
  }

  Future<void> _backToRoles() async {
    await context.read<ProviderApplicationCubit>().stop();
    await context.read<ProviderAuthCubit>().signOut();
    if (mounted) context.go('/role-selection');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderApplicationCubit>().state;
    if (state.loading && state.application == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final application = state.application;
    if (application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('طلب الانضمام')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.assignment_late_outlined,
                  size: 70,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 14),
                Text(
                  state.message ?? 'لم يتم العثور على طلب انضمام لهذا الحساب.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'إنشاء طلب جديد',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => context.go('/provider-join'),
                ),
                TextButton(
                  onPressed: _otherProviderAccount,
                  child: const Text('الدخول بحساب صنايعي آخر'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _ReviewContent(
      application: application,
      refreshing: state.loading,
      onRefresh: _refresh,
      onOtherAccount: _otherProviderAccount,
      onBackToRoles: _backToRoles,
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.application,
    required this.refreshing,
    required this.onRefresh,
    required this.onOtherAccount,
    required this.onBackToRoles,
  });

  final ProviderApplication application;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onOtherAccount;
  final Future<void> Function() onBackToRoles;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(application);
    final photo = context.read<ImageService>().decode(application.photoBase64);
    final category = context.read<HomeCubit>().state.categoryById(
      application.categoryId,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: <Widget>[
              const Align(
                alignment: Alignment.centerRight,
                child: BrandLogo(compact: true, markSize: 44),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 132,
                  height: 132,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: presentation.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    presentation.icon,
                    size: 68,
                    color: presentation.color,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                presentation.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 9),
              Text(
                presentation.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 31,
                      backgroundColor: AppColors.powderBlue,
                      backgroundImage: photo == null
                          ? null
                          : MemoryImage(photo),
                      child: photo == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: AppColors.navy,
                              size: 32,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            application.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            category?.name ?? 'الحرفة المختارة',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${application.governorate}، ${application.area}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: presentation.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        presentation.badge,
                        style: TextStyle(
                          color: presentation.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (application.reviewNote.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    application.reviewNote,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: application.isFullyActive
                    ? 'فتح لوحة الصنايعي'
                    : 'تحديث حالة الطلب',
                icon: application.isFullyActive
                    ? Icons.dashboard_rounded
                    : Icons.refresh_rounded,
                isLoading: refreshing,
                onPressed: refreshing
                    ? null
                    : application.isFullyActive
                    ? () async {
                        await onRefresh();
                        if (!context.mounted) return;
                        await context.read<ProviderApplicationCubit>().stop();
                        if (context.mounted) context.go('/provider/main');
                      }
                    : onRefresh,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: refreshing ? null : onOtherAccount,
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('الدخول بحساب صنايعي آخر'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              TextButton(
                onPressed: refreshing ? null : onBackToRoles,
                child: const Text('الرجوع لاختيار نوع الحساب'),
              ),
              const SizedBox(height: 5),
              const Text(
                'حساب الصنايعي مستقل عن حساب العميل؛ العميل يدخل بـ Google فقط.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _ReviewPresentation _presentation(ProviderApplication application) {
    if (application.status == ProviderApplicationStatus.rejected) {
      return const _ReviewPresentation(
        title: 'طلبك يحتاج مراجعة',
        description:
            'راجِع ملاحظة الإدارة وتواصل مع الدعم لتحديث بيانات الانضمام.',
        badge: 'مرفوض/تعديل',
        icon: Icons.error_outline_rounded,
        color: AppColors.danger,
        background: AppColors.powderPeach,
      );
    }
    if (application.status == ProviderApplicationStatus.approved &&
        !application.subscriptionActive) {
      return const _ReviewPresentation(
        title: 'تم قبول طلبك',
        description:
            'بياناتك اتراجعت بنجاح. متبقي تفعيل الاشتراك الشهري 50 جنيه لفتح لوحة الصنايعي والظهور للعملاء.',
        badge: 'مقبول',
        icon: Icons.verified_rounded,
        color: AppColors.success,
        background: AppColors.powderGreen,
      );
    }
    if (application.isFullyActive) {
      return const _ReviewPresentation(
        title: 'أهلًا بيك في مظبوط',
        description:
            'حسابك اتفعّل بالكامل. تقدر تدخل لوحة الصنايعي وتستقبل الطلبات وتتابع شغلك.',
        badge: 'نشط',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.success,
        background: AppColors.powderGreen,
      );
    }
    return const _ReviewPresentation(
      title: 'طلبك قيد المراجعة',
      description:
          'وصلتنا بياناتك وفريق مظبوط بيراجعها. ارجع بنفس رقم الموبايل وكلمة المرور لمتابعة النتيجة.',
      badge: 'قيد المراجعة',
      icon: Icons.manage_search_rounded,
      color: AppColors.orange,
      background: AppColors.orangeSoft,
    );
  }
}

class _ReviewPresentation {
  const _ReviewPresentation({
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final Color color;
  final Color background;
}
