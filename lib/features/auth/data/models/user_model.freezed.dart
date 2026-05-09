// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 String get id; String get phone; String get name; String get avatarUrl; String get about; String get birthdate; bool get isOnline;@TimestampConverter()@JsonKey(name: 'last_seen') DateTime? get lastSeen;@TimestampConverter()@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.birthdate, birthdate) || other.birthdate == birthdate)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phone,name,avatarUrl,about,birthdate,isOnline,lastSeen,createdAt);

@override
String toString() {
  return 'UserModel(id: $id, phone: $phone, name: $name, avatarUrl: $avatarUrl, about: $about, birthdate: $birthdate, isOnline: $isOnline, lastSeen: $lastSeen, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String id, String phone, String name, String avatarUrl, String about, String birthdate, bool isOnline,@TimestampConverter()@JsonKey(name: 'last_seen') DateTime? lastSeen,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phone = null,Object? name = null,Object? avatarUrl = null,Object? about = null,Object? birthdate = null,Object? isOnline = null,Object? lastSeen = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String,birthdate: null == birthdate ? _self.birthdate : birthdate // ignore: cast_nullable_to_non_nullable
as String,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String phone,  String name,  String avatarUrl,  String about,  String birthdate,  bool isOnline, @TimestampConverter()@JsonKey(name: 'last_seen')  DateTime? lastSeen, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.phone,_that.name,_that.avatarUrl,_that.about,_that.birthdate,_that.isOnline,_that.lastSeen,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String phone,  String name,  String avatarUrl,  String about,  String birthdate,  bool isOnline, @TimestampConverter()@JsonKey(name: 'last_seen')  DateTime? lastSeen, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.phone,_that.name,_that.avatarUrl,_that.about,_that.birthdate,_that.isOnline,_that.lastSeen,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String phone,  String name,  String avatarUrl,  String about,  String birthdate,  bool isOnline, @TimestampConverter()@JsonKey(name: 'last_seen')  DateTime? lastSeen, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.phone,_that.name,_that.avatarUrl,_that.about,_that.birthdate,_that.isOnline,_that.lastSeen,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({required this.id, required this.phone, this.name = '', this.avatarUrl = '', this.about = '', this.birthdate = '', this.isOnline = false, @TimestampConverter()@JsonKey(name: 'last_seen') this.lastSeen, @TimestampConverter()@JsonKey(name: 'created_at') this.createdAt});
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  String id;
@override final  String phone;
@override@JsonKey() final  String name;
@override@JsonKey() final  String avatarUrl;
@override@JsonKey() final  String about;
@override@JsonKey() final  String birthdate;
@override@JsonKey() final  bool isOnline;
@override@TimestampConverter()@JsonKey(name: 'last_seen') final  DateTime? lastSeen;
@override@TimestampConverter()@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.birthdate, birthdate) || other.birthdate == birthdate)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phone,name,avatarUrl,about,birthdate,isOnline,lastSeen,createdAt);

@override
String toString() {
  return 'UserModel(id: $id, phone: $phone, name: $name, avatarUrl: $avatarUrl, about: $about, birthdate: $birthdate, isOnline: $isOnline, lastSeen: $lastSeen, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String phone, String name, String avatarUrl, String about, String birthdate, bool isOnline,@TimestampConverter()@JsonKey(name: 'last_seen') DateTime? lastSeen,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phone = null,Object? name = null,Object? avatarUrl = null,Object? about = null,Object? birthdate = null,Object? isOnline = null,Object? lastSeen = freezed,Object? createdAt = freezed,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String,birthdate: null == birthdate ? _self.birthdate : birthdate // ignore: cast_nullable_to_non_nullable
as String,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
