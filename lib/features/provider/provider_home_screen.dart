import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../models/provider_application.dart';
import '../../models/technician.dart';
import 'provider_auth_cubit.dart';
import 'provider_order_card.dart';
import 'provider_workspace_cubit.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderWorkspaceCubit>().state;
    final application = context.watch<ProviderAuthCubit>().state.application;
    final profile = state.profile;
    if (state.loading && profile == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (profile == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 58,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Text('ملف الصنايعي لسه ما اتنشرش.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<ProviderWorkspaceCubit>().start(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: context.read<ProviderWorkspaceCubit>().start,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
          children: <Widget>[
            _Header(profile: profile),
            const SizedBox(height: 16),
            _AvailabilityCard(profile: profile, saving: state.saving),
            const SizedBox(height: 13),
            _SubscriptionCard(application: application, profile: profile),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: Icons.notifications_active_outlined,
                    value: '${state.incoming.length}',
                    label: 'طلبات جديدة',
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _StatCard(
                    icon: Icons.build_circle_outlined,
                    value: '${state.active.length}',
                    label: 'قيد التنفيذ',
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _StatCard(
                    icon: Icons.task_alt_rounded,
                    value: '${state.completed.length}',
                    label: 'مكتملة',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'أحدث الطلبات',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/provider/orders'),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (state.incoming.isEmpty && state.active.isEmpty)
              const _NoOrdersCard()
            else ...<Widget>[
              ...state.incoming
                  .take(2)
                  .map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProviderOrderCard(
                        order: order,
                        compact: true,
                        onTap: () =>
                            context.push('/provider/order/${order.id}'),
                      ),
                    ),
                  ),
              if (state.incoming.isEmpty)
                ProviderOrderCard(
                  order: state.active.first,
                  compact: true,
                  onTap: () =>
                      context.push('/provider/order/${state.active.first.id}'),
                ),
            ],
            const SizedBox(height: 20),
            const _CashInfoCard(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final Technician profile;

  @override
  Widget build(BuildContext context) {
    final image = context.read<ImageService>().decode(profile.imageBase64);
    final name = profile.name.trim().isEmpty ? 'صنايعي Mazboot' : profile.name;
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 27,
          backgroundColor: AppColors.powderBlue,
          backgroundImage: image == null ? null : MemoryImage(image),
          child: image == null
              ? Text(
                  name[0],
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'أهلًا بيك يا',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const BrandLogo(compact: true, markSize: 39),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.profile, required this.saving});

  final Technician profile;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final available = profile.isAvailable;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: available ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: available ? AppColors.navy : AppColors.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: available
                  ? Colors.white.withOpacity(0.12)
                  : AppColors.powderPeach,
              shape: BoxShape.circle,
            ),
            child: Icon(
              available ? Icons.work_history_rounded : Icons.pause_rounded,
              color: available ? Colors.white : AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  available ? 'متاح لاستقبال طلبات' : 'استقبال الطلبات متوقف',
                  style: TextStyle(
                    color: available ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  available
                      ? 'ملفك ظاهر للعملاء ويمكنهم إرسال طلب.'
                      : 'شغّل الحالة لما تكون جاهز للشغل.',
                  style: TextStyle(
                    color: available ? Colors.white70 : AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: available,
            activeColor: AppColors.orange,
            activeTrackColor: Colors.white,
            onChanged: saving
                ? null
                : context.read<ProviderWorkspaceCubit>().setAvailability,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.application, required this.profile});

  final ProviderApplication? application;
  final Technician profile;

  @override
  Widget build(BuildContext context) {
    final applicationExpiry = application?.subscriptionExpiresAt ?? 0;
    final expiresAt = applicationExpiry > 0
        ? applicationExpiry
        : profile.subscriptionExpiresAt;
    final daysLeft = expiresAt <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            expiresAt,
          ).difference(DateTime.now()).inDays;
    final active = profile.subscriptionActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppColors.powderGreen : AppColors.powderPeach,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            active ? Icons.workspace_premium_rounded : Icons.warning_rounded,
            color: active ? AppColors.success : AppColors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  active ? 'الاشتراك الشهري فعّال' : 'الاشتراك غير فعّال',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  daysLeft == null
                      ? 'قيمة الاشتراك 50 جنيه شهريًا.'
                      : daysLeft >= 0
                      ? 'متبقي $daysLeft يوم • 50 جنيه شهريًا'
                      : 'انتهى الاشتراك؛ تواصل مع الإدارة للتجديد.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _NoOrdersCard extends StatelessWidget {
  const _NoOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 40),
          SizedBox(height: 8),
          Text('مفيش طلبات جديدة حاليًا'),
          Text(
            'سيب حالتك متاح وهنبلغك أول ما يوصلك طلب.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CashInfoCard extends StatelessWidget {
  const _CashInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.powderBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.payments_outlined, color: AppColors.navy),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'اتفاق السعر والتحصيل',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Text(
                  'اتفق مع العميل على سعر الشغل داخل المحادثة، والتحصيل يتم بينكم مباشرة بعد تنفيذ الخدمة.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
