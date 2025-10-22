import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';

/// Admin Settings Screen
///
/// Admin system settings and configuration
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: UserRoleExtension(UserRole.admin).color,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'System Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Under Construction'),
          ],
        ),
      ),
    );
  }
}
