import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../widgets/notification_item_card.dart';
import '../../../../core/routes/app_routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepositoryImpl _repository = NotificationRepositoryImpl();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color(0xFF9F7AEA),
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF9F7AEA),
        actions: [
          // Mark all as read
          StreamBuilder<int>(
            stream: _repository.unreadCountStream(userId!),
            builder: (context, snapshot) {
              final hasUnread = (snapshot.data ?? 0) > 0;
              return IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: hasUnread
                    ? () async {
                        await _repository.markAllAsRead(userId!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications marked as read'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                tooltip: 'Mark all as read',
              );
            },
          ),
          // Delete all
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_all') {
                final confirmed = await _showDeleteAllConfirmation();
                if (confirmed == true) {
                  await _repository.deleteAllNotifications(userId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: _repository.notificationsStream(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationItemCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDismiss: () => _deleteNotification(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _repository.markAsRead(userId!, notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.complaintStatus:
      case NotificationType.taskAssigned:
        // Navigate to track complaints screen
        Get.toNamed(AppRoutes.complaintDetail,
            arguments: notification.data['complaintId']);
        break;

      case NotificationType.newComplaint:
        // Admin only - navigate to complaint detail
        final complaintId = notification.data['complaintId'];
        if (complaintId != null) {
          Get.toNamed(
            '/admin/complaint-detail',
            arguments: complaintId,
          );
        }
        break;

      case NotificationType.urgentNotice:
      case NotificationType.notice:
      case NotificationType.news:
        // Stay on notifications screen or go back to dashboard
        Get.back();
        break;

      default:
        // Default: go to dashboard
        Get.back();
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    await _repository.deleteNotification(userId!, notificationId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool?> _showDeleteAllConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
