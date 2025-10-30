import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for notification types
enum NotificationType {
  complaintStatus,
  newComplaint,
  taskAssigned,
  urgentNotice,
  notice,
  news,
  chatMessage, // Will be excluded from notification bell
}

/// Enum for notification priority
enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

/// Entity representing a notification item
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>
      data; // Additional data (complaintId, noticeId, etc.)

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.isRead,
    required this.data,
  });

  /// Create from Firestore document
  factory NotificationItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseNotificationType(data['type'] ?? ''),
      priority: _parseNotificationPriority(data['priority'] ?? 'normal'),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: Map<String, dynamic>.from(data['data'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
    };
  }

  /// Parse notification type from string
  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'complaint_status':
      case 'complaintStatus':
        return NotificationType.complaintStatus;
      case 'new_complaint':
      case 'newComplaint':
        return NotificationType.newComplaint;
      case 'task_assigned':
      case 'taskAssigned':
        return NotificationType.taskAssigned;
      case 'urgent_notice':
      case 'urgentNotice':
        return NotificationType.urgentNotice;
      case 'notice':
        return NotificationType.notice;
      case 'news':
        return NotificationType.news;
      case 'chat_message':
      case 'chatMessage':
      case 'admin_chat_message':
      case 'user_chat_message':
      case 'admin_contractor_chat_message':
      case 'contractor_chat_message':
      case 'chat':
        return NotificationType.chatMessage;
      default:
        return NotificationType.notice;
    }
  }

  /// Parse notification priority from string
  static NotificationPriority _parseNotificationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'critical':
      case 'max':
        return NotificationPriority.critical;
      default:
        return NotificationPriority.normal;
    }
  }

  /// Get time ago string
  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if notification is urgent
  bool get isUrgent =>
      priority == NotificationPriority.critical ||
      priority == NotificationPriority.high;

  /// Check if notification is a chat message
  bool get isChatMessage => type == NotificationType.chatMessage;

  /// Create a copy with updated fields
  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}
