import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../data/repositories/contacts_repository.dart';
import '../../auth/data/models/user_model.dart';
import 'contacts_state.dart';

@injectable
class ContactsCubit extends Cubit<ContactsState> {
  final ContactsRepository _repository;
  List<UserModel> _allUsers = [];

  ContactsCubit(this._repository) : super(const ContactsState.initial());

  Future<void> loadContacts(String currentUserId) async {
    emit(const ContactsState.loading());
    try {
      _allUsers = await _repository.getAllUsers(currentUserId);
      emit(ContactsState.loaded(_allUsers));
    } catch (e) {
      emit(ContactsState.error(e.toString()));
    }
  }

  void searchContacts(String query) {
    if (query.isEmpty) {
      emit(ContactsState.loaded(_allUsers));
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    final filteredUsers = _allUsers.where((user) {
      final nameMatches = user.name.toLowerCase().contains(lowerQuery);
      final phoneMatches = user.phone.toLowerCase().contains(lowerQuery);
      return nameMatches || phoneMatches;
    }).toList();
    
    emit(ContactsState.loaded(filteredUsers));
  }
}
