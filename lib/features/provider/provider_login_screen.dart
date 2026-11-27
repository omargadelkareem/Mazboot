import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/primary_button.dart';
import 'provider_auth_cubit.dart';

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({super.key});

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProviderAuthCubit>().checkSession();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<ProviderAuthCubit>().signIn(
      phone: _phoneController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProviderAuthCubit, ProviderAuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        switch (state.status) {
          case ProviderAccessStatus.approved:
            context.go('/provider/main');
          case ProviderAccessStatus.pending:
          case ProviderAccessStatus.inactive:
          case ProviderAccessStatus.rejected:
            context.go('/provider-review');
          case ProviderAccessStatus.noApplication:
            context.go('/provider-join');
          case ProviderAccessStatus.failure:
            if (state.message != null) {
              UiUtils.showSnackBar(context, state.message!);
            }
          case ProviderAccessStatus.initial:
          case ProviderAccessStatus.loading:
          case ProviderAccessStatus.unauthenticated:
            break;
        }
      },
      builder: (context, state) {
        final loading = state.isBusy;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: loading
                            ? null
                            : () => context.go('/role-selection'),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                      const Spacer(),
                      const BrandLogo(compact: true, markSize: 44),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(
                        color: AppColors.powderPeach,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: AppColors.navy,
                        size: 58,
                      ),
                    ),
                  ),
                  const SizedBox(height: 27),
                  Text(
                    'دخول الصنايعي',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'حساب الصنايعي منفصل عن حساب العميل. ادخل برقم الموبايل وكلمة المرور التي أنشأتها مع طلب الانضمام.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 27),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !loading,
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
                    enabled: !loading,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value ?? '').length < 6
                        ? 'اكتب كلمة المرور كاملة'
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: loading ? null : () => _showPasswordHelp(),
                      child: const Text('نسيت كلمة المرور؟'),
                    ),
                  ),
                  const SizedBox(height: 7),
                  PrimaryButton(
                    label: 'دخول حساب الصنايعي',
                    icon: Icons.login_rounded,
                    isLoading: loading,
                    onPressed: loading ? null : _submit,
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () => context.go('/provider-join'),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('تقديم طلب انضمام جديد'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.powderGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.success,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'لن تفتح واجهة الصنايعي إلا بعد موافقة الإدارة وتفعيل الاشتراك.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPasswordHelp() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استرجاع حساب الصنايعي'),
        content: const Text(
          'لأمان حسابك، تواصل مع إدارة Mazboot من رقم الموبايل المسجل علشان يتم التحقق وإعادة ضبط كلمة المرور.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }
}
