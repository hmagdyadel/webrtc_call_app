import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import 'message_state.dart';

@injectable
class MessageCubit extends Cubit<MessageState> {
  final ChatRepository _repository;
  StreamSubscription<List<MessageModel>>? _subscription;

  MessageCubit(this._repository) : super(const MessageState.initial());

  void loadMessages(String chatId, String currentUserId) {
    emit(const MessageState.loading());
    _subscription?.cancel();
    _subscription = _repository.getMessages(chatId).listen(
      (messages) {
        emit(MessageState.loaded(messages: messages));
        // Whenever we receive new messages while the screen is open,
        // mark any unread messages from the other user as read.
        _repository.markChatAsRead(chatId, currentUserId);
      },
      onError: (e) => emit(MessageState.error(message: e.toString())),
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: senderId,
      text: text.trim(),
      type: 'text',
      timestamp: DateTime.now(),
      status: 'sent',
    );

    try {
      await _repository.sendMessage(chatId, message);
    } catch (e) {
      emit(MessageState.error(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
