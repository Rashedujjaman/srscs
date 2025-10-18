import 'package:firebase_database/firebase_database.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  ChatMessageModel({
    required String id,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
    required DateTime timestamp,
    bool isAdmin = false,
  }) : super(
          id: id,
          senderId: senderId,
          senderName: senderName,
          message: message,
          type: type,
          mediaUrl: mediaUrl,
          timestamp: timestamp,
          isAdmin: isAdmin,
        );

  factory ChatMessageModel.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return ChatMessageModel(
      id: snapshot.key ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      mediaUrl: data['mediaUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isAdmin': isAdmin,
    };
  }
}
