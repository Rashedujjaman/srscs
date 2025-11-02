import 'package:firebase_database/firebase_database.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatRemoteDataSource {
  final FirebaseDatabase database;

  ChatRemoteDataSource({FirebaseDatabase? database})
      : database = database ?? FirebaseDatabase.instance;

  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
    bool isAdmin = false,
  }) async {
    final chatRef = database.ref('chats/$userId/messages');
    final newMessageRef = chatRef.push();

    final chatMessage = ChatMessageModel(
      id: newMessageRef.key ?? '',
      senderId: userId,
      senderName: userName,
      message: message,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
      isAdmin: isAdmin,
    );

    await newMessageRef.set(chatMessage.toJson());

    // Update last message in session
    await database.ref('chats/$userId').update({
      'lastMessage': message,
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      if (userName != 'Admin') 'userName': userName,
    });
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String userId) {
    return database
        .ref('chats/$userId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final messages = <ChatMessageModel>[];

      if (event.snapshot.value == null) {
        return messages;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        try {
          final snapshot = event.snapshot.child(key);
          messages.add(ChatMessageModel.fromSnapshot(snapshot));
        } catch (e) {
          // Skip malformed messages
        }
      });

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Future<List<String>> getAllChatSessions() async {
    final snapshot = await database.ref('chats').get();
    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.keys.map((key) => key.toString()).toList();
    }
    return [];
  }
}
