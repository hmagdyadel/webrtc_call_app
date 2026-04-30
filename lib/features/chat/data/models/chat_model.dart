import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
abstract class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String id,
    required List<String> members,
    @Default('') String lastMessage,
    @Default('') String lastMessageSenderId,
    @JsonKey(name: 'last_message_time') DateTime? lastMessageTime,
    @Default(0) int unreadCount,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);
}