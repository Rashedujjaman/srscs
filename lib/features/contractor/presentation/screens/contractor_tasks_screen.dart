import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';

/// Contractor Tasks Screen
/// 
/// Shows list of assigned tasks/complaints for contractor
class ContractorTasksScreen extends StatelessWidget {
  const ContractorTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: UserRoleExtension(UserRole.contractor).color,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Task List',
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
