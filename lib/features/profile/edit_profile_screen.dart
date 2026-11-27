import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/primary_button.dart';
import 'profile_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileCubit>().state.profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _avatarBase64 = profile?.avatarBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final image = await context.read<ImageService>().pickBase64(
        source: source,
      );
      if (!mounted || image == null) return;
      setState(() => _avatarBase64 = image);
    } on ImageTooLargeException {
      if (mounted)
        UiUtils.showSnackBar(context, 'الصورة أكبر من 900 كيلوبايت.');
    } catch (_) {
      if (mounted) UiUtils.showSnackBar(context, 'تعذر اختيار الصورة.');
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().length < 2) {
      UiUtils.showSnackBar(context, 'اكتب اسمك بشكل صحيح.');
      return;
    }
    final success = await context.read<ProfileCubit>().saveBasic(
      name: _nameController.text,
      avatarBase64: _avatarBase64,
    );
    if (!mounted) return;
    if (success) {
      context.pop();
    } else {
      UiUtils.showSnackBar(
        context,
        context.read<ProfileCubit>().state.message ?? 'تعذر حفظ البيانات.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state.profile;
    final bytes = context.read<ImageService>().decode(_avatarBase64);
    final saving = context.watch<ProfileCubit>().state.saving;
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل البيانات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 110,
                  height: 110,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.powderBlue,
                    shape: BoxShape.circle,
                  ),
                  child: bytes == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 55,
                          color: AppColors.navy,
                        )
                      : Image.memory(
                          bytes,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                ),
                PositionedDirectional(
                  end: -3,
                  bottom: 2,
                  child: IconButton.filled(
                    onPressed: () => _showPhotoOptions(context),
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 13),
          TextFormField(
            enabled: false,
            initialValue: profile?.phone ?? '',
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رقم الموبايل',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'رقم الموبايل مرتبط بتسجيل الدخول ولا يتغير من هنا.',
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'حفظ التعديلات',
            icon: Icons.check_rounded,
            isLoading: saving,
            onPressed: saving ? null : _save,
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من الصور'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
