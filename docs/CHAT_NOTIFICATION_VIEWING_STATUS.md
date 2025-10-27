# 🔕 Chat Notification - Viewing Status Implementation

## 🎯 Problem Solved

**Issue:** Users receive notifications even when actively chatting on the screen.

**Solution:** Track when users are viewing chat and skip notifications during active sessions.

---

## ✅ Cloud Functions Updated

Both chat functions now check "viewing status" before sending notifications:

### **1. `onChatMessage` (Citizen ↔ Admin)**

- **Path:** `chats/{userId}/messages`
- **Checks:**
  - Citizen viewing: `chats/{userId}/chatStatus/isViewing`
  - Admin viewing: `admin_chat_status/{userId}/isViewing`

### **2. `onContractorChatMessage` (Contractor ↔ Admin)**

- **Path:** `contractor_chats/{contractorId}/messages`
- **Checks:**
  - Contractor viewing: `contractor_chats/{contractorId}/chatStatus/isViewing`
  - Admin viewing: `admin_chat_status/{contractorId}/isViewing`

---

## 📂 Database Structure

### **Realtime Database Paths:**

```json
{
  // For Citizen Chats
  "chats": {
    "{userId}": {
      "chatStatus": {
        "isViewing": true, // Citizen is viewing chat
        "lastSeen": 1698400000000
      },
      "messages": {
        /* ... */
      }
    }
  },

  // For Contractor Chats
  "contractor_chats": {
    "{contractorId}": {
      "chatStatus": {
        "isViewing": true, // Contractor is viewing chat
        "lastSeen": 1698400000000
      },
      "messages": {
        /* ... */
      }
    }
  },

  // For Admin Viewing Status (shared for all chats)
  "admin_chat_status": {
    "{userId}": {
      // or {contractorId}
      "isViewing": true, // Admin is viewing this chat
      "lastSeen": 1698400000000,
      "adminId": "admin123"
    }
  }
}
```

---

## 🛠️ Flutter Implementation

### **Step 1: Update Chat Screen for Citizens**

**File:** `lib/features/chat/presentation/screens/chat_screen.dart` (or similar)

```dart
import 'package:firebase_database/firebase_database.dart';

class CitizenChatScreen extends StatefulWidget {
  final String userId;
  const CitizenChatScreen({required this.userId});

  @override
  State<CitizenChatScreen> createState() => _CitizenChatScreenState();
}

class _CitizenChatScreenState extends State<CitizenChatScreen> with WidgetsBindingObserver {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference _chatStatusRef;
  bool _isInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatStatusRef = _database.child('chats/${widget.userId}/chatStatus');
    _setChatViewingStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setChatViewingStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        _setChatViewingStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isInForeground = false;
        _setChatViewingStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _setChatViewingStatus(bool isViewing) async {
    try {
      await _chatStatusRef.set({
        'isViewing': isViewing,
        'lastSeen': ServerValue.timestamp,
      });
      print('📱 Chat viewing status set: $isViewing');
    } catch (e) {
      print('❌ Error setting chat viewing status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing chat UI
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Admin')),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(/* ... */),
          ),
          // Message input
          TextField(/* ... */),
        ],
      ),
    );
  }
}
```

---

### **Step 2: Update Chat Screen for Contractors**

**File:** `lib/features/contractor/presentation/screens/contractor_chat_screen.dart`

```dart
class ContractorChatScreen extends StatefulWidget {
  final String contractorId;
  const ContractorChatScreen({required this.contractorId});

  @override
  State<ContractorChatScreen> createState() => _ContractorChatScreenState();
}

class _ContractorChatScreenState extends State<ContractorChatScreen> with WidgetsBindingObserver {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference _chatStatusRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatStatusRef = _database.child('contractor_chats/${widget.contractorId}/chatStatus');
    _setChatViewingStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setChatViewingStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _setChatViewingStatus(true);
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive) {
      _setChatViewingStatus(false);
    }
  }

  Future<void> _setChatViewingStatus(bool isViewing) async {
    try {
      await _chatStatusRef.set({
        'isViewing': isViewing,
        'lastSeen': ServerValue.timestamp,
      });
      print('📱 Contractor chat viewing status set: $isViewing');
    } catch (e) {
      print('❌ Error setting contractor chat viewing status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing contractor chat UI
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Admin')),
      body: Column(/* ... */),
    );
  }
}
```

---

### **Step 3: Update Admin Chat Screen**

**File:** `lib/features/admin/presentation/screens/admin_chat_screen.dart`

