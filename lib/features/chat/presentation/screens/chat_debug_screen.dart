import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Debug screen to check Firebase Realtime Database connection and data
class ChatDebugScreen extends StatefulWidget {
  const ChatDebugScreen({super.key});

  @override
  State<ChatDebugScreen> createState() => _ChatDebugScreenState();
}

class _ChatDebugScreenState extends State<ChatDebugScreen> {
  String _debugInfo = 'Click "Check Database" to start...';
  bool _isLoading = false;

  Future<void> _checkDatabase() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Checking...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _debugInfo = '❌ ERROR: User not logged in!';
          _isLoading = false;
        });
        return;
      }

      final userId = user.uid;
      final database = FirebaseDatabase.instance;

      StringBuffer info = StringBuffer();
      info.writeln('🔍 FIREBASE REALTIME DATABASE CHECK\n');
      info.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      // Check user info
      info.writeln('👤 Current User:');
      info.writeln('   User ID: $userId');
      info.writeln('   Email: ${user.email}');
      info.writeln('   Display Name: ${user.displayName ?? "Not set"}\n');

      // Check database connection
      info.writeln('🔌 Database Connection:');
      final connectedRef = database.ref('.info/connected');
      final connectedSnapshot = await connectedRef.get();
      final isConnected = connectedSnapshot.value as bool? ?? false;
      info.writeln(
          '   Status: ${isConnected ? "✅ Connected" : "❌ Disconnected"}\n');

      // Check if chats node exists
      info.writeln('📂 Database Structure:');
      final chatsRef = database.ref('chats');
      final chatsSnapshot = await chatsRef.get();

      if (chatsSnapshot.exists) {
        info.writeln('   ✅ "chats" node exists');
        final chatsData = chatsSnapshot.value as Map<dynamic, dynamic>?;
        if (chatsData != null) {
          info.writeln('   📊 Total chat sessions: ${chatsData.keys.length}');
        }
      } else {
        info.writeln('   ❌ "chats" node does NOT exist');
        info.writeln('   💡 This is normal if no messages sent yet!\n');
      }

      // Check user's chat
      info.writeln('\n💬 Your Chat Data:');
      final userChatRef = database.ref('chats/$userId');
      final userChatSnapshot = await userChatRef.get();

      if (userChatSnapshot.exists) {
        info.writeln('   ✅ Chat session exists!');
        final chatData = userChatSnapshot.value as Map<dynamic, dynamic>?;
        if (chatData != null) {
          info.writeln('   📝 User Name: ${chatData['userName'] ?? "Not set"}');
          info.writeln(
              '   💬 Last Message: ${chatData['lastMessage'] ?? "None"}');
          info.writeln(
              '   🕒 Last Time: ${chatData['lastMessageTime'] ?? "Never"}');
        }
      } else {
        info.writeln('   ❌ No chat session for this user');
        info.writeln('   💡 Send a message to create one!\n');
      }

      // Check messages
      info.writeln('\n📨 Messages:');
      final messagesRef = database.ref('chats/$userId/messages');
      final messagesSnapshot = await messagesRef.get();

      if (messagesSnapshot.exists) {
        final messagesData = messagesSnapshot.value as Map<dynamic, dynamic>?;
        if (messagesData != null) {
          info.writeln('   ✅ Messages found: ${messagesData.keys.length}');

          // Show first 3 messages
          final messagesList = messagesData.entries.take(3).toList();
          for (var i = 0; i < messagesList.length; i++) {
            final entry = messagesList[i];
            final msgData = entry.value as Map<dynamic, dynamic>;
            info.writeln('\n   Message ${i + 1}:');
            info.writeln('   - ID: ${entry.key}');
            info.writeln('   - Text: ${msgData['message'] ?? "N/A"}');
            info.writeln('   - From: ${msgData['senderName'] ?? "N/A"}');
            info.writeln('   - Admin: ${msgData['isAdmin'] ?? false}');
          }

          if (messagesData.keys.length > 3) {
            info.writeln(
                '\n   ... and ${messagesData.keys.length - 3} more messages');
          }
        }
      } else {
        info.writeln('   ❌ No messages found');
        info.writeln('   💡 Path: chats/$userId/messages\n');
      }

      // Database URL
      info.writeln('\n🌐 Database URL:');
      info.writeln('   ${database.databaseURL}\n');

      info.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      info.writeln('\n✅ Check completed successfully!');

      setState(() {
        _debugInfo = info.toString();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _debugInfo = '❌ ERROR:\n\n$e\n\nStack Trace:\n$stackTrace';
        _isLoading = false;
      });
    }
  }

  Future<void> _testWrite() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Testing write...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final database = FirebaseDatabase.instance;
      final testRef = database.ref('chats/${user.uid}/messages').push();

      await testRef.set({
        'message': 'Test message from debug tool',
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Test User',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'text',
        'isAdmin': false,
      });

      await database.ref('chats/${user.uid}').update({
        'userName': user.displayName ?? 'Test User',
        'lastMessage': 'Test message from debug tool',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });

      setState(() {
        _debugInfo =
            '✅ SUCCESS!\n\nTest message written to:\nchats/${user.uid}/messages/${testRef.key}\n\nNow click "Check Database" to verify!';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _debugInfo = '❌ WRITE ERROR:\n\n$e\n\nStack Trace:\n$stackTrace';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Database Debug'),
        backgroundColor: const Color(0xFF9F7AEA),
      ),
      body: Column(
        children: [
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkDatabase,
                    icon: const Icon(Icons.search),
                    label: const Text('Check Database'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F7AEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testWrite,
                    icon: const Icon(Icons.edit),
                    label: const Text('Test Write'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          // Debug info
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _debugInfo,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
