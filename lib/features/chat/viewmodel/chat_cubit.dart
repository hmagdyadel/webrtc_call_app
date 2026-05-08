import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../data/repositories/chat_repository.dart';
import 'chat_state.dart';

@injectable
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;
  StreamSubscription? _subscription;

  ChatCubit(this._repository) : super(const ChatState.initial());

  void loadChats(String userId) {
    debugPrint('🟢 ChatCubit.loadChats called with userId: "$userId"');
    if (userId.isEmpty) {
      debugPrint('🔴 ChatCubit: userId is empty!');
      emit(const ChatState.error(message: 'User ID is empty'));
      return;
    }
    emit(const ChatState.loading());
    _subscription?.cancel();
    _subscription = _repository.getChats(userId).listen(
      (chats) {
        debugPrint('🟢 ChatCubit: received ${chats.length} chats');
        emit(ChatState.loaded(chats: chats));
      },
      onError: (e) {
        debugPrint('🔴 ChatCubit error: $e');
        emit(ChatState.error(message: e.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}