import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../models/service_order.dart';
import '../auth/auth_cubit.dart';
import '../favorites/favorites_cubit.dart';
import '../orders/orders_cubit.dart';
import 'profile_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    final profile = profileState.profile;
    final orders = context.watch<OrdersCubit>().state.orders;
    final favorites = context.watch<FavoritesCubit>().state.ids;
    final avatar = context.read<ImageService>().decode(profile?.avatarBase64);
    final avatarUrl = profile?.avatarUrl;
    if (profileState.loading && profile == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : 'عميل Mazboot';
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('حسابي', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              const BrandLogo(compact: true, markSize: 40),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: avatar != null
                      ? Image.memory(
                          avatar,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                        )
                      : avatarUrl?.isNotEmpty == true
                      ? Image.network(
                          avatarUrl!,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : Text(
                          name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        profile?.phone.isNotEmpty == true
                            ? profile!.phone
                            : profile?.email ?? '',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                              profile?.locationLabel ?? 'حدد موقعك',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/edit-profile'),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickStat(
                  icon: Icons.home_repair_service_outlined,
                  value: '${orders.length}',
                  label: 'طلبات',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _QuickStat(
                  icon: Icons.favorite_border_rounded,
                  value: '${favorites.length}',
                  label: 'مفضلة',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _QuickStat(
                  icon: Icons.check_circle_outline_rounded,
                  value:
                      '${orders.where((item) => item.status == ServiceOrderStatus.completed).length}',
                  label: 'مكتملة',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel('البيت والحساب'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: <Widget>[
              _MenuTile(
                icon: Icons.location_on_outlined,
                title: 'العناوين المحفوظة',
                subtitle: '${profile?.addresses.length ?? 0} عنوان',
                onTap: () => context.push('/addresses'),
              ),
              _MenuTile(
                icon: Icons.favorite_border_rounded,
                title: 'الفنيون المفضّلون',
                subtitle: '${favorites.length} فني',
                onTap: () => context.push('/favorites'),
              ),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'طريقة الدفع',
                subtitle: 'الدفع بعد إتمام الخدمة',
                onTap: () => _showPaymentInfo(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('المساعدة والإعدادات'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: <Widget>[
              _MenuTile(
                icon: Icons.support_agent_rounded,
                title: 'مركز المساعدة',
                onTap: () => context.push('/support'),
              ),
              _MenuTile(
                icon: Icons.notifications_none_rounded,
                title: 'الإشعارات',
                onTap: () => context.push('/notifications'),
              ),
              _MenuTile(
                icon: Icons.shield_outlined,
                title: 'الخصوصية والشروط',
                onTap: () => context.push('/legal'),
              ),
              _MenuTile(
                icon: Icons.swap_horiz_rounded,
                title: 'الدخول كصنايعي',
                subtitle: 'حساب منفصل برقم الموبايل وكلمة المرور',
                onTap: () => _switchToProvider(context),
              ),
              _MenuTile(
                icon: Icons.info_outline_rounded,
                title: 'عن Mazboot',
                subtitle: 'الإصدار 1.2.0',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Mazboot',
                  applicationVersion: '1.2.0',
                  applicationLegalese: 'خدمات بيتك بشكل مظبوط',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('تسجيل الخروج'),
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

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('متأكد إنك عايز تسجل خروج من حساب العميل؟'),
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
    await context.read<AuthCubit>().signOut();
    if (context.mounted) context.go('/role-selection');
  }

  Future<void> _switchToProvider(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الدخول كصنايعي'),
        content: const Text(
          'حساب الصنايعي منفصل تمامًا. هنسجل خروج من حساب Google وبعدها تدخل برقم الموبايل وكلمة المرور.',
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
    await context.read<AuthCubit>().signOut();
    await context.read<AuthService>().prepareForProvider();
    if (context.mounted) context.go('/provider-login');
  }

  void _showPaymentInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'الدفع في Mazboot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text(
              'لا توجد رسوم معاينة أو رسوم مسبقة داخل التطبيق. اتفق على سعر تنفيذ الخدمة مع الفني داخل المحادثة قبل بدء العمل.',
              style: TextStyle(color: AppColors.textMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.orange, size: 21),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
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
        children: List<Widget>.generate(children.length * 2 - 1, (index) {
          if (index.isOdd) return const Divider(height: 1, indent: 58);
          return children[index ~/ 2];
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
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
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
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
      trailing: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 14,
        color: AppColors.textMuted,
      ),
    );
  }
}