```dart
class AdminChatScreen extends StatefulWidget {
  final String userId;        // Can be citizenId or contractorId
  final String userType;      // 'citizen' or 'contractor'
  const AdminChatScreen({
    required this.userId,
    required this.userType,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> with WidgetsBindingObserver {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference _adminChatStatusRef;
  late String _adminId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _adminChatStatusRef = _database.child('admin_chat_status/${widget.userId}');
    _setAdminViewingStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setAdminViewingStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _setAdminViewingStatus(true);
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive) {
      _setAdminViewingStatus(false);
    }
  }

  Future<void> _setAdminViewingStatus(bool isViewing) async {
    try {
      await _adminChatStatusRef.set({
        'isViewing': isViewing,
        'lastSeen': ServerValue.timestamp,
        'adminId': _adminId,
      });
      print('📱 Admin viewing status set for ${widget.userId}: $isViewing');
    } catch (e) {
      print('❌ Error setting admin viewing status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing admin chat UI
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.userType == 'citizen' ? 'Citizen' : 'Contractor'}'),
      ),
      body: Column(/* ... */),
    );
  }
}
```

---

## 🔄 How It Works

### **Flow Diagram:**

```
User Opens Chat Screen
    ↓
Set isViewing = true in Realtime DB
    ↓
User is actively viewing chat
    ↓
New message arrives
    ↓
Cloud Function checks isViewing status
    ↓
If isViewing === true → Skip notification ✅
If isViewing === false → Send notification 📬
    ↓
User Closes Chat Screen or App goes to background
    ↓
Set isViewing = false
    ↓
Notifications resume normally
```

---

## 🧪 Testing

### **Test 1: Active Chat (No Notification)**

```
1. Citizen opens chat screen
2. Admin sends message
3. ✅ Expected: NO notification (citizen is viewing)
4. ✅ Message appears in chat immediately
```

### **Test 2: Inactive Chat (Notification Sent)**

```
1. Citizen closes chat screen or minimizes app
2. Admin sends message
3. ✅ Expected: Notification received
4. ✅ User can tap notification to open chat
```

### **Test 3: App in Background**

```
1. User presses home button (app goes to background)
2. Other user sends message
3. ✅ Expected: Notification received
4. ✅ isViewing automatically set to false
```

### **Test 4: Bidirectional**

```
1. Admin opens chat with citizen
2. Citizen sends message
3. ✅ Expected: NO notification to admin
4. Admin closes chat
5. Citizen sends another message
6. ✅ Expected: Admin gets notification
```

---

## 📊 Monitoring

### **Check Viewing Status in Firebase Console:**

**Realtime Database:**

```
Go to: Firebase Console > Realtime Database > Data tab

Look for:
- chats/{userId}/chatStatus/isViewing
- contractor_chats/{contractorId}/chatStatus/isViewing
- admin_chat_status/{userId}/isViewing

Should be:
- true = User is viewing chat (no notifications)
- false = User left chat (send notifications)
```

### **Cloud Function Logs:**

```
Firebase Console > Functions > onChatMessage > Logs

Look for:
✅ "User is currently viewing chat, skipping notification"
✅ "Admin is currently viewing chat with {userId}, skipping notification"
```

---

## 🚀 Deployment

### **Step 1: Deploy Cloud Functions**

```powershell
cd functions
firebase deploy --only functions
```

### **Step 2: Update Flutter App**

```powershell
# Add to pubspec.yaml (if not already added)
dependencies:
  firebase_database: ^10.0.0

# Get packages
flutter pub get

# Hot reload/restart app
flutter run
```

### **Step 3: Test All Scenarios**

- Open/close chat screens
- Send messages in different states
- Check Firebase Console for viewing status
- Monitor Cloud Function logs

---

## 🎯 Key Features

✅ **No notifications during active chat**  
✅ **Automatic status update on app lifecycle changes**  
✅ **Works with multi-device support**  
✅ **Separate tracking for citizen/contractor/admin**  
✅ **Timestamp tracking (lastSeen)**  
✅ **Clean up on screen disposal**  
✅ **Handles app backgrounding correctly**

---

## 🐛 Troubleshooting

### **Issue: Still getting notifications while chatting**

**Check 1: Viewing status in Realtime DB**

```
Is isViewing set to true in database?
Path: chats/{userId}/chatStatus/isViewing
```

**Check 2: WidgetsBindingObserver added**

```dart
class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver {  // ← Must have this
```

**Check 3: initState and dispose called**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);  // ← Must add
  _setChatViewingStatus(true);                 // ← Must set
}

@override
void dispose() {
  _setChatViewingStatus(false);                // ← Must clear
  WidgetsBinding.instance.removeObserver(this); // ← Must remove
  super.dispose();
}
```

### **Issue: Not getting notifications after closing chat**

**Check: Status cleared on dispose**

```dart
@override
void dispose() {
  _setChatViewingStatus(false);  // ← This MUST be called
  super.dispose();
}
```

---

**Last Updated:** October 27, 2025  
**Version:** 5.0  
**Status:** Ready for Implementation 🚀
