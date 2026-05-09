import 'package:injectable/injectable.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../sources/chat_remote_source.dart';

abstract class ChatRepository {
  Stream<List<ChatModel>> getChats(String userId);
  Future<String> createOrGetChat(String currentUserId, String otherUserId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(String chatId, MessageModel message);
  Future<void> markChatAsRead(String chatId, String currentUserId);
  Future<String> uploadMedia(String filePath, String storagePath, {Function(double)? onProgress});
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

  @override
  Stream<List<MessageModel>> getMessages(String chatId) =>
      _source.getMessages(chatId);

  @override
  Future<void> sendMessage(String chatId, MessageModel message) =>
      _source.sendMessage(chatId, message);

  @override
  Future<void> markChatAsRead(String chatId, String currentUserId) =>
      _source.markChatAsRead(chatId, currentUserId);

  @override
  Future<String> uploadMedia(String filePath, String storagePath, {Function(double)? onProgress}) =>
      _source.uploadMedia(filePath, storagePath, onProgress: onProgress);
}