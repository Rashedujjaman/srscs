import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<void> call({
    required String userId,
    required String userName,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    return await repository.sendMessage(
      userId: userId,
      userName: userName,
      message: message,
      type: type,
      mediaUrl: mediaUrl,
    );
  }
}
