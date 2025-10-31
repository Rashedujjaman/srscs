import '../../domain/entities/notification_item.dart';

/// Repository interface for notifications
abstract class NotificationRepository {
  /// Get notifications for a user (excludes chat messages)
  Future<List<NotificationItem>> getNotifications(String userId,
      {int limit = 50});

  /// Get unread notification count (excludes chat messages)
  Future<int> getUnreadCount(String userId);

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId);

  /// Delete all notifications
  Future<void> deleteAllNotifications(String userId);

  /// Stream of notifications
  Stream<List<NotificationItem>> notificationsStream(String userId,
      {int limit = 50});

  /// Stream of unread notification count
  Stream<int> unreadCountStream(String userId);
}
