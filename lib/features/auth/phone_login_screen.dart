import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../repositories/customer_repository.dart';
import 'auth_cubit.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = context.read<CustomerRepository>().isDemo;
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/location');
        } else if (state.status == AuthStatus.failure &&
            state.message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final codeSent = state.session != null;
        final loading = state.isBusy;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height - 90,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Align(
                      alignment: Alignment.centerRight,
                      child: BrandLogo(compact: true, markSize: 44),
                    ),
                    const SizedBox(height: 54),
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.powderBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.navy,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      codeSent ? 'اكتب رمز التحقق' : 'أهلًا بيك في مظبوط',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      codeSent
                          ? 'أرسلنا رمز التحقق إلى ${state.phone}'
                          : 'سجّل برقم موبايلك علشان تطلب فني وتتابع الخدمة بسهولة.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (codeSent && isDemo) ...<Widget>[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Text(
                          'وضع المعاينة: رمز الدخول 1234',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    if (!codeSent)
                      TextField(
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
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      )
                    else
                      TextField(
                        controller: _otpController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 27,
                          letterSpacing: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: '••••••',
                        ),
                        onSubmitted: (_) => context
                            .read<AuthCubit>()
                            .confirmCode(_otpController.text),
                      ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: codeSent ? 'تأكيد ودخول' : 'إرسال رمز التحقق',
                      icon: codeSent
                          ? Icons.check_rounded
                          : Icons.arrow_back_rounded,
                      isLoading: loading,
                      onPressed: loading
                          ? null
                          : () {
                              if (codeSent) {
                                context.read<AuthCubit>().confirmCode(
                                  _otpController.text,
                                );
                              } else {
                                context.read<AuthCubit>().sendCode(
                                  _phoneController.text,
                                );
                              }
                            },
                    ),
                    if (codeSent) ...<Widget>[
                      TextButton(
                        onPressed: loading
                            ? null
                            : context.read<AuthCubit>().resendCode,
                        child: const Text('إعادة إرسال الرمز'),
                      ),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                _otpController.clear();
                                context.read<AuthCubit>().editPhone();
                              },
                        child: const Text('تغيير رقم الموبايل'),
                      ),
                    ],
                    const SizedBox(height: 70),
                    const Text(
                      'بالمتابعة أنت توافق على الشروط والأحكام وسياسة الخصوصية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
