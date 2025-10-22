import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';

/// Admin Complaint Detail Screen
///
/// Shows detailed information about a specific complaint for admin
class AdminComplaintDetailScreen extends StatelessWidget {
  const AdminComplaintDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: UserRoleExtension(UserRole.admin).color,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Complaint Details',
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
