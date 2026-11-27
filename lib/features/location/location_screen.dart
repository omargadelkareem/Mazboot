import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/address.dart';
import '../profile/profile_cubit.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const areas = <String, List<String>>{
    'القاهرة': <String>['مدينة نصر', 'المعادي', 'التجمع الخامس', 'مصر الجديدة'],
    'الجيزة': <String>['الدقي', 'المهندسين', '6 أكتوبر', 'الشيخ زايد'],
    'الإسكندرية': <String>['سيدي جابر', 'سموحة', 'العجمي', 'المنتزه'],
    'الدقهلية': <String>['المنصورة', 'طلخا', 'ميت غمر', 'دكرنس'],
    'البحر الأحمر': <String>['الغردقة', 'رأس غارب', 'سفاجا', 'القصير'],
    'البحيرة': <String>['دمنهور', 'كفر الدوار', 'رشيد', 'وادي النطرون'],
    'الفيوم': <String>['الفيوم', 'سنورس', 'إطسا', 'طامية'],
    'الغربية': <String>['طنطا', 'المحلة الكبرى', 'كفر الزيات', 'زفتى'],
    'الإسماعيلية': <String>['حي أول', 'حي ثان', 'حي ثالث', 'فايد'],
    'المنوفية': <String>['شبين الكوم', 'منوف', 'السادات', 'أشمون'],
    'المنيا': <String>['المنيا', 'ملوي', 'سمالوط', 'بني مزار'],
    'القليوبية': <String>['بنها', 'شبرا الخيمة', 'العبور', 'قليوب'],
    'الوادي الجديد': <String>['الخارجة', 'الداخلة', 'الفرافرة', 'باريس'],
    'السويس': <String>['الأربعين', 'عتاقة', 'فيصل', 'الجناين'],
    'أسوان': <String>['أسوان', 'كوم أمبو', 'إدفو', 'دراو'],
    'أسيوط': <String>['حي شرق', 'حي غرب', 'أسيوط الجديدة', 'أبنوب'],
    'بني سويف': <String>['بني سويف', 'الواسطى', 'ببا', 'ناصر'],
    'بورسعيد': <String>['حي الشرق', 'حي العرب', 'الزهور', 'بورفؤاد'],
    'دمياط': <String>['دمياط', 'دمياط الجديدة', 'رأس البر', 'فارسكور'],
    'الشرقية': <String>['الزقازيق', 'العاشر من رمضان', 'بلبيس', 'فاقوس'],
    'جنوب سيناء': <String>['شرم الشيخ', 'دهب', 'الطور', 'رأس سدر'],
    'كفر الشيخ': <String>['كفر الشيخ', 'دسوق', 'بلطيم', 'سيدي سالم'],
    'مطروح': <String>['مرسى مطروح', 'الحمام', 'العلمين', 'الضبعة'],
    'الأقصر': <String>['الأقصر', 'البياضية', 'إسنا', 'أرمنت'],
    'قنا': <String>['قنا', 'نجع حمادي', 'قفط', 'دشنا'],
    'شمال سيناء': <String>['العريش', 'بئر العبد', 'الشيخ زويد', 'رفح'],
    'سوهاج': <String>['حي شرق', 'حي غرب', 'أخميم', 'الكوثر', 'المراغة', 'طهطا'],
  };

  String _governorate = 'القاهرة';
  String _area = 'مدينة نصر';
  CustomerLocation? _coordinates;
  bool _locating = false;
  bool _initialized = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final value = await context.read<LocationService>().current();
      if (!mounted) return;
      setState(() {
        _coordinates = value;
        _locating = false;
      });
      UiUtils.showSnackBar(
        context,
        'تم التقاط موقعك. راجع المحافظة والمنطقة ثم احفظ.',
      );
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _locating = false);
      UiUtils.showSnackBar(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      UiUtils.showSnackBar(context, 'تعذر تحديد الموقع، اختاره يدويًا.');
    }
  }

  Future<void> _continue() async {
    final cubit = context.read<ProfileCubit>();
    final saved = await cubit.saveLocation(
      governorate: _governorate,
      area: _area,
    );
    if (!mounted) return;
    if (!saved) {
      UiUtils.showSnackBar(context, cubit.state.message ?? 'تعذر حفظ الموقع.');
      return;
    }
    await cubit.saveAddress(
      CustomerAddress(
        id: 'current-location',
        label: 'الموقع الأساسي',
        details: '$_governorate، $_area',
        governorate: _governorate,
        area: _area,
        latitude: _coordinates?.latitude,
        longitude: _coordinates?.longitude,
        isDefault: true,
      ),
    );
    if (mounted) context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    final profile = profileState.profile;
    if (!_initialized && profile != null) {
      _initialized = true;
      if (areas.containsKey(profile.governorate)) {
        _governorate = profile.governorate;
        if (areas[_governorate]!.contains(profile.area)) _area = profile.area;
      }
    }
    final saving = profileState.saving;
    return Scaffold(
      appBar: AppBar(title: const Text('حدد موقعك')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 230,
                decoration: BoxDecoration(
                  color: AppColors.powderBlue,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    const Positioned(
                      right: 28,
                      top: 32,
                      child: _MapDot(size: 12),
                    ),
                    const Positioned(
                      left: 42,
                      bottom: 46,
                      child: _MapDot(size: 8),
                    ),
                    Icon(
                      Icons.map_rounded,
                      size: 145,
                      color: AppColors.navy.withOpacity(0.13),
                    ),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 52,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'علشان نعرض أقرب صنايعي ليك',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 7),
              Text(
                'اختار المحافظة والمنطقة، وتقدر تغيرهم في أي وقت من الرئيسية.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<String>(
                value: _governorate,
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: areas.keys
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _governorate = value;
                    _area = areas[value]!.first;
                  });
                },
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(_governorate),
                value: _area,
                decoration: const InputDecoration(
                  labelText: 'المنطقة أو المركز',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                items: areas[_governorate]!
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _area = value ?? _area),
              ),
              const SizedBox(height: 13),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(
                  _coordinates == null
                      ? 'استخدام موقعي الحالي'
                      : 'تم تحديد موقعك',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'حفظ ومتابعة',
                icon: Icons.arrow_back_rounded,
                isLoading: saving,
                onPressed: saving ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
      ),
    );
  }
}
