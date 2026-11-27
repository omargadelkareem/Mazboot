import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/customer_repository.dart';

class FavoritesState extends Equatable {
  const FavoritesState({this.ids = const <String>{}, this.loading = false});

  final Set<String> ids;
  final bool loading;

  bool contains(String id) => ids.contains(id);

  @override
  List<Object?> get props => <Object?>[ids, loading];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this.repository) : super(const FavoritesState());

  final CustomerRepository repository;
  StreamSubscription<Set<String>>? _subscription;

  void start() {
    if (_subscription != null) return;
    _subscription = repository.watchFavorites().listen(
      (ids) => emit(FavoritesState(ids: ids)),
      onError: (_) => emit(FavoritesState(ids: state.ids)),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!isClosed) emit(const FavoritesState());
  }

  Future<void> toggle(String technicianId) async {
    final favorite = !state.contains(technicianId);
    final previous = Set<String>.from(state.ids);
    final optimistic = Set<String>.from(previous);
    favorite ? optimistic.add(technicianId) : optimistic.remove(technicianId);
    emit(FavoritesState(ids: optimistic, loading: true));
    try {
      await repository.setFavorite(technicianId, favorite: favorite);
    } catch (_) {
      emit(FavoritesState(ids: previous));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
