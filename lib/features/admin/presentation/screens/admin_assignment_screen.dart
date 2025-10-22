import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';

/// Admin Assignment Screen
///
/// Interface for assigning complaints to contractors
class AdminAssignmentScreen extends StatelessWidget {
  const AdminAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Complaints'),
        backgroundColor: UserRoleExtension(UserRole.admin).color,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Assignment System',
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
