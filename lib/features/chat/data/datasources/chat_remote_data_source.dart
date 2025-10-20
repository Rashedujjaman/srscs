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
    try {
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
        'userName': userName,
      });
    } catch (e) {
      print('Error sending message for userId $userId: $e');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String userId) {
    try {
      return database
          .ref('chats/$userId/messages')
          .orderByChild('timestamp')
          .onValue
          .map((event) {
        try {
          final messages = <ChatMessageModel>[];
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              try {
                final snapshot = event.snapshot.child(key);
                messages.add(ChatMessageModel.fromSnapshot(snapshot));
              } catch (e) {
                print('Error parsing message $key: $e');
              }
            });
          }
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        } catch (e) {
          print('Error processing messages stream: $e');
          throw Exception('Failed to process messages: ${e.toString()}');
        }
      }).handleError((error) {
        print('Error in getMessagesStream for userId $userId: $error');
        throw Exception('Failed to stream messages: ${error.toString()}');
      });
    } catch (e) {
      print('Error initializing getMessagesStream: $e');
      throw Exception('Failed to initialize message stream: ${e.toString()}');
    }
  }

  Future<List<String>> getAllChatSessions() async {
    try {
      final snapshot = await database.ref('chats').get();
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.keys.map((key) => key.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all chat sessions: $e');
      throw Exception('Failed to retrieve chat sessions: ${e.toString()}');
    }
  }
}
