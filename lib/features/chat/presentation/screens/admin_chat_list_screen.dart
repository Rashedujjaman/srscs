import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:srscs/core/theme/app_theme_provider.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Management'),
        backgroundColor: theme.primaryColor,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('chats').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No active chats yet'),
            );
          }

          final chatsData =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final chatSessions = <ChatSession>[];

          chatsData.forEach((userId, chatData) {
            if (chatData is Map) {
              chatSessions.add(ChatSession(
                userId: userId.toString(),
                userName: chatData['userName'] ?? 'Unknown User',
                lastMessage: chatData['lastMessage'] ?? '',
                lastMessageTime: chatData['lastMessageTime'] ?? 0,
                unreadCount: chatData['unreadCount'] ?? 0,
              ));
            }
          });

          // Sort by last message time
          chatSessions
              .sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

          if (chatSessions.isEmpty) {
            return const Center(
              child: Text('No active chats yet'),
            );
          }

          return ListView.builder(
            itemCount: chatSessions.length,
            itemBuilder: (context, index) {
              final session = chatSessions[index];
              return _buildChatSessionTile(context, session);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatSessionTile(BuildContext context, ChatSession session) {
    final lastMessageDate =
        DateTime.fromMillisecondsSinceEpoch(session.lastMessageTime);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
        lastMessageDate.year, lastMessageDate.month, lastMessageDate.day);

    String timeLabel;
    if (messageDate == today) {
      timeLabel = DateFormat('HH:mm').format(lastMessageDate);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      timeLabel = 'Yesterday';
    } else if (now.difference(lastMessageDate).inDays < 7) {
      timeLabel = DateFormat('EEEE').format(lastMessageDate);
    } else {
      timeLabel = DateFormat('MM/dd/yyyy').format(lastMessageDate);
    }

    final theme = Provider.of<AppThemeProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor,
          child: Text(
            session.userName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.userName,
                style: TextStyle(
                  fontWeight: session.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (session.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          session.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight:
                session.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            color: session.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
          ),
        ),
        trailing: Text(
          timeLabel,
          style: TextStyle(
            fontSize: 12,
            color:
                session.unreadCount > 0 ? const Color(0xFF9F7AEA) : Colors.grey,
            fontWeight:
                session.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminChatDetailScreen(
                userId: session.userId,
                userName: session.userName,
                userType: 'admin',
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatSession {
  final String userId;
  final String userName;
  final String lastMessage;
  final int lastMessageTime;
  final int unreadCount;

  ChatSession({
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });
}
