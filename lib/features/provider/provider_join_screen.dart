import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/egypt_locations.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/primary_button.dart';
import '../home/home_cubit.dart';
import 'provider_application_cubit.dart';

class ProviderJoinScreen extends StatefulWidget {
  const ProviderJoinScreen({super.key});

  @override
  State<ProviderJoinScreen> createState() => _ProviderJoinScreenState();
}

class _ProviderJoinScreenState extends State<ProviderJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _categoryId;
  String _governorate = EgyptLocations.areas.keys.first;
  late String _area = EgyptLocations.areas[_governorate]!.first;
  String? _photoBase64;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final value = await context.read<ImageService>().pickBase64(
        source: source,
      );
      if (!mounted || value == null) return;
      setState(() => _photoBase64 = value);
    } on ImageTooLargeException {
      if (mounted) {
        UiUtils.showSnackBar(context, 'الصورة كبيرة، اختار صورة أصغر.');
      }
    } catch (_) {
      if (mounted) {
        UiUtils.showSnackBar(context, 'تعذر فتح الصورة، راجع الصلاحيات.');
      }
    }
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار صورة من الهاتف'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_photoBase64 == null) {
      UiUtils.showSnackBar(context, 'ضيف صورة شخصية واضحة علشان نراجع طلبك.');
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) return;
    final submitted = await context.read<ProviderApplicationCubit>().submit(
      name: _nameController.text.trim(),
      phone: _normalizedPhone(_phoneController.text),
      categoryId: categoryId,
      governorate: _governorate,
      area: _area,
      photoBase64: _photoBase64!,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (!submitted) {
      UiUtils.showSnackBar(
        context,
        context.read<ProviderApplicationCubit>().state.message ??
            'تعذر إرسال الطلب.',
      );
      return;
    }
    if (mounted) context.go('/provider-review');
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<HomeCubit>().state.categories;
    final state = context.watch<ProviderApplicationCubit>().state;
    final imageBytes = context.read<ImageService>().decode(_photoBase64);
    return Scaffold(
      appBar: AppBar(
        title: const Text('انضم كصنايعي'),
        leading: IconButton(
          onPressed: () => context.go('/role-selection'),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.powderPeach,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.handyman_rounded,
                        color: AppColors.navy,
                        size: 29,
                      ),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ابدأ شغلك مع Mazboot',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'املأ بياناتك وسيتم مراجعتها قبل ظهورك للعملاء.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: InkWell(
                  onTap: _choosePhotoSource,
                  borderRadius: BorderRadius.circular(60),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        width: 112,
                        height: 112,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.powderBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: imageBytes == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 58,
                                color: AppColors.navy,
                              )
                            : Image.memory(imageBytes, fit: BoxFit.cover),
                      ),
                      PositionedDirectional(
                        end: -2,
                        bottom: 4,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'صورة شخصية واضحة',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالكامل',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 3) return 'اكتب اسمك بالكامل';
                  return null;
                },
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                maxLength: 18,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9٠-٩۰-۹+()\-\s]'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'رقم الموبايل',
                  hintText: '01xxxxxxxxx',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (!AuthService.isValidEgyptianPhone(value ?? '')) {
                    return 'اكتب رقم موبايل مصري صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'كلمة مرور حساب الصنايعي',
                  hintText: '6 أحرف على الأقل',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'كلمتا المرور غير متطابقتين';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'هتستخدم رقم الموبايل وكلمة المرور للدخول كصنايعي بعد قبول الطلب.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                value: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'الحرفة أو التخصص',
                  prefixIcon: Icon(Icons.home_repair_service_outlined),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: categories.isEmpty
                    ? null
                    : (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'اختار الحرفة أو التخصص' : null,
              ),
              if (categories.isEmpty) ...<Widget>[
                const SizedBox(height: 6),
                const Text(
                  'جاري تحميل قائمة الحرف…',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                value: _governorate,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: EgyptLocations.areas.keys
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
                    _area = EgyptLocations.areas[value]!.first;
                  });
                },
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(_governorate),
                value: _area,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'المدينة أو المركز',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: EgyptLocations.areas[_governorate]!
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _area = value ?? _area),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.powderGreen,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'لن يظهر حسابك للعملاء إلا بعد مراجعة الإدارة والموافقة وتفعيل الاشتراك الشهري 50 جنيه.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'إرسال طلب الانضمام',
                icon: Icons.send_rounded,
                isLoading: state.submitting,
                onPressed: state.submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _normalizedPhone(String value) {
    return AuthService.normalizeEgyptianPhone(value);
  }
}
