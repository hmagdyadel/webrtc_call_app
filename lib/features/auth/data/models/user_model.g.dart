// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  phone: json['phone'] as String,
  name: json['name'] as String? ?? '',
  avatarUrl: json['avatarUrl'] as String? ?? '',
  about: json['about'] as String? ?? '',
  birthdate: json['birthdate'] as String? ?? '',
  isOnline: json['isOnline'] as bool? ?? false,
  lastSeen: json['last_seen'] == null
      ? null
      : DateTime.parse(json['last_seen'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'about': instance.about,
      'birthdate': instance.birthdate,
      'isOnline': instance.isOnline,
      'last_seen': instance.lastSeen?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
