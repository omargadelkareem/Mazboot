import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/service_category.dart';
import '../../models/technician.dart';
import '../../repositories/customer_repository.dart';

class HomeState extends Equatable {
  const HomeState({
    this.categories = const <ServiceCategory>[],
    this.technicians = const <Technician>[],
    this.loading = true,
    this.message,
  });

  final List<ServiceCategory> categories;
  final List<Technician> technicians;
  final bool loading;
  final String? message;

  HomeState copyWith({
    List<ServiceCategory>? categories,
    List<Technician>? technicians,
    bool? loading,
    String? message,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      technicians: technicians ?? this.technicians,
      loading: loading ?? this.loading,
      message: message,
    );
  }

  ServiceCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Technician? technicianById(String id) {
    for (final technician in technicians) {
      if (technician.id == id) return technician;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    categories,
    technicians,
    loading,
    message,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this.repository) : super(const HomeState()) {
    _categoriesSubscription = repository.watchCategories().listen(
      (categories) =>
          emit(state.copyWith(categories: categories, loading: false)),
      onError: _onError,
    );
    _techniciansSubscription = repository.watchTechnicians().listen(
      (technicians) =>
          emit(state.copyWith(technicians: technicians, loading: false)),
      onError: _onError,
    );
  }

  final CustomerRepository repository;
  StreamSubscription<List<ServiceCategory>>? _categoriesSubscription;
  StreamSubscription<List<Technician>>? _techniciansSubscription;

  void _onError(Object error) {
    if (!isClosed) {
      emit(
        state.copyWith(
          loading: false,
          message: 'تعذر تحميل الخدمات. اسحب وحاول تاني.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _categoriesSubscription?.cancel();
    await _techniciansSubscription?.cancel();
    return super.close();
  }
}
