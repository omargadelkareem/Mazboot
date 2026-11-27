import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/conversation.dart';
import '../../repositories/customer_repository.dart';

class ConversationsState extends Equatable {
  const ConversationsState({
    this.items = const <Conversation>[],
    this.loading = true,
    this.message,
  });

  final List<Conversation> items;
  final bool loading;
  final String? message;

  @override
  List<Object?> get props => <Object?>[items, loading, message];
}

class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(this.repository) : super(const ConversationsState());

  final CustomerRepository repository;
  StreamSubscription<List<Conversation>>? _subscription;

  void start() {
    if (_subscription != null) return;
    _subscription = repository.watchConversations().listen(
      (items) => emit(ConversationsState(items: items, loading: false)),
      onError: (_) => emit(
        const ConversationsState(
          loading: false,
          message: 'تعذر تحميل المحادثات.',
        ),
      ),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!isClosed) emit(const ConversationsState());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
