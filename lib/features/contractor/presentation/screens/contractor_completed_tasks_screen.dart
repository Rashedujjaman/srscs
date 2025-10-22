import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';

/// Contractor Completed Tasks Screen
///
/// Shows list of completed tasks by contractor
class ContractorCompletedTasksScreen extends StatelessWidget {
  const ContractorCompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        backgroundColor: UserRoleExtension(UserRole.contractor).color,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Completed Tasks',
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
