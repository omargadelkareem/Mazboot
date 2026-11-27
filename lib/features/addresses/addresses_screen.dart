import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../models/address.dart';
import '../profile/profile_cubit.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final addresses =
        context.watch<ProfileCubit>().state.profile?.addresses ??
        const <CustomerAddress>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectionMode ? 'اختار عنوان الزيارة' : 'العناوين المحفوظة',
        ),
      ),
      body: addresses.isEmpty
          ? const _EmptyAddresses()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _AddressCard(
                address: addresses[index],
                onTap: selectionMode
                    ? () => Navigator.pop(context, addresses[index])
                    : null,
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddressSheet(context),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('عنوان جديد'),
      ),
    );
  }

  static Future<void> _openAddressSheet(
    BuildContext context, {
    CustomerAddress? address,
  }) async {
    final result = await showModalBottomSheet<CustomerAddress>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddressSheet(address: address),
    );
    if (result == null || !context.mounted) return;
    final saved = await context.read<ProfileCubit>().saveAddress(result);
    if (context.mounted) {
      UiUtils.showSnackBar(
        context,
        saved ? 'تم حفظ العنوان.' : 'تعذر حفظ العنوان.',
      );
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, this.onTap});

  final CustomerAddress address;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: address.isDefault ? AppColors.orange : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: address.isDefault
                    ? AppColors.orangeSoft
                    : AppColors.powderBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                address.label.contains('عمل')
                    ? Icons.work_outline_rounded
                    : Icons.home_outlined,
                color: address.isDefault ? AppColors.orange : AppColors.navy,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        address.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (address.isDefault) ...<Widget>[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orangeSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'الأساسي',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.details,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    '${address.governorate}، ${address.area}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  AddressesScreen._openAddressSheet(context, address: address);
                } else if (value == 'default') {
                  context.read<ProfileCubit>().saveAddress(
                    CustomerAddress(
                      id: address.id,
                      label: address.label,
                      details: address.details,
                      governorate: address.governorate,
                      area: address.area,
                      latitude: address.latitude,
                      longitude: address.longitude,
                      isDefault: true,
                    ),
                  );
                } else if (value == 'delete') {
                  context.read<ProfileCubit>().deleteAddress(address.id);
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('تعديل'),
                ),
                if (!address.isDefault)
                  const PopupMenuItem<String>(
                    value: 'default',
                    child: Text('جعله أساسيًا'),
                  ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({this.address});

  final CustomerAddress? address;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  static const _governorates = <String>[
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحر الأحمر',
    'البحيرة',
    'الفيوم',
    'الغربية',
    'الإسماعيلية',
    'المنوفية',
    'المنيا',
    'القليوبية',
    'الوادي الجديد',
    'السويس',
    'أسوان',
    'أسيوط',
    'بني سويف',
    'بورسعيد',
    'دمياط',
    'الشرقية',
    'جنوب سيناء',
    'كفر الشيخ',
    'مطروح',
    'الأقصر',
    'قنا',
    'شمال سيناء',
    'سوهاج',
  ];

  late final TextEditingController _labelController;
  late final TextEditingController _detailsController;
  late final TextEditingController _areaController;
  late String _governorate;
  late bool _isDefault;
  CustomerLocation? _coordinates;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _labelController = TextEditingController(text: address?.label ?? 'المنزل');
    _detailsController = TextEditingController(text: address?.details ?? '');
    _areaController = TextEditingController(text: address?.area ?? '');
    _governorate = _governorates.contains(address?.governorate)
        ? address!.governorate
        : 'القاهرة';
    _isDefault = address?.isDefault ?? false;
    if (address?.latitude != null && address?.longitude != null) {
      _coordinates = CustomerLocation(
        latitude: address!.latitude!,
        longitude: address.longitude!,
      );
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _detailsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final coordinates = await context.read<LocationService>().current();
      if (mounted) setState(() => _coordinates = coordinates);
    } on LocationException catch (error) {
      if (mounted) UiUtils.showSnackBar(context, error.message);
    } catch (_) {
      if (mounted) UiUtils.showSnackBar(context, 'تعذر تحديد الموقع.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _save() {
    if (_labelController.text.trim().isEmpty ||
        _detailsController.text.trim().length < 5 ||
        _areaController.text.trim().isEmpty) {
      UiUtils.showSnackBar(context, 'كمّل اسم العنوان والمنطقة والتفاصيل.');
      return;
    }
    Navigator.pop(
      context,
      CustomerAddress(
        id: widget.address?.id ?? const Uuid().v4(),
        label: _labelController.text.trim(),
        details: _detailsController.text.trim(),
        governorate: _governorate,
        area: _areaController.text.trim(),
        latitude: _coordinates?.latitude,
        longitude: _coordinates?.longitude,
        isDefault: _isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.address == null ? 'عنوان جديد' : 'تعديل العنوان',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'اسم العنوان'),
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(
              value: _governorate,
              items: _governorates
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _governorate = value ?? _governorate),
              decoration: const InputDecoration(labelText: 'المحافظة'),
            ),
            const SizedBox(height: 11),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'المنطقة أو المركز'),
            ),
            const SizedBox(height: 11),
            TextField(
              controller: _detailsController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'العنوان بالتفصيل',
                hintText: 'الشارع، العمارة، الدور، علامة مميزة',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _locating ? null : _locate,
              icon: _locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _coordinates == null
                    ? 'إضافة إحداثيات الموقع'
                    : 'تم حفظ الإحداثيات',
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              title: const Text('العنوان الأساسي'),
            ),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.orange,
              ),
              child: const Text('حفظ العنوان'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.add_location_alt_outlined,
            size: 68,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text('احفظ عنوان علشان طلب الخدمة يبقى أسرع'),
        ],
      ),
    );
  }
}
