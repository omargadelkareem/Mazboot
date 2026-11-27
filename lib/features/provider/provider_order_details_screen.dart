import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/service_order.dart';
import '../home/home_cubit.dart';
import 'provider_order_card.dart';
import 'provider_workspace_cubit.dart';

class ProviderOrderDetailsScreen extends StatelessWidget {
  const ProviderOrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderWorkspaceCubit>().state;
    final order = state.orderById(orderId);
    if (state.loading && order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: const Center(child: Text('الطلب غير موجود أو لا يخص حسابك.')),
      );
    }
    final category = context.watch<HomeCubit>().state.categoryById(
      order.categoryId,
    );
    final statusColor = providerOrderStatusColor(order.status);
    final image = context.read<ImageService>().decode(order.problemImageBase64);
    final next = providerNextStatus(order.status);
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      bottomNavigationBar: _BottomActions(order: order, next: next),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, next == null ? 24 : 112),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          category?.icon ?? Icons.home_repair_service_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              category?.name ?? 'طلب خدمة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '#$orderId',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          order.status.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _DarkInfo(
                          icon: Icons.calendar_today_outlined,
                          label: 'اليوم',
                          value: order.date,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DarkInfo(
                          icon: Icons.schedule_rounded,
                          label: 'الموعد',
                          value: order.time,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _SectionCard(
              title: 'وصف المشكلة',
              icon: Icons.build_outlined,
              child: Text(
                order.problem,
                style: const TextStyle(fontSize: 13, height: 1.65),
              ),
            ),
            if (image != null) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(
                  image,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _SectionCard(
              title: 'العنوان',
              icon: Icons.location_on_outlined,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.pin_drop_rounded,
                    color: AppColors.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.address,
                      style: const TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'العميل والتواصل',
              icon: Icons.person_outline_rounded,
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    radius: 23,
                    backgroundColor: AppColors.powderBlue,
                    child: Icon(Icons.person_rounded, color: AppColors.navy),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'عميل Mazboot • ${_customerReference(order.customerId)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'التواصل الآمن داخل محادثة الطلب',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push(
                      '/provider/chat/${order.id}/${order.customerId}',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'تقدم الطلب',
              icon: Icons.route_rounded,
              child: _StatusTimeline(status: order.status),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.powderGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.payments_outlined,
                    color: AppColors.success,
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'اتفق على سعر التنفيذ مع العميل قبل بدء الشغل. الدفع والتحصيل بيتموا بينكم مباشرة.',
                      style: TextStyle(fontSize: 10, height: 1.55),
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

  static String _customerReference(String value) {
    if (value.isEmpty) return 'عميل';
    if (value.length <= 5) return '#$value';
    return '#${value.substring(value.length - 5).toUpperCase()}';
  }
}

class _DarkInfo extends StatelessWidget {
  const _DarkInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.orange, size: 17),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 8),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 19, color: AppColors.navy),
              const SizedBox(width: 7),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final ServiceOrderStatus status;

  static const _steps = <ServiceOrderStatus>[
    ServiceOrderStatus.sent,
    ServiceOrderStatus.accepted,
    ServiceOrderStatus.onTheWay,
    ServiceOrderStatus.inProgress,
    ServiceOrderStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == ServiceOrderStatus.cancelled) {
      return const Row(
        children: <Widget>[
          Icon(Icons.cancel_rounded, color: AppColors.danger),
          SizedBox(width: 8),
          Text('تم إلغاء الطلب'),
        ],
      );
    }
    final currentIndex = _steps.indexOf(status);
    return Row(
      children: List<Widget>.generate(_steps.length, (index) {
        final reached = index <= currentIndex;
        return Expanded(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: reached ? AppColors.success : AppColors.border,
                      ),
                    ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: reached ? AppColors.success : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: reached ? AppColors.success : AppColors.border,
                      ),
                    ),
                    child: reached
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  if (index < _steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentIndex
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _shortLabel(_steps[index]),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: reached ? AppColors.text : AppColors.textMuted,
                  fontSize: 7.5,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  static String _shortLabel(ServiceOrderStatus status) => switch (status) {
    ServiceOrderStatus.sent => 'جديد',
    ServiceOrderStatus.accepted => 'مقبول',
    ServiceOrderStatus.onTheWay => 'في الطريق',
    ServiceOrderStatus.inProgress => 'تنفيذ',
    ServiceOrderStatus.completed => 'مكتمل',
    ServiceOrderStatus.cancelled => 'ملغي',
  };
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.order, required this.next});

  final ServiceOrder order;
  final ServiceOrderStatus? next;

  @override
  Widget build(BuildContext context) {
    if (next == null) return const SizedBox.shrink();
    final saving = context.watch<ProviderWorkspaceCubit>().state.saving;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: saving ? null : () => _advance(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(providerActionLabel(order.status)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(53),
                backgroundColor: next == ServiceOrderStatus.completed
                    ? AppColors.success
                    : AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: () =>
                context.push('/provider/chat/${order.id}/${order.customerId}'),
            style: IconButton.styleFrom(
              minimumSize: const Size(53, 53),
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          if (order.status == ServiceOrderStatus.sent ||
              order.status == ServiceOrderStatus.accepted ||
              order.status == ServiceOrderStatus.onTheWay) ...<Widget>[
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: saving ? null : () => _cancel(context),
              style: IconButton.styleFrom(
                minimumSize: const Size(53, 53),
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              tooltip: order.status == ServiceOrderStatus.sent
                  ? 'رفض الطلب'
                  : 'إلغاء الطلب',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _advance(BuildContext context) async {
    final target = next;
    if (target == null) return;
    if (target == ServiceOrderStatus.completed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تأكيد إتمام الخدمة'),
          content: const Text('أكد إن الشغل خلص والعميل استلم الخدمة.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('تمت الخدمة'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await context.read<ProviderWorkspaceCubit>().updateOrderStatus(
      order.id,
      target,
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          order.status == ServiceOrderStatus.sent ? 'رفض الطلب' : 'إلغاء الطلب',
        ),
        content: const Text(
          'الإجراء ده هيظهر للعميل ومش هتقدر ترجع الطلب لنفس الحالة.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ProviderWorkspaceCubit>().updateOrderStatus(
      order.id,
      ServiceOrderStatus.cancelled,
    );
  }
}
