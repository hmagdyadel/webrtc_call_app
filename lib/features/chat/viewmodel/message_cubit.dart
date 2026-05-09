import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import 'message_state.dart';

@injectable
class MessageCubit extends Cubit<MessageState> {
  final ChatRepository _repository;
  StreamSubscription<List<MessageModel>>? _subscription;

  MessageCubit(this._repository) : super(const MessageState.initial());

  void loadMessages(String chatId, String currentUserId) {
    emit(const MessageState.loading());
    _subscription?.cancel();
    _subscription = _repository.getMessages(chatId).listen(
      (messages) {
        state.maybeWhen(
          loaded: (_, localMessages, uploadProgress) {
            emit(MessageState.loaded(
              messages: messages,
              localMessages: localMessages,
              uploadProgress: uploadProgress,
            ));
          },
          orElse: () {
            emit(MessageState.loaded(messages: messages));
          },
        );
        // Whenever we receive new messages while the screen is open,
        // mark any unread messages from the other user as read.
        _repository.markChatAsRead(chatId, currentUserId);
      },
      onError: (e) => emit(MessageState.error(message: e.toString())),
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) async {
    if (text.trim().isEmpty && mediaUrl == null && type != 'location') return;

    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: senderId,
      text: text.trim(),
      type: type,
      timestamp: DateTime.now(),
      status: 'sent',
      mediaUrl: mediaUrl,
      metadata: metadata,
    );

    try {
      await _repository.sendMessage(chatId, message);
    } catch (e) {
      emit(MessageState.error(message: e.toString()));
    }
  }

  Future<void> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String filePath,
    required String type, // image, video, file, sticker
    String text = '',
    Map<String, dynamic>? metadata,
  }) async {
    final messageId = const Uuid().v4();
    
    // 1. Create a local temporary message
    final localMessage = MessageModel(
      id: messageId,
      senderId: senderId,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      status: 'uploading',
      metadata: {
        ...(metadata ?? {}),
        'localPath': filePath,
      },
    );

    // 2. Add to local state immediately
    state.maybeWhen(
      loaded: (messages, localMessages, uploadProgress) {
        final newLocalMessages = List<MessageModel>.from(localMessages)..add(localMessage);
        final newProgress = Map<String, double>.from(uploadProgress)..[messageId] = 0.0;
        emit(MessageState.loaded(
          messages: messages,
          localMessages: newLocalMessages,
          uploadProgress: newProgress,
        ));
      },
      orElse: () {},
    );

    try {
      final extension = filePath.split('.').last;
      final fileName = '${const Uuid().v4()}.$extension';
      final storagePath = 'chats/$chatId/$type/$fileName';

      // 3. Upload with progress listener
      final mediaUrl = await _repository.uploadMedia(
        filePath, 
        storagePath,
        onProgress: (progress) {
          state.maybeWhen(
            loaded: (messages, localMessages, uploadProgress) {
              final newProgress = Map<String, double>.from(uploadProgress)..[messageId] = progress;
              emit(MessageState.loaded(
                messages: messages,
                localMessages: localMessages,
                uploadProgress: newProgress,
              ));
            },
            orElse: () {},
          );
        },
      );

      // 4. Remove from local state
      state.maybeWhen(
        loaded: (messages, localMessages, uploadProgress) {
          final newLocalMessages = localMessages.where((m) => m.id != messageId).toList();
          final newProgress = Map<String, double>.from(uploadProgress)..remove(messageId);
          emit(MessageState.loaded(
            messages: messages,
            localMessages: newLocalMessages,
            uploadProgress: newProgress,
          ));
        },
        orElse: () {},
      );

      // 5. Save the final message to Firestore
      final finalMessage = localMessage.copyWith(
        status: 'sent',
        mediaUrl: mediaUrl,
        metadata: metadata, // strip localPath
      );
      
      await _repository.sendMessage(chatId, finalMessage);
    } catch (e) {
      // Clean up local state on error
      state.maybeWhen(
        loaded: (messages, localMessages, uploadProgress) {
          final newLocalMessages = localMessages.where((m) => m.id != messageId).toList();
          final newProgress = Map<String, double>.from(uploadProgress)..remove(messageId);
          emit(MessageState.loaded(
            messages: messages,
            localMessages: newLocalMessages,
            uploadProgress: newProgress,
          ));
        },
        orElse: () {},
      );
      emit(MessageState.error(message: e.toString()));
    }
  }

  Future<void> sendLocationMessage({
    required String chatId,
    required String senderId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      await sendMessage(
        chatId: chatId,
        senderId: senderId,
        text: address,
        type: 'location',
        metadata: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } catch (e) {
      emit(MessageState.error(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
