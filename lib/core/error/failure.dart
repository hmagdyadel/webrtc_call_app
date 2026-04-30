import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const factory Failure.network({required String message}) = NetworkFailure;
  const factory Failure.server({
    required String message,
    int? statusCode,
  }) = ServerFailure;
  const factory Failure.auth({required String message}) = AuthFailure;
  const factory Failure.unknown({required String message}) = UnknownFailure;
}