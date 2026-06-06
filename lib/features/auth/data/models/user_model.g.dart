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
  fcmToken: json['fcmToken'] as String? ?? '',
  isOnline: json['isOnline'] as bool? ?? false,
  lastSeen: const TimestampConverter().fromJson(json['last_seen']),
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  blockedUsers:
      (json['blockedUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  mutedUsers:
      (json['mutedUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'about': instance.about,
      'birthdate': instance.birthdate,
      'fcmToken': instance.fcmToken,
      'isOnline': instance.isOnline,
      'last_seen': const TimestampConverter().toJson(instance.lastSeen),
      'created_at': const TimestampConverter().toJson(instance.createdAt),
      'blockedUsers': instance.blockedUsers,
      'mutedUsers': instance.mutedUsers,
    };
