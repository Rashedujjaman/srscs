enum MessageType { text, image, file }

class ChatMessageEntity {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType type;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isAdmin;

  ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.type = MessageType.text,
    this.mediaUrl,
    required this.timestamp,
    this.isAdmin = false,
  });
}
