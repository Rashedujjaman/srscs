import 'package:firebase_database/firebase_database.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.message,
    super.type,
    super.mediaUrl,
    required super.timestamp,
    super.isAdmin,
  });

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
