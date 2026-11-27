import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/chat_message.dart';
import '../../repositories/customer_repository.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.loading = true,
    this.sending = false,
    this.message,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final String? message;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    String? message,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      message: message,
    );
  }

  @override
  List<Object?> get props => <Object?>[messages, loading, sending, message];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required this.repository,
    required this.orderId,
    required this.technicianId,
  }) : super(const ChatState()) {
    _subscription = repository
        .watchMessages(orderId)
        .listen(
          (messages) =>
              emit(state.copyWith(messages: messages, loading: false)),
          onError: (_) => emit(
            state.copyWith(loading: false, message: 'تعذر تحميل الرسائل.'),
          ),
        );
  }

  final CustomerRepository repository;
  final String orderId;
  final String technicianId;
  StreamSubscription<List<ChatMessage>>? _subscription;

  Future<bool> send(String text, {String? imageBase64}) async {
    if (text.trim().isEmpty && imageBase64 == null) return false;
    emit(state.copyWith(sending: true));
    try {
      await repository.sendMessage(
        orderId: orderId,
        technicianId: technicianId,
        text: text.trim(),
        imageBase64: imageBase64,
      );
      emit(state.copyWith(sending: false));
      return true;
    } catch (_) {
      emit(state.copyWith(sending: false, message: 'تعذر إرسال الرسالة.'));
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
