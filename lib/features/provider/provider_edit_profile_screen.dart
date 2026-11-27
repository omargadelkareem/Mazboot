import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/primary_button.dart';
import 'provider_workspace_cubit.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _experienceController;
  late final TextEditingController _servicesController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProviderWorkspaceCubit>().state.profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _experienceController = TextEditingController(
      text: '${profile?.experienceYears ?? 0}',
    );
    _servicesController = TextEditingController(
      text: profile?.services.join('\n') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final services = _servicesController.text
        .split(RegExp(r'[\n،,]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(12)
        .toList();
    final saved = await context.read<ProviderWorkspaceCubit>().updateProfile(
      name: _nameController.text,
      bio: _bioController.text,
      experienceYears: int.tryParse(_experienceController.text) ?? 0,
      services: services,
    );
    if (!mounted) return;
    if (saved) {
      UiUtils.showSnackBar(context, 'تم حفظ بيانات ملفك المهني.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderWorkspaceCubit>().state;
    final profile = state.profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف المهني')),
        body: const Center(child: Text('تعذر تحميل الملف.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف المهني')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.powderBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.visibility_outlined, color: AppColors.navy),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'البيانات دي بتظهر للعملاء في ملفك العام. خليها واضحة ومختصرة وتعبّر عن شغلك الحقيقي.',
                        style: TextStyle(fontSize: 10, height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'الاسم الظاهر للعملاء',
                  counterText: '',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 3 ? 'اكتب اسم صحيح' : null,
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'سنوات الخبرة',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
                validator: (value) {
                  final years = int.tryParse(value ?? '');
                  if (years == null || years < 0 || years > 70) {
                    return 'اكتب عدد سنوات صحيح من 0 إلى 70';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _bioController,
                minLines: 4,
                maxLines: 7,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: 'نبذة عنك وعن خبرتك',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 74),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 10
                    ? 'اكتب نبذة أوضح عن خبرتك'
                    : null,
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _servicesController,
                minLines: 5,
                maxLines: 9,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: 'الخدمات التي تقدمها',
                  hintText: 'اكتب كل خدمة في سطر منفصل',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 95),
                    child: Icon(Icons.handyman_outlined),
                  ),
                ),
                validator: (value) {
                  final services = (value ?? '')
                      .split(RegExp(r'[\n،,]+'))
                      .where((item) => item.trim().isNotEmpty)
                      .toList();
                  if (services.isEmpty) return 'ضيف خدمة واحدة على الأقل';
                  if (services.any((item) => item.trim().length > 60)) {
                    return 'اسم كل خدمة لازم يكون أقل من 60 حرف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'الصورة والتخصص والمنطقة يتم تعديلهم عن طريق الإدارة حفاظًا على بيانات التوثيق.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'حفظ التعديلات',
                icon: Icons.save_outlined,
                isLoading: state.saving,
                onPressed: state.saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
