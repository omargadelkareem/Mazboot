import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/address.dart';
import '../../models/customer_profile.dart';
import '../../repositories/customer_repository.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.profile,
    this.loading = true,
    this.saving = false,
    this.message,
  });

  final CustomerProfile? profile;
  final bool loading;
  final bool saving;
  final String? message;

  ProfileState copyWith({
    CustomerProfile? profile,
    bool? loading,
    bool? saving,
    String? message,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      message: message,
    );
  }

  @override
  List<Object?> get props => <Object?>[profile, loading, saving, message];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.repository) : super(const ProfileState());

  final CustomerRepository repository;
  StreamSubscription<CustomerProfile?>? _subscription;

  void start() {
    if (_subscription != null) return;
    _subscription = repository.watchProfile().listen(
      (profile) => emit(state.copyWith(profile: profile, loading: false)),
      onError: (_) => emit(
        state.copyWith(loading: false, message: 'تعذر تحميل بيانات الحساب.'),
      ),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!isClosed) emit(const ProfileState());
  }

  Future<bool> saveBasic({required String name, String? avatarBase64}) async {
    final current = state.profile;
    if (current == null) return false;
    emit(state.copyWith(saving: true));
    try {
      await repository.saveProfile(
        current.copyWith(
          name: name.trim(),
          avatarBase64: avatarBase64 ?? current.avatarBase64,
        ),
      );
      emit(state.copyWith(saving: false));
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          saving: false,
          message: 'تعذر حفظ البيانات. حاول مرة أخرى.',
        ),
      );
      return false;
    }
  }

  Future<bool> saveLocation({
    required String governorate,
    required String area,
  }) async {
    emit(state.copyWith(saving: true));
    try {
      final current = state.profile ?? await repository.loadProfile();
      if (current == null) {
        emit(
          state.copyWith(
            saving: false,
            message: 'تعذر تحميل بيانات الحساب. سجّل الدخول مرة أخرى.',
          ),
        );
        return false;
      }
      await repository.saveProfile(
        current.copyWith(governorate: governorate, area: area),
      );
      emit(state.copyWith(saving: false));
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          saving: false,
          message: 'تعذر حفظ الموقع. حاول مرة أخرى.',
        ),
      );
      return false;
    }
  }

  Future<bool> saveAddress(CustomerAddress address) async {
    try {
      await repository.saveAddress(address);
      return true;
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حفظ العنوان.'));
      return false;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await repository.deleteAddress(addressId);
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حذف العنوان.'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
