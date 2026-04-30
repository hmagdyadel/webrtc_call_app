import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../data/repositories/chat_repository.dart';
import 'chat_state.dart';

@injectable
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;

  ChatCubit(this._repository) : super(const ChatState.initial());

  void loadChats(String userId) {
    emit(const ChatState.loading());
    _repository.getChats(userId).listen(
          (chats) => emit(ChatState.loaded(chats: chats)),
      onError: (e) => emit(ChatState.error(message: e.toString())),
    );
  }
}