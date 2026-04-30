import 'package:injectable/injectable.dart';
import '../../../auth/data/models/user_model.dart';
import '../sources/contacts_remote_source.dart';

abstract class ContactsRepository {
  Future<List<UserModel>> getAllUsers(String currentUserId);
}

@LazySingleton(as: ContactsRepository)
class ContactsRepositoryImpl implements ContactsRepository {
  final ContactsRemoteSource _source;
  ContactsRepositoryImpl(this._source);

  @override
  Future<List<UserModel>> getAllUsers(String currentUserId) =>
      _source.getAllUsers(currentUserId);
}