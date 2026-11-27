import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/remote_image.dart';
import '../../models/service_order.dart';
import '../home/home_cubit.dart';
import '../profile/profile_cubit.dart';
import 'orders_cubit.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrdersCubit>().state;
    final current = state.orders.where((order) {
      return order.status != ServiceOrderStatus.completed &&
          order.status != ServiceOrderStatus.cancelled;
    }).toList();
    final completed = state.orders
        .where((order) => order.status == ServiceOrderStatus.completed)
        .toList();
    final cancelled = state.orders
        .where((order) => order.status == ServiceOrderStatus.cancelled)
        .toList();
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 13),
              child: Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'طلباتي',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text(
                        'كل خدمات بيتك محفوظة هنا',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.powderBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                indicator: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(13),
                ),
                tabs: <Widget>[
                  Tab(text: 'الحالية (${current.length})'),
                  Tab(text: 'المكتملة (${completed.length})'),
                  Tab(text: 'الملغية (${cancelled.length})'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: <Widget>[
                        _OrdersList(
                          orders: current,
                          type: _OrderListType.current,
                        ),
                        _OrdersList(
                          orders: completed,
                          type: _OrderListType.completed,
                        ),
                        _OrdersList(
                          orders: cancelled,
                          type: _OrderListType.cancelled,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OrderListType { current, completed, cancelled }

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders, required this.type});

  final List<ServiceOrder> orders;
  final _OrderListType type;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return _EmptyOrders(type: type);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 116),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 11),
      itemBuilder: (_, index) => _OrderCard(order: orders[index], type: type),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.type});

  final ServiceOrder order;
  final _OrderListType type;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCubit>().state;
    final technician = home.technicianById(order.technicianId);
    final category = home.categoryById(order.categoryId);
    if (technician == null || category == null) return const SizedBox.shrink();
    final statusColor = switch (order.status) {
      ServiceOrderStatus.completed => AppColors.success,
      ServiceOrderStatus.cancelled => AppColors.danger,
      ServiceOrderStatus.inProgress => AppColors.orange,
      _ => AppColors.navy,
    };
    void openOrder() => context.push('/tracking/${order.id}');

    return InkWell(
      onTap: openOrder,
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
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: category.backgroundColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(category.icon, color: AppColors.navy, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        order.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: <Widget>[
                RemoteImage(
                  url: technician.imageUrl,
                  base64Data: technician.imageBase64,
                  width: 51,
                  height: 51,
                  borderRadius: 14,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        technician.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        technician.profession,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    order.date,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  order.time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: type == _OrderListType.completed
                  ? OutlinedButton.icon(
                      onPressed: () =>
                          _showRating(context, order, technician.name),
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('قيّم الخدمة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: const BorderSide(color: AppColors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: openOrder,
                      icon: Icon(
                        type == _OrderListType.current
                            ? Icons.route_rounded
                            : Icons.receipt_long_outlined,
                        size: 18,
                      ),
                      label: Text(
                        type == _OrderListType.current
                            ? 'تتبع الطلب'
                            : 'عرض التفاصيل',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRating(
    BuildContext context,
    ServiceOrder order,
    String technicianName,
  ) async {
    final result = await showModalBottomSheet<_RatingResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _RatingSheet(technicianName: technicianName),
    );
    if (result == null || !context.mounted) return;
    final customerName =
        context.read<ProfileCubit>().state.profile?.name ?? 'عميل Mazboot';
    final success = await context.read<OrdersCubit>().review(
      order: order,
      customerName: customerName,
      rating: result.rating,
      comment: result.comment,
    );
    if (!context.mounted) return;
    UiUtils.showSnackBar(
      context,
      success
          ? 'شكرًا! تم حفظ تقييمك.'
          : context.read<OrdersCubit>().state.message ?? 'تعذر الحفظ',
    );
  }
}

class _RatingResult {
  const _RatingResult(this.rating, this.comment);

  final int rating;
  final String comment;
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.technicianName});

  final String technicianName;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        0,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'قيّم خدمة ${widget.technicianName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.warning,
                  size: 38,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب رأيك في الخدمة (اختياري)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _RatingResult(_rating, _commentController.text.trim()),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.orange,
            ),
            child: const Text('إرسال التقييم'),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.type});

  final _OrderListType type;

  @override
  Widget build(BuildContext context) {
    final text = switch (type) {
      _OrderListType.current => 'مفيش طلبات حالية',
      _OrderListType.completed => 'لسه مفيش خدمات مكتملة',
      _OrderListType.cancelled => 'مفيش طلبات ملغية',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: AppColors.powderBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 38,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 14),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
