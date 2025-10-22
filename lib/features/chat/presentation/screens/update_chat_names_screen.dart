import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time utility to update old chat sessions with correct user names
/// from Firestore. Run this once if you have existing chats with empty names.
class UpdateChatNamesScreen extends StatefulWidget {
  const UpdateChatNamesScreen({Key? key}) : super(key: key);

  @override
  State<UpdateChatNamesScreen> createState() => _UpdateChatNamesScreenState();
}

class _UpdateChatNamesScreenState extends State<UpdateChatNamesScreen> {
  bool _isUpdating = false;
  List<String> _logs = [];
  int _totalChats = 0;
  int _updatedChats = 0;
  int _failedChats = 0;

  void _log(String message) {
    setState(() {
      _logs.add(
          '${DateTime.now().toIso8601String().split('T')[1].substring(0, 8)}: $message');
    });
    print(message);
  }

  Future<void> _updateAllChatNames() async {
    setState(() {
      _isUpdating = true;
      _logs.clear();
      _totalChats = 0;
      _updatedChats = 0;
      _failedChats = 0;
    });

    try {
      _log('🔍 Starting chat name update process...');

      final database = FirebaseDatabase.instance;
      final firestore = FirebaseFirestore.instance;

      // Get all chat sessions
      _log('📥 Fetching all chat sessions...');
      final chatsSnapshot = await database.ref('chats').get();

      if (!chatsSnapshot.exists) {
        _log('⚪ No chat sessions found');
        setState(() => _isUpdating = false);
        return;
      }

      final chats = chatsSnapshot.value as Map<dynamic, dynamic>;
      _totalChats = chats.length;
      _log('📊 Found $_totalChats chat session(s)');

      // Process each chat session
      int index = 0;
      for (var userId in chats.keys) {
        index++;
        _log('');
        _log('[$index/$_totalChats] Processing user: $userId');

        try {
          // Get user's real name from Firestore
          final userDoc =
              await firestore.collection('citizens').doc(userId).get();

          if (!userDoc.exists) {
            _log('⚠️ User document not found in Firestore');
            _failedChats++;
            continue;
          }

          final fullName = userDoc.data()?['fullName'];
          if (fullName == null || fullName.isEmpty) {
            _log('⚠️ User has no fullName in profile');
            _failedChats++;
            continue;
          }

          _log('👤 Found user name: $fullName');

          // Update userName in chat session
          await database.ref('chats/$userId').update({
            'userName': fullName,
          });
          _log('✅ Updated chat session userName');

          // Get all messages for this user
          final messagesSnapshot =
              await database.ref('chats/$userId/messages').get();

          if (messagesSnapshot.exists) {
            final messages = messagesSnapshot.value as Map<dynamic, dynamic>;
            _log('📨 Found ${messages.length} messages');

            int updatedMessages = 0;
            // Update senderName in user's messages (not admin messages)
            for (var messageId in messages.keys) {
              final message = messages[messageId];

              // Only update user messages (not admin messages)
              if (message is Map && message['isAdmin'] == false) {
                await database
                    .ref('chats/$userId/messages/$messageId')
                    .update({'senderName': fullName});
                updatedMessages++;
              }
            }
            _log('✅ Updated $updatedMessages user messages');
          } else {
            _log('📭 No messages found');
          }

          _updatedChats++;
          _log('✅ Successfully updated chat for: $fullName');
        } catch (e) {
          _log('❌ Error updating chat for user $userId: $e');
          _failedChats++;
        }
      }

      _log('');
      _log('🎉 Update complete!');
      _log('📊 Total chats: $_totalChats');
      _log('✅ Successfully updated: $_updatedChats');
      _log('❌ Failed: $_failedChats');

      if (_updatedChats > 0) {
        _showSuccessDialog();
      }
    } catch (e) {
      _log('❌ FATAL ERROR: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Update Complete'),
        content: Text(
          'Updated $_updatedChats chat session(s) successfully!\n\n'
          'All user names have been fetched from Firestore and updated in the chat database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Chat Names'),
        backgroundColor: const Color(0xFF9F7AEA),
      ),
      body: Column(
        children: [
          // Info Card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'One-Time Utility',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This tool updates old chat sessions with correct user names from Firestore.\n\n'
                    'What it does:\n'
                    '• Fetches user names from citizens collection\n'
                    '• Updates userName in chat sessions\n'
                    '• Updates senderName in user messages\n'
                    '• Skips admin messages\n\n'
                    'Run this once if you have existing chats with empty names.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Stats
          if (_totalChats > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Total', _totalChats, Colors.blue),
                  _buildStatCard('Updated', _updatedChats, Colors.green),
                  _buildStatCard('Failed', _failedChats, Colors.red),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : _updateAllChatNames,
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isUpdating ? 'Updating...' : 'Start Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9F7AEA),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Click "Start Update" to begin',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = Colors.white70;

                        if (log.contains('✅')) {
                          textColor = Colors.green[300]!;
                        } else if (log.contains('❌')) {
                          textColor = Colors.red[300]!;
                        } else if (log.contains('⚠️')) {
                          textColor = Colors.orange[300]!;
                        } else if (log.contains('🔍') || log.contains('📊')) {
                          textColor = Colors.blue[300]!;
                        } else if (log.contains('🎉')) {
                          textColor = Colors.yellow[300]!;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
