import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/message_model.dart';

part 'message_state.freezed.dart';

@freezed
abstract class MessageState with _$MessageState {
  const factory MessageState.initial() = _Initial;
  const factory MessageState.loading() = _Loading;
  const factory MessageState.loaded({
    required List<MessageModel> messages,
    @Default([]) List<MessageModel> localMessages,
    @Default({}) Map<String, double> uploadProgress,
  }) = _Loaded;
  const factory MessageState.error({required String message}) = _Error;
}
