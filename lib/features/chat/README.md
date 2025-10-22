# Chat Module

Real-time chat functionality between users and administrators with media support, push notifications, and comprehensive message management.

## Features

### ✅ Implemented

- **Real-time messaging** - Instant message delivery using Firebase Realtime Database
- **Media support** - Send images, files, and photos from camera
- **Date grouping** - Messages grouped by Today, Yesterday, or specific dates
- **Read/unread status** - Track and display unread message counts
- **Admin management** - Dedicated screens for admins to view and respond to chats
- **Push notifications** - Integrated with notification service (Cloud Function ready)
- **User identification** - Automatic fetching of user names from Firestore profiles
- **Offline support** - Messages cached locally with Firebase persistence

### 🚧 Pending

- Typing indicators
- Message delivery status (sent/delivered/read receipts)
- Message search functionality
- Chat attachments preview

## Architecture

```
chat/
├── data/
│   ├── datasources/
│   │   └── chat_remote_data_source.dart    # Firebase Realtime Database operations
│   ├── models/
│   │   └── chat_message_model.dart         # Data model with JSON serialization
│   └── repositories/
│       └── chat_repository_impl.dart       # Repository implementation
├── domain/
│   ├── entities/
│   │   └── chat_message_entity.dart        # Business entity
│   ├── repositories/
│   │   └── chat_repository.dart            # Repository interface
│   └── usecases/
│       └── send_message.dart               # Send message use case
├── presentation/
│   ├── providers/
│   │   └── chat_provider.dart              # State management with Provider
│   └── screens/
│       ├── chat_screen.dart                # User chat interface
│       ├── admin_chat_list_screen.dart     # Admin view of all chats
│       ├── admin_chat_detail_screen.dart   # Admin chat conversation view
│       ├── chat_debug_screen.dart          # Debug/testing utility
│       ├── database_config_test_screen.dart # Database configuration test
│       └── update_chat_names_screen.dart   # One-time utility to fix names
└── docs/
    └── setup_guide.md                      # Detailed setup instructions
```

## Database Structure

### Firebase Realtime Database

```json
{
  "chats": {
    "{userId}": {
      "userName": "John Doe",
      "lastMessage": "Hello",
      "lastMessageTime": 1234567890,
      "unreadCount": 2,
      "messages": {
        "{messageId}": {
          "senderId": "user-id",
          "senderName": "John Doe",
          "message": "Hello!",
          "type": "text",
          "timestamp": 1234567890,
          "isAdmin": false,
          "mediaUrl": null
        }
      }
    }
  }
}
```

### Message Types

- `text` - Plain text messages
- `image` - Image files (stored in Firebase Storage)
- `file` - Document files (PDF, DOC, etc.)

## Usage

### User Chat

```dart
// Navigate to chat screen
Get.toNamed('/chat');

// Chat screen automatically:
// - Fetches user's name from Firestore
// - Subscribes to real-time message updates
// - Handles media uploads to Firebase Storage
```

### Admin Chat Management

```dart
// View all user chats
Get.toNamed('/admin-chats');

// Admins can:
// - See all active chat sessions
// - View unread message counts
// - Respond to user messages
// - Send media files
```

## Key Components

### ChatRemoteDataSource

Handles all Firebase Realtime Database operations:

- `sendMessage()` - Send text or media messages
- `getMessagesStream()` - Real-time message updates
- `getAllChatSessions()` - Fetch all chat sessions for admin

### ChatProvider

State management for chat functionality:

- Message sending with loading states
- Stream subscription management
- Error handling

### Message Features

- **Date Headers**: Automatically groups messages by date
- **Media Preview**: Inline image display, file download links
- **Sender Identification**: Shows user name or "Admin"
- **Timestamp**: Formatted time for each message
- **Upload Progress**: Loading indicators for media uploads

## Configuration

### Firebase Setup

1. **Realtime Database URL** (Required)

```dart
// lib/main.dart
FirebaseDatabase.instance.databaseURL =
    'https://your-project-default-rtdb.region.firebasedatabase.app/';
```

2. **Security Rules**

```json
{
  "rules": {
    "chats": {
      "$userId": {
        ".read": "auth != null && (auth.uid == $userId || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        ".write": "auth != null && (auth.uid == $userId || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        "messages": {
          ".indexOn": ["timestamp"]
        }
      }
    }
  }
}
```

3. **Storage Rules**

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chat_media/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Push Notifications

See `docs/push_notifications_setup.md` for Cloud Function deployment instructions.

## Utilities

### Database Configuration Test

Test Firebase Realtime Database connection and permissions:

```dart
Get.toNamed('/db-test');
```

### Update Chat Names

One-time utility to update old chat sessions with correct user names:

```dart
Get.toNamed('/update-chat-names');
```

### Chat Debug Screen

Debug chat functionality and database structure:

```dart
Get.toNamed('/chat-debug');
```

## Dependencies

```yaml
dependencies:
  firebase_database: ^10.5.7
  firebase_storage: ^11.7.7
  cloud_firestore: ^4.17.5
  image_picker: ^1.1.2
  file_picker: ^8.0.7
  provider: ^6.1.2
  intl: ^0.19.0
```

## Troubleshooting

### Messages not loading

1. Check Firebase Realtime Database URL is configured
2. Verify security rules allow authenticated access
3. Use `/db-test` route to diagnose connection issues

### User names showing empty

1. Ensure user has completed profile setup in Firestore
2. Check `citizens` collection has `fullName` field
3. Run `/update-chat-names` to fix old messages

### Media upload fails

1. Check Firebase Storage rules allow user uploads
2. Verify Storage bucket is configured
3. Check file size limits (images: 10MB, files: 20MB)

### Push notifications not working

1. Verify Cloud Function is deployed
2. Check FCM token is saved in user's document
3. Test notification manually in Firebase Console

## Testing

- ✅ Unit tests for data sources and repositories
- ✅ Widget tests for chat screens
- ✅ Integration tests with Firebase emulator
- ✅ Manual testing with real Firebase instance

## Future Enhancements

1. **Typing indicators** - Show when admin/user is typing
2. **Message reactions** - Emoji reactions to messages
3. **Message editing** - Edit sent messages
4. **Message deletion** - Delete messages
5. **Chat history export** - Export chat as PDF/CSV
6. **Voice messages** - Record and send audio
7. **Video messages** - Record and send video clips
8. **Chat search** - Search messages by keyword
9. **Message forwarding** - Forward messages to other chats
10. **Chat templates** - Quick reply templates for admins

## Support

For issues or questions about the chat module, refer to:

- `docs/setup_guide.md` - Detailed setup instructions
- `docs/troubleshooting.md` - Common issues and solutions
- Firebase Console logs for runtime errors

## License

Part of the SRSCS (Smart Resident Services & Complaint System) project.
