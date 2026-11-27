import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/remote_image.dart';
import '../../models/address.dart';
import '../home/home_cubit.dart';
import '../orders/orders_cubit.dart';
import '../profile/profile_cubit.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, required this.technicianId});

  final String technicianId;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _problemController = TextEditingController();
  late final TextEditingController _addressController;
  late final List<String> _dates;

  static const _times = <String>[
    '10:00 ص - 1:00 م',
    '2:00 م - 5:00 م',
    '6:00 م - 9:00 م',
  ];

  int _dateIndex = 0;
  int _timeIndex = 0;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = <String>[
      'اليوم، ${_dateLabel(today)}',
      'غدًا، ${_dateLabel(today.add(const Duration(days: 1)))}',
      'بعد غد، ${_dateLabel(today.add(const Duration(days: 2)))}',
    ];
    final profile = context.read<ProfileCubit>().state.profile;
    final defaultAddress = profile?.addresses
        .where((item) => item.isDefault)
        .firstOrNull;
    final value = defaultAddress?.details ?? profile?.locationLabel ?? '';
    _addressController = TextEditingController(
      text: value == 'حدد موقعك' ? '' : value,
    );
  }

  @override
  void dispose() {
    _problemController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await context.read<ImageService>().pickBase64(
        source: source,
      );
      if (!mounted || image == null) return;
      setState(() => _imageBase64 = image);
    } on ImageTooLargeException {
      if (mounted)
        UiUtils.showSnackBar(
          context,
          'الصورة كبيرة. اختار صورة أصغر من 900 كيلوبايت.',
        );
    } catch (_) {
      if (mounted)
        UiUtils.showSnackBar(
          context,
          'تعذر فتح الصورة. راجع صلاحية الكاميرا أو الصور.',
        );
    }
  }

  Future<void> _submit() async {
    final technician = context.read<HomeCubit>().state.technicianById(
      widget.technicianId,
    );
    if (technician == null) return;
    if (!technician.canReceiveOrders) {
      UiUtils.showSnackBar(
        context,
        'الفني غير متاح لاستقبال طلبات جديدة حاليًا.',
      );
      return;
    }
    if (_problemController.text.trim().length < 8) {
      UiUtils.showSnackBar(
        context,
        'اكتب تفاصيل أكتر عن المشكلة علشان الفني يستعد.',
      );
      return;
    }
    if (_addressController.text.trim().length < 5) {
      UiUtils.showSnackBar(context, 'اكتب عنوان الزيارة بالتفصيل.');
      return;
    }
    final order = await context.read<OrdersCubit>().create(
      technician: technician,
      problem: _problemController.text.trim(),
      address: _addressController.text.trim(),
      date: _dates[_dateIndex],
      time: _times[_timeIndex],
      problemImageBase64: _imageBase64,
    );
    if (!mounted) return;
    if (order == null) {
      UiUtils.showSnackBar(
        context,
        context.read<OrdersCubit>().state.message ?? 'تعذر إرسال الطلب.',
      );
      return;
    }
    context.pushReplacement('/tracking/${order.id}');
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCubit>().state;
    final technician = home.technicianById(widget.technicianId);
    final sending = context.watch<OrdersCubit>().state.actionLoading;
    if (technician == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: const Center(child: Text('الفني غير متاح حاليًا')),
      );
    }
    final category = home.categoryById(technician.categoryId);
    final imageBytes = context.read<ImageService>().decode(_imageBase64);
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
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
                    width: 64,
                    height: 64,
                    borderRadius: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          technician.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${category?.name ?? ''} • ${technician.profession}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '★ ${technician.rating}  •  ${technician.distanceKm} كم',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (technician.isVerified)
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _FieldTitle(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'إيه المشكلة؟',
            ),
            const SizedBox(height: 9),
            TextField(
              controller: _problemController,
              minLines: 4,
              maxLines: 6,
              maxLength: 800,
              decoration: const InputDecoration(
                hintText: 'اوصف العطل ومكانه وأي تفاصيل مهمة…',
                alignLabelWithHint: true,
              ),
            ),
            if (imageBytes != null) ...<Widget>[
              const SizedBox(height: 4),
              Stack(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      imageBytes,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  PositionedDirectional(
                    end: 8,
                    top: 8,
                    child: IconButton.filled(
                      onPressed: () => setState(() => _imageBase64 = null),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _AttachmentButton(
                    icon: Icons.photo_library_outlined,
                    label: 'اختار صورة',
                    active: _imageBase64 != null,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _AttachmentButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'صوّر المشكلة',
                    active: _imageBase64 != null,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _FieldTitle(
              icon: Icons.location_on_outlined,
              title: 'عنوان الزيارة',
            ),
            const SizedBox(height: 9),
            TextField(
              controller: _addressController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.home_outlined),
                suffixIcon: IconButton(
                  onPressed: () async {
                    final selected = await context.push<CustomerAddress>(
                      '/addresses?select=1',
                    );
                    if (!mounted || selected == null) return;
                    _addressController.text = selected.details;
                  },
                  icon: const Icon(
                    Icons.bookmark_outline_rounded,
                    color: AppColors.orange,
                  ),
                ),
                hintText: 'الشارع، رقم العمارة، الدور، علامة مميزة',
              ),
            ),
            const SizedBox(height: 24),
            const _FieldTitle(
              icon: Icons.calendar_month_outlined,
              title: 'اختار اليوم',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ChoiceChip(
                  label: Text(_dates[index]),
                  selected: _dateIndex == index,
                  onSelected: (_) => setState(() => _dateIndex = index),
                  selectedColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _dateIndex == index ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  side: BorderSide(
                    color: _dateIndex == index
                        ? AppColors.navy
                        : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _FieldTitle(
              icon: Icons.schedule_rounded,
              title: 'اختار الوقت',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(
                _times.length,
                (index) => ChoiceChip(
                  label: Text(_times[index]),
                  selected: _timeIndex == index,
                  onSelected: (_) => setState(() => _timeIndex = index),
                  selectedColor: AppColors.orangeSoft,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _timeIndex == index
                        ? AppColors.orange
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  side: BorderSide(
                    color: _timeIndex == index
                        ? AppColors.orange
                        : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.powderBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>[
                  _SummaryRow(label: 'إرسال الطلب', value: 'مجاني'),
                  const SizedBox(height: 8),
                  const _SummaryRow(
                    label: 'السعر النهائي',
                    value: 'بعد الاتفاق مع الفني',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  const Row(
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.success,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'لا توجد رسوم معاينة أو دفع مسبق داخل التطبيق.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
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
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: PrimaryButton(
            label: 'تأكيد وإرسال الطلب',
            icon: Icons.send_rounded,
            isLoading: sending,
            onPressed: sending || !technician.canReceiveOrders ? null : _submit,
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FieldTitle extends StatelessWidget {
  const _FieldTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: AppColors.orange, size: 20),
        const SizedBox(width: 7),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.powderGreen : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: active ? AppColors.success : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 19,
              color: active ? AppColors.success : AppColors.navy,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
