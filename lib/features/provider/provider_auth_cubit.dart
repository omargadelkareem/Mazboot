import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/auth_service.dart';
import '../../models/provider_application.dart';
import '../../repositories/provider_application_repository.dart';

enum ProviderAccessStatus {
  initial,
  loading,
  unauthenticated,
  noApplication,
  pending,
  approved,
  inactive,
  rejected,
  failure,
}

class ProviderAuthState extends Equatable {
  const ProviderAuthState({
    this.status = ProviderAccessStatus.initial,
    this.application,
    this.message,
  });

  final ProviderAccessStatus status;
  final ProviderApplication? application;
  final String? message;

  bool get isBusy => status == ProviderAccessStatus.loading;

  @override
  List<Object?> get props => <Object?>[status, application, message];
}

class ProviderAuthCubit extends Cubit<ProviderAuthState> {
  ProviderAuthCubit({required this.authService, required this.repository})
    : super(const ProviderAuthState());

  final AuthService authService;
  final ProviderApplicationRepository repository;

  Future<void> checkSession() async {
    if (!authService.hasProviderSession) {
      emit(
        const ProviderAuthState(status: ProviderAccessStatus.unauthenticated),
      );
      return;
    }
    await _loadApplication();
  }

  Future<void> signIn({required String phone, required String password}) async {
    emit(const ProviderAuthState(status: ProviderAccessStatus.loading));
    try {
      await authService.signInProvider(phone: phone, password: password);
      await _loadApplication();
    } catch (error) {
      emit(
        ProviderAuthState(
          status: ProviderAccessStatus.failure,
          message: authService.friendlyError(error),
        ),
      );
    }
  }

  Future<void> refresh() => _loadApplication();

  Future<void> signOut() async {
    await authService.signOut();
    emit(const ProviderAuthState(status: ProviderAccessStatus.unauthenticated));
  }

  Future<void> _loadApplication() async {
    emit(
      ProviderAuthState(
        status: ProviderAccessStatus.loading,
        application: state.application,
      ),
    );
    try {
      final application = await repository.loadCurrentApplication();
      if (application == null) {
        emit(
          const ProviderAuthState(status: ProviderAccessStatus.noApplication),
        );
        return;
      }
      final status = switch (application.status) {
        ProviderApplicationStatus.pending => ProviderAccessStatus.pending,
        ProviderApplicationStatus.rejected => ProviderAccessStatus.rejected,
        ProviderApplicationStatus.approved when application.isFullyActive =>
          ProviderAccessStatus.approved,
        ProviderApplicationStatus.approved => ProviderAccessStatus.inactive,
      };
      emit(ProviderAuthState(status: status, application: application));
    } catch (_) {
      emit(
        const ProviderAuthState(
          status: ProviderAccessStatus.failure,
          message: 'تعذر تحميل حالة حساب الصنايعي. حاول مرة أخرى.',
        ),
      );
    }
  }
}
