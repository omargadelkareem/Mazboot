import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/auth_service.dart';
import '../../models/customer_profile.dart';
import '../../repositories/customer_repository.dart';

enum AuthStatus {
  initial,
  checking,
  unauthenticated,
  authenticating,
  sendingCode,
  codeSent,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.phone = '',
    this.session,
    this.message,
  });

  final AuthStatus status;
  final String phone;
  final OtpSession? session;
  final String? message;

  bool get isBusy =>
      status == AuthStatus.checking ||
      status == AuthStatus.authenticating ||
      status == AuthStatus.sendingCode;

  @override
  List<Object?> get props => <Object?>[status, phone, session, message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.authService, required this.repository})
    : super(const AuthState());

  final AuthService authService;
  final CustomerRepository repository;

  Future<void> checkSession() async {
    emit(const AuthState(status: AuthStatus.checking));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(
      AuthState(
        status: authService.currentUid == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        phone: authService.currentPhone,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final identity = await authService.signInWithGoogle();
      await _ensureProfile(identity.phone, identity: identity);
      emit(AuthState(status: AuthStatus.authenticated, phone: identity.phone));
    } catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: authService.friendlyError(error),
        ),
      );
    }
  }

  Future<void> signInAsGuest() async {
    emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final identity = await authService.signInAsGuest();
      await _ensureProfile(identity.phone, identity: identity);
      emit(AuthState(status: AuthStatus.authenticated, phone: identity.phone));
    } catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: authService.friendlyError(error),
        ),
      );
    }
  }

  Future<void> sendCode(String rawPhone, {int? resendToken}) async {
    late final String phone;
    try {
      phone = AuthService.normalizeEgyptianPhone(rawPhone);
    } on AuthException catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.message,
        ),
      );
      return;
    }
    emit(
      AuthState(
        status: AuthStatus.sendingCode,
        phone: phone,
        session: state.session,
      ),
    );
    try {
      await authService.saveDemoPhone(phone);
      final session = await authService.sendOtp(
        phone,
        forceResendingToken: resendToken,
      );
      if (session.autoVerifiedUid != null) {
        await _ensureProfile(phone);
        emit(AuthState(status: AuthStatus.authenticated, phone: phone));
        return;
      }
      emit(
        AuthState(status: AuthStatus.codeSent, phone: phone, session: session),
      );
    } catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          phone: phone,
          session: state.session,
          message: authService.friendlyError(error),
        ),
      );
    }
  }

  Future<void> confirmCode(String code) async {
    final session = state.session;
    if (session == null) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: 'اطلب رمز تحقق جديد وحاول مرة أخرى',
        ),
      );
      return;
    }
    if (code.trim().length < 4) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          phone: state.phone,
          session: session,
          message: 'اكتب رمز التحقق كاملًا',
        ),
      );
      return;
    }
    final phone = state.phone;
    emit(
      AuthState(status: AuthStatus.sendingCode, phone: phone, session: session),
    );
    try {
      await authService.confirmOtp(session: session, code: code.trim());
      await _ensureProfile(phone);
      emit(AuthState(status: AuthStatus.authenticated, phone: phone));
    } catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          phone: phone,
          session: session,
          message: authService.friendlyError(error),
        ),
      );
    }
  }

  Future<void> resendCode() =>
      sendCode(state.phone, resendToken: state.session?.resendToken);

  void editPhone() =>
      emit(AuthState(status: AuthStatus.unauthenticated, phone: state.phone));

  Future<void> signOut() async {
    await authService.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _ensureProfile(String phone, {AuthIdentity? identity}) async {
    final existing = await repository.loadProfile();
    final googleName = identity?.name.trim() ?? '';
    if (existing != null) {
      if (identity != null && !identity.isGuest) {
        await repository.saveProfile(
          existing.copyWith(
            name: googleName.length >= 2 ? googleName : existing.name,
            phone: identity.phone.isNotEmpty ? identity.phone : existing.phone,
            email: identity.email,
            avatarUrl: identity.photoUrl,
          ),
        );
      }
      return;
    }
    await repository.saveProfile(
      CustomerProfile(
        uid: repository.currentUid,
        name: googleName.length >= 2 ? googleName : 'عميل مظبوط',
        phone: phone,
        email: identity?.email ?? '',
        avatarUrl: identity?.photoUrl,
        governorate: '',
        area: '',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

}
