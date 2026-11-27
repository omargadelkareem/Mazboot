import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/service_order.dart';
import '../../models/technician.dart';
import '../../repositories/customer_repository.dart';

class OrdersState extends Equatable {
  const OrdersState({
    this.orders = const <ServiceOrder>[],
    this.loading = true,
    this.actionLoading = false,
    this.cancellationRequestedIds = const <String>{},
    this.message,
  });

  final List<ServiceOrder> orders;
  final bool loading;
  final bool actionLoading;
  final Set<String> cancellationRequestedIds;
  final String? message;

  OrdersState copyWith({
    List<ServiceOrder>? orders,
    bool? loading,
    bool? actionLoading,
    Set<String>? cancellationRequestedIds,
    String? message,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      actionLoading: actionLoading ?? this.actionLoading,
      cancellationRequestedIds:
          cancellationRequestedIds ?? this.cancellationRequestedIds,
      message: message,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    orders,
    loading,
    actionLoading,
    cancellationRequestedIds,
    message,
  ];
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this.repository) : super(const OrdersState());

  final CustomerRepository repository;
  StreamSubscription<List<ServiceOrder>>? _subscription;

  void start() {
    if (_subscription != null) return;
    _subscription = repository.watchOrders().listen(
      (orders) => emit(state.copyWith(orders: orders, loading: false)),
      onError: (_) => emit(
        state.copyWith(
          loading: false,
          message: 'تعذر تحميل الطلبات. تأكد من الإنترنت وحاول تاني.',
        ),
      ),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!isClosed) emit(const OrdersState());
  }

  Future<ServiceOrder?> create({
    required Technician technician,
    required String problem,
    required String address,
    required String date,
    required String time,
    String? problemImageBase64,
  }) async {
    emit(state.copyWith(actionLoading: true));
    try {
      final order = await repository.createOrder(
        ServiceOrder(
          id: '',
          technicianId: technician.id,
          categoryId: technician.categoryId,
          problem: problem,
          address: address,
          date: date,
          time: time,
          visitFee: 0,
          status: ServiceOrderStatus.sent,
          problemImageBase64: problemImageBase64,
        ),
      );
      emit(state.copyWith(actionLoading: false));
      return order;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          message: 'تعذر إرسال الطلب. راجع البيانات وحاول مرة أخرى.',
        ),
      );
      return null;
    }
  }

  Future<bool> cancel(String orderId, String reason) async {
    emit(state.copyWith(actionLoading: true));
    try {
      await repository.requestCancellation(orderId, reason);
      emit(
        state.copyWith(
          actionLoading: false,
          cancellationRequestedIds: <String>{
            ...state.cancellationRequestedIds,
            orderId,
          },
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          message: 'تعذر إرسال طلب الإلغاء، حاول مرة أخرى.',
        ),
      );
      return false;
    }
  }

  Future<bool> review({
    required ServiceOrder order,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    try {
      await repository.submitReview(
        orderId: order.id,
        technicianId: order.technicianId,
        customerName: customerName,
        rating: rating,
        comment: comment,
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          message: error.toString().replaceFirst('Bad state: ', ''),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
