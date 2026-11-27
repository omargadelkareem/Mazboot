import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/remote_image.dart';
import '../../models/service_order.dart';
import '../../repositories/customer_repository.dart';
import '../home/home_cubit.dart';
import '../orders/orders_cubit.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceOrder?>(
      stream: context.read<CustomerRepository>().watchOrder(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('تتبع الطلب')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تتبع الطلب')),
            body: const Center(
              child: Text('الطلب غير موجود أو لا يخص هذا الحساب'),
            ),
          );
        }
        final technician = context.watch<HomeCubit>().state.technicianById(
          order.technicianId,
        );
        if (technician == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تتبع الطلب')),
            body: const Center(child: Text('تعذر تحميل بيانات الفني')),
          );
        }
        final isDone = order.status == ServiceOrderStatus.completed;
        final isCancelled = order.status == ServiceOrderStatus.cancelled;
        final ordersState = context.watch<OrdersCubit>().state;
        final cancellationRequested = ordersState.cancellationRequestedIds
            .contains(order.id);
        return Scaffold(
          appBar: AppBar(
            title: const Text('تتبع الطلب'),
            actions: <Widget>[
              IconButton(
                onPressed: () =>
                    UiUtils.showSnackBar(context, 'رقم الطلب: ${order.id}'),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.powderGreen
                        : isCancelled
                        ? AppColors.orangeSoft
                        : AppColors.navy,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDone || isCancelled
                              ? Colors.white
                              : AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone
                              ? Icons.check_rounded
                              : isCancelled
                              ? Icons.close_rounded
                              : Icons.route_rounded,
                          color: isDone
                              ? AppColors.success
                              : isCancelled
                              ? AppColors.danger
                              : Colors.white,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _statusHeadline(order.status),
                              style: TextStyle(
                                color: isDone || isCancelled
                                    ? AppColors.text
                                    : Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _statusSubtitle(order.status),
                              style: TextStyle(
                                color: isDone || isCancelled
                                    ? AppColors.textMuted
                                    : Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isDone && !isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isCancelled) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    height: 214,
                    decoration: BoxDecoration(
                      color: AppColors.powderBlue,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      children: <Widget>[
                        const Positioned.fill(
                          child: CustomPaint(painter: _RouteMapPainter()),
                        ),
                        const Positioned(
                          right: 38,
                          bottom: 35,
                          child: _MapPin(
                            icon: Icons.home_rounded,
                            color: AppColors.navy,
                          ),
                        ),
                        Positioned(
                          left: 44,
                          top: 38,
                          child: _MapPin(
                            icon: Icons.handyman_rounded,
                            color: isDone
                                ? AppColors.success
                                : AppColors.orange,
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x19032A57),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              isDone
                                  ? 'تمت الخدمة'
                                  : '${technician.distanceKm} كم بعيدًا',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      RemoteImage(
                        url: technician.imageUrl,
                        base64Data: technician.imageBase64,
                        width: 62,
                        height: 62,
                        borderRadius: 16,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    technician.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (technician.isVerified)
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: AppColors.navy,
                                  ),
                              ],
                            ),
                            Text(
                              technician.profession,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '★ ${technician.rating}  •  ${technician.completedJobs} خدمة',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        color: AppColors.navy,
                        onTap: () =>
                            context.push('/chat/${order.id}/${technician.id}'),
                      ),
                      const SizedBox(width: 7),
                      _RoundAction(
                        icon: Icons.call_outlined,
                        color: AppColors.success,
                        onTap: () => _callTechnician(context, technician.phone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'حالة الطلب',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 13),
                _OrderTimeline(status: order.status),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.orange,
                        size: 23,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'لأمانك: اتفق على السعر داخل الشات قبل بدء العمل، وما تدفعش إلا بعد التأكد من الخدمة.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.text,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if ((order.status == ServiceOrderStatus.sent ||
                        order.status == ServiceOrderStatus.accepted) &&
                    cancellationRequested) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.powderBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.navy,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'طلب الإلغاء تحت المراجعة.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (order.status == ServiceOrderStatus.sent ||
                    order.status == ServiceOrderStatus.accepted) ...<Widget>[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: ordersState.actionLoading
                        ? null
                        : () => _showCancellation(context, order),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('طلب إلغاء الخدمة'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _callTechnician(
    BuildContext context,
    String phone,
  ) async {
    if (phone.isEmpty) {
      UiUtils.showSnackBar(context, 'رقم الفني غير متاح داخل بياناته حاليًا.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (context.mounted) UiUtils.showSnackBar(context, 'تعذر فتح الاتصال.');
    }
  }

  static Future<void> _showCancellation(
    BuildContext context,
    ServiceOrder order,
  ) async {
    final controller = TextEditingController();
    final shouldCancel = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('إلغاء الطلب', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'اكتب سبب الإلغاء. في النظام الحقيقي الطلب بيتراجع حسب حالته.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'سبب الإلغاء'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().length < 3) return;
                Navigator.pop(sheetContext, true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('تأكيد طلب الإلغاء'),
            ),
          ],
        ),
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    if (shouldCancel != true || !context.mounted) return;
    final success = await context.read<OrdersCubit>().cancel(order.id, reason);
    if (context.mounted && success) {
      UiUtils.showSnackBar(context, 'تم إرسال طلب الإلغاء.');
    }
  }

  static String _statusHeadline(ServiceOrderStatus status) => switch (status) {
    ServiceOrderStatus.sent => 'طلبك وصل للفني',
    ServiceOrderStatus.accepted => 'الفني قبل طلبك',
    ServiceOrderStatus.onTheWay => 'الفني في الطريق إليك',
    ServiceOrderStatus.inProgress => 'الخدمة قيد التنفيذ',
    ServiceOrderStatus.completed => 'الخدمة اكتملت بنجاح',
    ServiceOrderStatus.cancelled => 'تم إلغاء الطلب',
  };

  static String _statusSubtitle(ServiceOrderStatus status) => switch (status) {
    ServiceOrderStatus.sent => 'في انتظار رد الفني',
    ServiceOrderStatus.accepted => 'تم تأكيد الموعد',
    ServiceOrderStatus.onTheWay => 'تابع وصول الفني وتواصل معاه',
    ServiceOrderStatus.inProgress => 'الفني بدأ تنفيذ الخدمة',
    ServiceOrderStatus.completed => 'شكرًا لاستخدامك Mazboot',
    ServiceOrderStatus.cancelled => 'راجع سبب الإلغاء في تفاصيل الطلب',
  };
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x25032A57), blurRadius: 12),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status});

  final ServiceOrderStatus status;

  int get _currentStep => switch (status) {
    ServiceOrderStatus.sent => 0,
    ServiceOrderStatus.accepted => 1,
    ServiceOrderStatus.onTheWay => 2,
    ServiceOrderStatus.inProgress => 3,
    ServiceOrderStatus.completed => 4,
    ServiceOrderStatus.cancelled => -1,
  };

  static const _labels = <String>[
    'تم إرسال الطلب',
    'الفني قبل الطلب',
    'الفني في الطريق',
    'بدأ تنفيذ الخدمة',
    'اكتملت الخدمة',
  ];

  static const _icons = <IconData>[
    Icons.send_outlined,
    Icons.task_alt_rounded,
    Icons.route_rounded,
    Icons.handyman_outlined,
    Icons.celebration_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == ServiceOrderStatus.cancelled) {
      return const ListTile(
        tileColor: AppColors.orangeSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        leading: Icon(Icons.cancel_outlined, color: AppColors.danger),
        title: Text(
          'تم إلغاء الطلب',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    return Column(
      children: List<Widget>.generate(_labels.length, (index) {
        final done = index <= _currentStep;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 38,
              child: Column(
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: done ? AppColors.navy : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done ? AppColors.navy : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      _icons[index],
                      size: 16,
                      color: done ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  if (index != _labels.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: index < _currentStep
                          ? AppColors.navy
                          : AppColors.border,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _labels[index],
                  style: TextStyle(
                    color: done ? AppColors.text : AppColors.textMuted,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (index == _currentStep)
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Text(
                  'الآن',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    final thinRoadPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, 0),
      Offset(size.width * 0.38, size.height),
      thinRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, 0),
      Offset(size.width * 0.62, size.height),
      thinRoadPaint,
    );
    final route = Path()
      ..moveTo(size.width * 0.24, size.height * 0.29)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.42,
        size.width * 0.5,
        size.height * 0.58,
        size.width * 0.73,
        size.height * 0.72,
      );
    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
