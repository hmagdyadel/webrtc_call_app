import 'package:freezed_annotation/freezed_annotation.dart';
import '../../auth/data/models/user_model.dart';

part 'contacts_state.freezed.dart';

@freezed
abstract class ContactsState with _$ContactsState {
  const factory ContactsState.initial() = _Initial;
  const factory ContactsState.loading() = _Loading;
  const factory ContactsState.loaded(List<UserModel> users) = _Loaded;
  const factory ContactsState.error(String message) = _Error;
}
