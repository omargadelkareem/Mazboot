import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../models/service_order.dart';
import '../home/home_cubit.dart';

Color providerOrderStatusColor(ServiceOrderStatus status) => switch (status) {
  ServiceOrderStatus.sent => AppColors.orange,
  ServiceOrderStatus.accepted => AppColors.navy,
  ServiceOrderStatus.onTheWay => const Color(0xFF7259C7),
  ServiceOrderStatus.inProgress => AppColors.warning,
  ServiceOrderStatus.completed => AppColors.success,
  ServiceOrderStatus.cancelled => AppColors.danger,
};

ServiceOrderStatus? providerNextStatus(ServiceOrderStatus status) =>
    switch (status) {
      ServiceOrderStatus.sent => ServiceOrderStatus.accepted,
      ServiceOrderStatus.accepted => ServiceOrderStatus.onTheWay,
      ServiceOrderStatus.onTheWay => ServiceOrderStatus.inProgress,
      ServiceOrderStatus.inProgress => ServiceOrderStatus.completed,
      ServiceOrderStatus.completed || ServiceOrderStatus.cancelled => null,
    };

String providerActionLabel(ServiceOrderStatus status) => switch (status) {
  ServiceOrderStatus.sent => 'قبول الطلب',
  ServiceOrderStatus.accepted => 'أنا في الطريق',
  ServiceOrderStatus.onTheWay => 'بدء التنفيذ',
  ServiceOrderStatus.inProgress => 'إتمام الخدمة',
  ServiceOrderStatus.completed => 'تمت الخدمة',
  ServiceOrderStatus.cancelled => 'طلب ملغي',
};

class ProviderOrderCard extends StatelessWidget {
  const ProviderOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.compact = false,
  });

  final ServiceOrder order;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final category = context.watch<HomeCubit>().state.categoryById(
      order.categoryId,
    );
    final statusColor = providerOrderStatusColor(order.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: category?.backgroundColor ?? AppColors.powderBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    category?.icon ?? Icons.home_repair_service_rounded,
                    color: AppColors.navy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        category?.name ?? 'طلب خدمة',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'طلب #${_shortId(order.id)}',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.problem,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.55),
            ),
            const SizedBox(height: 11),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.orange,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    order.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    order.date,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  order.time,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.navy,
                  size: 13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(value.length - 8).toUpperCase();
  }
}
