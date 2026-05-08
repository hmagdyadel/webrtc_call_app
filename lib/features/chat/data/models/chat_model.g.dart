// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => _ChatModel(
  id: json['id'] as String,
  members: (json['members'] as List<dynamic>).map((e) => e as String).toList(),
  lastMessage: json['lastMessage'] as String? ?? '',
  lastMessageSenderId: json['lastMessageSenderId'] as String? ?? '',
  lastMessageTime: const TimestampConverter().fromJson(
    json['last_message_time'],
  ),
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ChatModelToJson(_ChatModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'members': instance.members,
      'lastMessage': instance.lastMessage,
      'lastMessageSenderId': instance.lastMessageSenderId,
      'last_message_time': const TimestampConverter().toJson(
        instance.lastMessageTime,
      ),
      'unreadCount': instance.unreadCount,
    };
