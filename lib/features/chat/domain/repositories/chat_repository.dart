import '../entities/chat_message_entity.dart';

abstract class ChatRepository {
  /// Send a message to admin
  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
  });

  /// Get messages stream for real-time updates
  Stream<List<ChatMessageEntity>> getMessagesStream(String userId);

  /// Get all chat sessions (for admin)
  Future<List<String>> getAllChatSessions();
}
