import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/route_manager.dart';
import '../../../../core/constants/user_roles.dart';

/// Contractor Dashboard Screen
///
/// Main screen for contractors showing:
/// - Task statistics
/// - Assigned complaints
/// - Quick actions
class ContractorDashboardScreen extends StatelessWidget {
  const ContractorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Dashboard'),
        backgroundColor: UserRoleExtension(UserRole.contractor).color,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => RouteManager().logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Contractor Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Under Construction'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final navItems = AppRoutes.getNavigationItems('contractor');

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      items: navItems
          .map((item) => BottomNavigationBarItem(
                icon: _getIcon(item.icon),
                label: item.label,
              ))
          .toList(),
      onTap: (index) {
        RouteManager().navigateWithRoleCheck(
          context,
          navItems[index].route,
        );
      },
      selectedItemColor: UserRoleExtension(UserRole.contractor).color,
    );
  }

  Icon _getIcon(String iconName) {
    switch (iconName) {
      case 'dashboard':
        return const Icon(Icons.dashboard);
      case 'assignment':
        return const Icon(Icons.assignment);
      case 'check':
        return const Icon(Icons.check_circle);
      case 'chat':
        return const Icon(Icons.chat);
      case 'person':
        return const Icon(Icons.person);
      default:
        return const Icon(Icons.help);
    }
  }
}
