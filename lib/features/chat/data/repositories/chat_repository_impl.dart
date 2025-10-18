import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;

  ChatRepositoryImpl({required this.remote});

  @override
  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    await remote.sendMessage(
      userId: userId,
      userName: userName,
      message: message,
      type: type,
      mediaUrl: mediaUrl,
    );
  }

  @override
  Stream<List<ChatMessageEntity>> getMessagesStream(String userId) {
    return remote.getMessagesStream(userId);
  }

  @override
  Future<List<String>> getAllChatSessions() async {
    return await remote.getAllChatSessions();
  }
}
