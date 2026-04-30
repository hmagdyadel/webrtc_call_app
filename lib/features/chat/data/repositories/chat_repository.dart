import 'package:injectable/injectable.dart';
import '../models/chat_model.dart';
import '../sources/chat_remote_source.dart';

abstract class ChatRepository {
  Stream<List<ChatModel>> getChats(String userId);
  Future<String> createOrGetChat(String currentUserId, String otherUserId);
}

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteSource _source;
  ChatRepositoryImpl(this._source);

  @override
  Stream<List<ChatModel>> getChats(String userId) =>
      _source.getChats(userId);

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) =>
      _source.createOrGetChat(currentUserId, otherUserId);
}