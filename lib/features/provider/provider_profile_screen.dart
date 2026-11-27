import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/provider_application.dart';
import '../../models/technician.dart';
import 'provider_auth_cubit.dart';
import 'provider_application_cubit.dart';
import 'provider_workspace_cubit.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderWorkspaceCubit>().state;
    final profile = state.profile;
    final application = context.watch<ProviderAuthCubit>().state.application;
    if (state.loading && profile == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (profile == null) {
      return const SafeArea(child: Center(child: Text('تعذر تحميل الحساب.')));
    }
    final image = context.read<ImageService>().decode(profile.imageBase64);
    final name = profile.name.isEmpty ? 'صنايعي مظبوط' : profile.name;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'حساب الصنايعي',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () => context.push('/provider/edit-profile'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: image == null
                          ? Text(
                              name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : Image.memory(
                              image,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (profile.isVerified) ...<Widget>[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.orange,
                                  size: 19,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            profile.profession,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.orange,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${profile.area}، ${profile.governorate}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ProfileStat(
                        value: profile.rating.toStringAsFixed(1),
                        label: 'التقييم',
                        icon: Icons.star_rounded,
                      ),
                    ),
                    Expanded(
                      child: _ProfileStat(
                        value: '${profile.reviewsCount}',
                        label: 'تقييم عميل',
                        icon: Icons.reviews_outlined,
                      ),
                    ),
                    Expanded(
                      child: _ProfileStat(
                        value: '${state.completed.length}',
                        label: 'طلبات مكتملة',
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SubscriptionSummary(application: application, profile: profile),
          const SizedBox(height: 20),
          const _SectionLabel('إدارة الشغل'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: <Widget>[
              _MenuTile(
                icon: Icons.edit_note_rounded,
                title: 'تعديل الملف المهني',
                subtitle: 'النبذة والخبرة والخدمات',
                onTap: () => context.push('/provider/edit-profile'),
              ),
              _MenuTile(
                icon: Icons.visibility_outlined,
                title: 'ظهور الملف للعملاء',
                subtitle: profile.isAvailable
                    ? 'متاح لاستقبال طلبات'
                    : 'استقبال الطلبات متوقف',
                trailing: Switch.adaptive(
                  value: profile.isAvailable,
                  onChanged: state.saving
                      ? null
                      : context.read<ProviderWorkspaceCubit>().setAvailability,
                ),
              ),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'التحصيل والأرباح',
                subtitle: 'الدفع يتم مباشرة بينك وبين العميل',
                onTap: () => _showEarningsInfo(context, state.completed.length),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('المساعدة والحساب'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: <Widget>[
              _MenuTile(
                icon: Icons.support_agent_rounded,
                title: 'الدعم والمساعدة',
                onTap: () => context.push('/support'),
              ),
              _MenuTile(
                icon: Icons.shield_outlined,
                title: 'الخصوصية والشروط',
                onTap: () => context.push('/legal'),
              ),
              _MenuTile(
                icon: Icons.swap_horiz_rounded,
                title: 'الدخول كتطبيق العميل',
                subtitle: 'هتخرج من حساب الصنايعي وتدخل بـ Google',
                onTap: () => _switchToCustomer(context),
              ),
            ],
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('تسجيل الخروج من حساب الصنايعي'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchToCustomer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الدخول كتطبيق العميل'),
        content: const Text(
          'حساب العميل مستقل تمامًا. هنسجل خروج من حساب الصنايعي وبعدها تدخل بحساب Google.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ProviderWorkspaceCubit>().stop();
    await context.read<ProviderApplicationCubit>().stop();
    await context.read<ProviderAuthCubit>().signOut();
    await context.read<AuthService>().prepareForCustomer();
    if (context.mounted) context.go('/login');
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('متأكد إنك عايز تخرج من حساب الصنايعي؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ProviderWorkspaceCubit>().stop();
    await context.read<ProviderApplicationCubit>().stop();
    await context.read<ProviderAuthCubit>().signOut();
    if (context.mounted) context.go('/role-selection');
  }

  void _showEarningsInfo(BuildContext context, int completed) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'التحصيل والأرباح',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.powderGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.task_alt_rounded, color: AppColors.success),
                  const SizedBox(width: 9),
                  Text(
                    '$completed خدمة مكتملة على التطبيق',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'مظبوط لا تخصم عمولة من سعر الشغل ولا تسجل المبلغ المتفق عليه. اتفق مع العميل داخل المحادثة واستلم المقابل منه مباشرة بعد الخدمة.',
              style: TextStyle(color: AppColors.textMuted, height: 1.65),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({
    required this.application,
    required this.profile,
  });

  final ProviderApplication? application;
  final Technician profile;

  @override
  Widget build(BuildContext context) {
    final applicationExpiry = application?.subscriptionExpiresAt ?? 0;
    final expiresAt = applicationExpiry > 0
        ? applicationExpiry
        : profile.subscriptionExpiresAt;
    final expiry = expiresAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(expiresAt)
        : null;
    final active = profile.subscriptionActive;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: active ? AppColors.powderGreen : AppColors.powderPeach,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(
              active ? Icons.workspace_premium_rounded : Icons.warning_rounded,
              color: active ? AppColors.success : AppColors.orange,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  active ? 'اشتراكك فعّال' : 'اشتراكك غير فعّال',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  expiry == null
                      ? '50 جنيه شهريًا'
                      : 'صالح حتى ${expiry.day}/${expiry.month}/${expiry.year}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '50 ج.م',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, color: AppColors.orange, size: 19),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 8),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List<Widget>.generate(children.length, (index) {
          return Column(
            children: <Widget>[
              children[index],
              if (index < children.length - 1)
                const Divider(height: 1, indent: 62),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.powderBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.navy, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : const Icon(Icons.arrow_back_ios_new_rounded, size: 14)),
    );
  }
}
