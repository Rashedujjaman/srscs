import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';

/// Contractor Task Detail Screen
///
/// Shows detailed information about a specific assigned task
class ContractorTaskDetailScreen extends StatelessWidget {
  const ContractorTaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: UserRoleExtension(UserRole.contractor).color,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Task Details',
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
