import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseConfigTestScreen extends StatefulWidget {
  const DatabaseConfigTestScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseConfigTestScreen> createState() =>
      _DatabaseConfigTestScreenState();
}

class _DatabaseConfigTestScreenState extends State<DatabaseConfigTestScreen> {
  String _status = 'Testing...';
  Color _statusColor = Colors.orange;
  List<String> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _log('🔍 Starting Firebase Realtime Database diagnostics...');

      // Test 1: Check Database URL
      _log('Test 1: Checking database URL configuration...');
      final database = FirebaseDatabase.instance;
      final databaseURL = database.databaseURL;

      if (databaseURL == null || databaseURL.isEmpty) {
        _log('❌ CRITICAL: Database URL is NOT configured!');
        _log('💡 Fix: Add this to main.dart:');
        _log('   FirebaseDatabase.instance.databaseURL = "your-url";');
        setState(() {
          _status = 'Database URL Not Configured';
          _statusColor = Colors.red;
          _isLoading = false;
        });
        return;
      } else {
        _log('✅ Database URL configured: $databaseURL');
      }

      // Test 2: Check Authentication
      _log('Test 2: Checking user authentication...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _log('❌ WARNING: User is not authenticated');
        _log('💡 Chat requires authenticated user');
        setState(() {
          _status = 'User Not Authenticated';
          _statusColor = Colors.orange;
          _isLoading = false;
        });
        return;
      } else {
        _log('✅ User authenticated: ${currentUser.uid}');
      }

      // Test 3: Test Database Connection
      _log('Test 3: Testing database connection...');
      try {
        // Try to get connection status
        final connectedRef = database.ref('.info/connected');
        final snapshot = await connectedRef.get();

        if (snapshot.exists) {
          final connected = snapshot.value as bool;
          if (connected) {
            _log('✅ Database connection established');
          } else {
            _log('⚠️ Database connection status: disconnected');
          }
        }
      } catch (e) {
        _log('⚠️ Could not check connection status: $e');
      }

      // Test 4: Test Read Permission
      _log('Test 4: Testing read permissions...');
      try {
        final testRef = database.ref('chats/${currentUser.uid}/messages');
        final snapshot = await testRef.limitToLast(1).get();

        _log('✅ Read permission granted');

        if (snapshot.exists) {
          final data = snapshot.value;
          _log('📊 Data found at path: ${data.runtimeType}');
        } else {
          _log('📭 No data at path (this is OK for new users)');
        }
      } catch (e) {
        _log('❌ Read permission DENIED: $e');
        _log('💡 Fix: Update Firebase Realtime Database security rules');
        setState(() {
          _status = 'Permission Denied';
          _statusColor = Colors.red;
          _isLoading = false;
        });
        return;
      }

      // Test 5: Test Write Permission
      _log('Test 5: Testing write permissions...');
      try {
        final testRef = database.ref('chats/${currentUser.uid}/_test');
        await testRef.set({
          'timestamp': ServerValue.timestamp,
          'test': true,
        });
        _log('✅ Write permission granted');

        // Clean up test data
        await testRef.remove();
        _log('✅ Test data cleaned up');
      } catch (e) {
        _log('❌ Write permission DENIED: $e');
        _log('💡 Fix: Update Firebase Realtime Database security rules');
        setState(() {
          _status = 'Write Permission Denied';
          _statusColor = Colors.orange;
          _isLoading = false;
        });
        return;
      }

      // Test 6: Test Stream
      _log('Test 6: Testing realtime stream...');
      try {
        final messagesRef = database
            .ref('chats/${currentUser.uid}/messages')
            .orderByChild('timestamp')
            .limitToLast(5);

        // Listen for one event
        final event = await messagesRef.once();
        _log('✅ Stream works! Received event');

        if (event.snapshot.value != null) {
          final messages = event.snapshot.value as Map<dynamic, dynamic>;
          _log('📊 Found ${messages.length} messages');
        } else {
          _log('📭 No messages yet (this is OK)');
        }
      } catch (e) {
        _log('❌ Stream failed: $e');
        setState(() {
          _status = 'Stream Error';
          _statusColor = Colors.red;
          _isLoading = false;
        });
        return;
      }

      // All tests passed!
      _log('');
      _log('🎉 ALL TESTS PASSED!');
      _log('✅ Firebase Realtime Database is properly configured');
      _log('✅ Your chat module should work now');

      setState(() {
        _status = 'All Tests Passed ✓';
        _statusColor = Colors.green;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _log('❌ FATAL ERROR: $e');
      _log('Stack trace: $stackTrace');
      setState(() {
        _status = 'Fatal Error';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Configuration Test'),
        backgroundColor: const Color(0xFF9F7AEA),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _statusColor.withOpacity(0.2),
            child: Row(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _statusColor == Colors.green
                        ? Icons.check_circle
                        : _statusColor == Colors.red
                            ? Icons.error
                            : Icons.warning,
                    color: _statusColor,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor = Colors.black87;
                IconData? icon;

                if (log.contains('❌') || log.contains('CRITICAL')) {
                  textColor = Colors.red;
                  icon = Icons.error;
                } else if (log.contains('✅')) {
                  textColor = Colors.green;
                  icon = Icons.check_circle;
                } else if (log.contains('⚠️') || log.contains('WARNING')) {
                  textColor = Colors.orange;
                  icon = Icons.warning;
                } else if (log.contains('💡')) {
                  textColor = Colors.blue;
                  icon = Icons.lightbulb;
                } else if (log.contains('🔍')) {
                  textColor = Colors.purple;
                  icon = Icons.search;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: textColor),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          log,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Help Button
          if (!_isLoading && _statusColor != Colors.green)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('How to Fix'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Follow these steps to fix the issue:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Text('1. Go to Firebase Console'),
                            const Text('2. Enable Realtime Database'),
                            const Text('3. Copy your database URL'),
                            const Text('4. Add to main.dart:'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.grey[200],
                              child: const Text(
                                'FirebaseDatabase.instance.databaseURL = "your-url";',
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                                '5. Update security rules to allow access'),
                            const SizedBox(height: 12),
                            const Text(
                              'See FIREBASE_DATABASE_FIX.md for detailed guide',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.help),
                label: const Text('How to Fix'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9F7AEA),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
