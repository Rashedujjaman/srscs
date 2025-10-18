import 'package:flutter/material.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final SendMessage sendMessageUsecase;
  final ChatRepository repository;

  ChatProvider({
    required this.sendMessageUsecase,
    required this.repository,
  });

  List<ChatMessageEntity> messages = [];
  bool isLoading = false;
  String? errorMessage;

  Stream<List<ChatMessageEntity>> getMessagesStream(String userId) {
    return repository.getMessagesStream(userId);
  }

  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    try {
      await sendMessageUsecase.call(
        userId: userId,
        userName: userName,
        message: message,
        type: type,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
