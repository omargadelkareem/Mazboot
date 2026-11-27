import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/chat_message.dart';
import '../../repositories/provider_repository.dart';

class ProviderChatState extends Equatable {
  const ProviderChatState({
    this.messages = const <ChatMessage>[],
    this.loading = true,
    this.sending = false,
    this.message,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final String? message;

  ProviderChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    String? message,
  }) {
    return ProviderChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      message: message,
    );
  }

  @override
  List<Object?> get props => <Object?>[messages, loading, sending, message];
}

class ProviderChatCubit extends Cubit<ProviderChatState> {
  ProviderChatCubit({
    required this.repository,
    required this.orderId,
    required this.customerId,
  }) : super(const ProviderChatState());

  final ProviderRepository repository;
  final String orderId;
  final String customerId;
  StreamSubscription<List<ChatMessage>>? _subscription;

  void start() {
    _subscription?.cancel();
    _subscription = repository
        .watchMessages(orderId)
        .listen(
          (messages) =>
              emit(ProviderChatState(messages: messages, loading: false)),
          onError: (_) => emit(
            const ProviderChatState(
              loading: false,
              message: 'تعذر تحميل المحادثة.',
            ),
          ),
        );
  }

  Future<bool> send(String text, {String? imageBase64}) async {
    if (state.sending || (text.trim().isEmpty && imageBase64 == null)) {
      return false;
    }
    emit(state.copyWith(sending: true));
    try {
      await repository.sendMessage(
        orderId: orderId,
        customerId: customerId,
        text: text,
        imageBase64: imageBase64,
      );
      emit(state.copyWith(sending: false));
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          sending: false,
          message: 'تعذر إرسال الرسالة. حاول مرة أخرى.',
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
