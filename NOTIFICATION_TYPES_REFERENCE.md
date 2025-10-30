# Notification System - Quick Reference

## 📱 Notification Types Reference

### Server-Generated Notifications (Shown in Bell Icon)

| Type               | Source         | Recipient          | Trigger                          | Icon                 | Color  |
| ------------------ | -------------- | ------------------ | -------------------------------- | -------------------- | ------ |
| `complaint_status` | Cloud Function | Citizen/Contractor | Complaint status changes         | update               | Purple |
| `new_complaint`    | Cloud Function | Admin              | New complaint submitted          | report_problem       | Orange |
| `task_assigned`    | Cloud Function | Contractor         | Task assigned to contractor      | assignment_turned_in | Blue   |
| `urgent_notice`    | Cloud Function | All Users          | Emergency/warning notice created | warning              | Red    |
| `notice`           | Cloud Function | All Users          | Regular notice created           | notifications_active | Amber  |
| `news`             | Cloud Function | All Users          | High-priority news (priority 5)  | article              | Green  |

### Chat Notifications (Excluded from Bell Icon)

| Type                      | Shown In         | Navigation                    |
| ------------------------- | ---------------- | ----------------------------- |
| `chat_message`            | System Tray Only | `/chat`                       |
| `admin_chat_message`      | System Tray Only | `/chat` or `/contractor/chat` |
| `user_chat_message`       | System Tray Only | `/admin/chat/detail`          |
| `contractor_chat_message` | System Tray Only | `/admin/chat/detail`          |

## 🔔 Priority Levels

| Priority   | Description  | Badge Display  | Use Cases                                |
| ---------- | ------------ | -------------- | ---------------------------------------- |
| `critical` | Max urgency  | RED "CRITICAL" | Emergency notices, system alerts         |
| `high`     | High urgency | ORANGE "HIGH"  | Important status changes, urgent notices |
| `normal`   | Standard     | No badge       | Regular updates, standard notices        |
| `low`      | Low priority | No badge       | Informational, optional updates          |

## 🎨 Visual States

### Unread Notification

- Bold title text (Black87)
- Darker body text (Grey[700])
- Purple dot indicator
- White background
- Elevation: 2

### Read Notification

- Normal title text (Grey[600])
- Lighter body text (Grey[500])
- No dot indicator
- Grey[50] background
- Elevation: 0

## 🔄 User Actions

### Notification Card Actions:

1. **Tap** → Navigate to relevant screen + mark as read
2. **Swipe Left** → Delete notification
3. **Long Press** → (Not implemented, could add options menu)

### Screen Actions:

1. **Mark All Read** → Marks all unread notifications as read
2. **Delete All** → Shows confirmation, then deletes all notifications
3. **Pull to Refresh** → Reloads notification list

## 📍 Navigation Mapping

```dart
// Complaint Status → Track Complaints
case NotificationType.complaintStatus:
  Get.toNamed(AppRoutes.trackComplaints);

// New Complaint → Admin Detail
case NotificationType.newComplaint:
  Get.toNamed('/admin/complaint-detail', arguments: complaintId);

// Task Assigned → Track Complaints / Tasks
case NotificationType.taskAssigned:
  Get.toNamed(AppRoutes.trackComplaints);

// Notices/News → Dashboard
case NotificationType.urgentNotice:
case NotificationType.notice:
case NotificationType.news:
  Get.back(); // Return to dashboard
```

## 🔒 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User Notifications
    match /user_notifications/{userId}/notifications/{notificationId} {
      // Users can only access their own notifications
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

## 📊 Data Structure

```dart
// Firestore Document Structure
{
  "title": "🔧 Work in Progress",
  "body": "Great news! Work has started on your pothole complaint",
  "type": "complaint_status",
  "priority": "high",
  "timestamp": Timestamp(2024, 1, 15, 10, 30),
  "isRead": false,
  "data": {
    "complaintId": "abc123",
    "status": "inProgress",
    "complaintType": "pothole"
  }
}
```

## 🛠️ API Quick Reference

### NotificationRepository Methods

```dart
// Get notifications (paginated)
Future<List<NotificationItem>> getNotifications(String userId, {int limit = 50});

// Get unread count
Future<int> getUnreadCount(String userId);

// Mark single as read
Future<void> markAsRead(String userId, String notificationId);

// Mark all as read
Future<void> markAllAsRead(String userId);

// Delete single
Future<void> deleteNotification(String userId, String notificationId);

// Delete all
Future<void> deleteAllNotifications(String userId);

// Real-time streams
Stream<List<NotificationItem>> notificationsStream(String userId, {int limit = 50});
Stream<int> unreadCountStream(String userId);
```

## 🎯 Implementation Checklist

### For New Notification Types:

- [ ] Add type to `NotificationType` enum
- [ ] Add parsing in `NotificationItem._parseNotificationType()`
- [ ] Add icon in `NotificationItemCard._getIcon()`
- [ ] Add color in `NotificationItemCard._getIconBackgroundColor()`
- [ ] Add navigation in `NotificationsScreen._handleNotificationTap()`
- [ ] Update Cloud Function to save to Firestore (optional)
- [ ] Test end-to-end flow

## 💡 Usage Examples

### Display Notification Badge in AppBar

```dart
StreamBuilder<int>(
  stream: NotificationRepositoryImpl().unreadCountStream(userId),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    return Badge(
      label: Text('$unreadCount'),
      isLabelVisible: unreadCount > 0,
      child: IconButton(
        icon: Icon(Icons.notifications),
        onPressed: () => Get.toNamed('/notifications'),
      ),
    );
  },
);
```

### Listen to Notifications in Screen

```dart
StreamBuilder<List<NotificationItem>>(
  stream: _repository.notificationsStream(userId),
  builder: (context, snapshot) {
    final notifications = snapshot.data ?? [];
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return NotificationItemCard(
          notification: notifications[index],
          onTap: () => _handleTap(notifications[index]),
          onDismiss: () => _delete(notifications[index].id),
        );
      },
    );
  },
);
```

## 🐛 Troubleshooting

### Notifications not appearing?

1. Check FCM token is saved correctly
2. Verify notification service is initialized
3. Confirm Cloud Function is triggering
4. Check Firestore write permissions
5. Verify notification type is not in chat exclusion list

### Badge count incorrect?

1. Refresh the stream
2. Check for duplicate notifications
3. Verify isRead field updates correctly
4. Check timezone/timestamp issues

### Navigation not working?

1. Verify route is registered in app_routes.dart
2. Check route path matches exactly
3. Ensure arguments are passed correctly
4. Verify middleware allows navigation

---

**Quick Access:**

- Full Documentation: [NOTIFICATION_SYSTEM_UPDATE.md](NOTIFICATION_SYSTEM_UPDATE.md)
- Original Guide: [docs/NOTIFICATION_SYSTEM_GUIDE.md](docs/NOTIFICATION_SYSTEM_GUIDE.md)
- Cloud Functions: [functions/index.js](functions/index.js)
