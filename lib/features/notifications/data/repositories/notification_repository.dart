import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Firestore implementation of NotificationRepository
class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the user's notifications collection path
  CollectionReference<Map<String, dynamic>> _getUserNotificationsCollection(
    String userId,
  ) {
    return _firestore
        .collection('user_notifications')
        .doc(userId)
        .collection('notifications');
  }

  @override
  Future<List<NotificationItem>> getNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _getUserNotificationsCollection(userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc))
          .where((notification) =>
              !notification.isChatMessage) // Exclude chat messages
          .toList();
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _getUserNotificationsCollection(userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Count only non-chat notifications
      return querySnapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc))
          .where((notification) => !notification.isChatMessage)
          .length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _getUserNotificationsCollection(userId)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _getUserNotificationsCollection(userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error marking all as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _getUserNotificationsCollection(userId)
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final querySnapshot = await _getUserNotificationsCollection(userId).get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      rethrow;
    }
  }

  @override
  Stream<List<NotificationItem>> notificationsStream(
    String userId, {
    int limit = 50,
  }) {
    return _getUserNotificationsCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromFirestore(doc))
            .where(
                (notification) => !notification.isChatMessage) // Exclude chat
            .toList());
  }

  @override
  Stream<int> unreadCountStream(String userId) {
    return _getUserNotificationsCollection(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromFirestore(doc))
            .where((notification) => !notification.isChatMessage)
            .length);
  }
}
