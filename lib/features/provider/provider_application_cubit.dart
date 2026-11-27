import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/auth_service.dart';
import '../../models/provider_application.dart';
import '../../repositories/provider_application_repository.dart';

class ProviderApplicationState extends Equatable {
  const ProviderApplicationState({
    this.application,
    this.loading = false,
    this.submitting = false,
    this.submitted = false,
    this.message,
  });

  final ProviderApplication? application;
  final bool loading;
  final bool submitting;
  final bool submitted;
  final String? message;

  ProviderApplicationState copyWith({
    ProviderApplication? application,
    bool? loading,
    bool? submitting,
    bool? submitted,
    String? message,
  }) {
    return ProviderApplicationState(
      application: application ?? this.application,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      message: message,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    application,
    loading,
    submitting,
    submitted,
    message,
  ];
}

class ProviderApplicationCubit extends Cubit<ProviderApplicationState> {
  ProviderApplicationCubit({
    required this.repository,
    required this.authService,
  }) : super(const ProviderApplicationState());

  final ProviderApplicationRepository repository;
  final AuthService authService;
  StreamSubscription<ProviderApplication?>? _subscription;

  Future<void> start() async {
    emit(state.copyWith(loading: true));
    try {
      if (!authService.hasProviderSession) {
        emit(
          state.copyWith(
            loading: false,
            message: 'سجّل دخول بحساب الصنايعي لمتابعة طلب الانضمام.',
          ),
        );
        return;
      }
      await _subscription?.cancel();
      _subscription = repository.watchCurrentApplication().listen(
        (application) =>
            emit(state.copyWith(application: application, loading: false)),
        onError: (_) => emit(
          state.copyWith(
            loading: false,
            message: 'تعذر تحميل حالة طلب الانضمام.',
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(loading: false, message: 'تعذر بدء جلسة طلب الانضمام.'),
      );
    }
  }

  Future<bool> submit({
    required String name,
    required String phone,
    required String categoryId,
    required String governorate,
    required String area,
    required String photoBase64,
    required String password,
  }) async {
    emit(state.copyWith(submitting: true, submitted: false));
    try {
      await authService.registerProvider(
        phone: phone,
        password: password,
        name: name,
      );
      final application = await repository.submit(
        name: name,
        phone: phone,
        categoryId: categoryId,
        governorate: governorate,
        area: area,
        photoBase64: photoBase64,
      );
      emit(
        state.copyWith(
          application: application,
          submitting: false,
          submitted: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          submitting: false,
          submitted: false,
          message: _messageFrom(error),
        ),
      );
      return false;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  String _messageFrom(Object error) {
    if (error is AuthException || error is FirebaseAuthException) {
      return authService.friendlyError(error);
    }
    final value = error.toString().replaceFirst('Bad state: ', '');
    if (value.trim().isNotEmpty) return value;
    return 'تعذر إرسال الطلب. حاول مرة أخرى.';
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
