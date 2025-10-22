import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';

/// Admin Complaints Screen
///
/// Shows all complaints in the system for admin management
class AdminComplaintsScreen extends StatelessWidget {
  const AdminComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Complaints'),
        backgroundColor: UserRoleExtension(UserRole.admin).color,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Complaints Management',
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
