import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String phone,
    @Default('') String name,
    @Default('') String avatarUrl,
    @Default('') String about,
    @Default('') String birthdate,
    @Default(false) bool isOnline,
    @TimestampConverter() @JsonKey(name: 'last_seen') DateTime? lastSeen,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) => date != null ? Timestamp.fromDate(date) : null;
}