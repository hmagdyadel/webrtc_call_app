import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/chat_model.dart';

part 'chat_state.freezed.dart';

@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState.initial() = _Initial;
  const factory ChatState.loading() = _Loading;
  const factory ChatState.loaded({required List<ChatModel> chats}) = _Loaded;
  const factory ChatState.error({required String message}) = _Error;
}