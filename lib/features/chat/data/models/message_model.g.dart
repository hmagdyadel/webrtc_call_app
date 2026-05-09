// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(Map<String, dynamic> json) =>
    _MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
      status: json['status'] as String? ?? 'sent',
      mediaUrl: json['mediaUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'text': instance.text,
      'type': instance.type,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'status': instance.status,
      'mediaUrl': instance.mediaUrl,
      'metadata': instance.metadata,
    };
