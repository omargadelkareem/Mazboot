import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/app_notification.dart';
import '../../repositories/customer_repository.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const <AppNotification>[],
    this.loading = true,
  });

  final List<AppNotification> items;
  final bool loading;

  int get unreadCount => items.where((item) => !item.isRead).length;

  @override
  List<Object?> get props => <Object?>[items, loading];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this.repository) : super(const NotificationsState());

  final CustomerRepository repository;
  StreamSubscription<List<AppNotification>>? _subscription;

  void start() {
    if (_subscription != null) return;
    _subscription = repository.watchNotifications().listen(
      (items) => emit(NotificationsState(items: items, loading: false)),
      onError: (_) => emit(const NotificationsState(loading: false)),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!isClosed) emit(const NotificationsState());
  }

  Future<void> markRead(String id) => repository.markNotificationRead(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
