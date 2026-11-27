import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/service_order.dart';
import 'provider_order_card.dart';
import 'provider_workspace_cubit.dart';

class ProviderOrdersScreen extends StatelessWidget {
  const ProviderOrdersScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final content = const _OrdersContent();
    if (!standalone) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلبات')),
      body: content,
    );
  }
}

class _OrdersContent extends StatelessWidget {
  const _OrdersContent();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderWorkspaceCubit>().state;
    return DefaultTabController(
      length: 4,
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
                        'طلبات الشغل',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text(
                        'تابع كل طلب وحدّث حالته أول بأول',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: AppColors.powderPeach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 49,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                indicator: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(13),
                ),
                tabs: <Widget>[
                  Tab(text: 'جديدة (${state.incoming.length})'),
                  Tab(text: 'جارية (${state.active.length})'),
                  Tab(text: 'مكتملة (${state.completed.length})'),
                  Tab(text: 'ملغية (${state.cancelled.length})'),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: <Widget>[
                        _OrderList(
                          orders: state.incoming,
                          emptyTitle: 'مفيش طلبات جديدة',
                          emptyDescription:
                              'الطلبات الجديدة هتظهر هنا فور وصولها.',
                        ),
                        _OrderList(
                          orders: state.active,
                          emptyTitle: 'مفيش شغل جاري',
                          emptyDescription:
                              'أي طلب تقبله هتتابع مراحله من هنا.',
                        ),
                        _OrderList(
                          orders: state.completed,
                          emptyTitle: 'لسه مفيش طلبات مكتملة',
                          emptyDescription:
                              'بعد إتمام الخدمة هتتحفظ في السجل هنا.',
                        ),
                        _OrderList(
                          orders: state.cancelled,
                          emptyTitle: 'مفيش طلبات ملغية',
                          emptyDescription: 'وده شيء كويس جدًا.',
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

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyTitle,
    required this.emptyDescription,
  });

  final List<ServiceOrder> orders;
  final String emptyTitle;
  final String emptyDescription;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyOrders(title: emptyTitle, description: emptyDescription);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(15, 2, 15, 116),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 11),
      itemBuilder: (context, index) => _ActionOrderCard(order: orders[index]),
    );
  }
}

class _ActionOrderCard extends StatelessWidget {
  const _ActionOrderCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    final next = providerNextStatus(order.status);
    final saving = context.watch<ProviderWorkspaceCubit>().state.saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ProviderOrderCard(
          order: order,
          onTap: () => context.push('/provider/order/${order.id}'),
        ),
        if (next != null) ...<Widget>[
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: saving ? null : () => _advance(context, next),
                  icon: Icon(_actionIcon(next), size: 18),
                  label: Text(providerActionLabel(order.status)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: next == ServiceOrderStatus.completed
                        ? AppColors.success
                        : AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (order.status == ServiceOrderStatus.sent ||
                  order.status == ServiceOrderStatus.accepted ||
                  order.status == ServiceOrderStatus.onTheWay) ...<Widget>[
                const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => _cancel(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('رفض/إلغاء'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _advance(BuildContext context, ServiceOrderStatus next) async {
    if (next == ServiceOrderStatus.completed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('إتمام الخدمة'),
          content: const Text(
            'أكد إن الشغل خلص والعميل استلم الخدمة قبل ما تقفل الطلب.',
          ),
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
      next,
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

  static IconData _actionIcon(ServiceOrderStatus next) => switch (next) {
    ServiceOrderStatus.accepted => Icons.check_rounded,
    ServiceOrderStatus.onTheWay => Icons.route_rounded,
    ServiceOrderStatus.inProgress => Icons.handyman_rounded,
    ServiceOrderStatus.completed => Icons.task_alt_rounded,
    _ => Icons.arrow_back_rounded,
  };
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: AppColors.powderBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.navy,
                size: 38,
              ),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
