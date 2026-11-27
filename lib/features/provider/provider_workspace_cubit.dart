import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/provider_conversation.dart';
import '../../models/service_order.dart';
import '../../models/technician.dart';
import '../../repositories/provider_repository.dart';

class ProviderWorkspaceState extends Equatable {
  const ProviderWorkspaceState({
    this.profile,
    this.orders = const <ServiceOrder>[],
    this.conversations = const <ProviderConversation>[],
    this.loading = true,
    this.saving = false,
    this.message,
  });

  final Technician? profile;
  final List<ServiceOrder> orders;
  final List<ProviderConversation> conversations;
  final bool loading;
  final bool saving;
  final String? message;

  List<ServiceOrder> get incoming =>
      orders.where((order) => order.status == ServiceOrderStatus.sent).toList();

  List<ServiceOrder> get active => orders
      .where(
        (order) =>
            order.status == ServiceOrderStatus.accepted ||
            order.status == ServiceOrderStatus.onTheWay ||
            order.status == ServiceOrderStatus.inProgress,
      )
      .toList();

  List<ServiceOrder> get completed => orders
      .where((order) => order.status == ServiceOrderStatus.completed)
      .toList();

  List<ServiceOrder> get cancelled => orders
      .where((order) => order.status == ServiceOrderStatus.cancelled)
      .toList();

  int get unreadMessages => conversations.fold<int>(
    0,
    (total, conversation) => total + conversation.unreadCount,
  );

  ServiceOrder? orderById(String id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  ProviderWorkspaceState copyWith({
    Technician? profile,
    List<ServiceOrder>? orders,
    List<ProviderConversation>? conversations,
    bool? loading,
    bool? saving,
    String? message,
    bool clearMessage = false,
  }) {
    return ProviderWorkspaceState(
      profile: profile ?? this.profile,
      orders: orders ?? this.orders,
      conversations: conversations ?? this.conversations,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    profile,
    orders,
    conversations,
    loading,
    saving,
    message,
  ];
}

class ProviderWorkspaceCubit extends Cubit<ProviderWorkspaceState> {
  ProviderWorkspaceCubit(this.repository)
    : super(const ProviderWorkspaceState());

  final ProviderRepository repository;
  StreamSubscription<Technician?>? _profileSubscription;
  StreamSubscription<List<ServiceOrder>>? _ordersSubscription;
  StreamSubscription<List<ProviderConversation>>? _conversationSubscription;

  Future<void> start() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    await stop(reset: false);
    try {
      _profileSubscription = repository.watchProfile().listen(
        (profile) => emit(state.copyWith(profile: profile, loading: false)),
        onError: (_) => _emitError('تعذر تحميل ملف الصنايعي.'),
      );
      _ordersSubscription = repository.watchOrders().listen(
        (orders) => emit(state.copyWith(orders: orders, loading: false)),
        onError: (_) => _emitError('تعذر تحميل الطلبات.'),
      );
      _conversationSubscription = repository.watchConversations().listen(
        (conversations) =>
            emit(state.copyWith(conversations: conversations, loading: false)),
        onError: (_) => _emitError('تعذر تحميل المحادثات.'),
      );
    } catch (_) {
      _emitError('تعذر فتح لوحة الصنايعي. حاول مرة أخرى.');
    }
  }

  Future<void> setAvailability(bool available) async {
    final profile = state.profile;
    if (profile == null || state.saving) return;
    emit(
      state.copyWith(
        profile: profile.copyWith(isAvailable: available),
        saving: true,
        clearMessage: true,
      ),
    );
    try {
      await repository.setAvailability(available);
      emit(state.copyWith(saving: false, clearMessage: true));
    } catch (_) {
      emit(
        state.copyWith(
          profile: profile,
          saving: false,
          message: 'تعذر تحديث حالة استقبال الطلبات.',
        ),
      );
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
    required int experienceYears,
    required List<String> services,
  }) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearMessage: true));
    try {
      await repository.updateProfile(
        name: name,
        bio: bio,
        experienceYears: experienceYears,
        services: services,
      );
      emit(state.copyWith(saving: false, clearMessage: true));
      return true;
    } catch (_) {
      emit(
        state.copyWith(saving: false, message: 'تعذر حفظ بيانات الملف الشخصي.'),
      );
      return false;
    }
  }

  Future<bool> updateOrderStatus(
    String orderId,
    ServiceOrderStatus status,
  ) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearMessage: true));
    try {
      await repository.updateOrderStatus(orderId, status);
      emit(state.copyWith(saving: false, clearMessage: true));
      return true;
    } catch (error) {
      final message = error.toString().replaceFirst('Bad state: ', '');
      emit(
        state.copyWith(
          saving: false,
          message: message.isEmpty ? 'تعذر تحديث حالة الطلب.' : message,
        ),
      );
      return false;
    }
  }

  void clearMessage() => emit(state.copyWith(clearMessage: true));

  Future<void> stop({bool reset = true}) async {
    await _profileSubscription?.cancel();
    await _ordersSubscription?.cancel();
    await _conversationSubscription?.cancel();
    _profileSubscription = null;
    _ordersSubscription = null;
    _conversationSubscription = null;
    if (reset && !isClosed) emit(const ProviderWorkspaceState());
  }

  void _emitError(String message) {
    if (!isClosed) emit(state.copyWith(loading: false, message: message));
  }

  @override
  Future<void> close() async {
    await stop(reset: false);
    return super.close();
  }
}
