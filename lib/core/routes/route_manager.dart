/// Route Manager - Handles navigation with role-based access control
///
/// Provides middleware for:
/// - Authentication checking
/// - Role-based access control
/// - Route guarding
/// - Automatic redirects
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/user_roles.dart';
import 'app_routes.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._internal();
  factory RouteManager() => _instance;
  RouteManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Navigate with role checking
  Future<void> navigateWithRoleCheck(
    BuildContext context,
    String route, {
    Map<String, dynamic>? arguments,
  }) async {
    // Check if authenticated
    if (!isAuthenticated && AppRoutes.requiresAuth(route)) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // Check role-based access
    if (isAuthenticated) {
      final userId = currentUserId!;
      final userRole = await _authService.getUserRole(userId);

      if (userRole == null) {
        // User role not found, logout
        await logout();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      if (!AppRoutes.isAccessibleByRole(route, userRole.value)) {
        final dashboardRoute = AppRoutes.getInitialRoute(userRole.value);
        Get.offAllNamed(dashboardRoute);
        // Access denied, show error and navigate to appropriate dashboard
        _showAccessDeniedDialog();
        return;
      }
    }

    // Navigate to route
    if (arguments != null) {
      Get.toNamed(route, arguments: arguments);
    } else {
      Get.toNamed(route);
    }
  }

  /// Navigate and replace with role checking
  Future<void> navigateAndReplaceWithRoleCheck(
    BuildContext context,
    String route, {
    Map<String, dynamic>? arguments,
  }) async {
    // Check if authenticated
    if (!isAuthenticated && AppRoutes.requiresAuth(route)) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // Check role-based access
    if (isAuthenticated) {
      final userId = currentUserId!;
      final userRole = await _authService.getUserRole(userId);

      if (userRole == null) {
        await logout();
        Get.toNamed(AppRoutes.login);
        return;
      }

      if (!AppRoutes.isAccessibleByRole(route, userRole.value)) {
        _showAccessDeniedDialog();
        final dashboardRoute = AppRoutes.getInitialRoute(userRole.value);
        Get.toNamed(dashboardRoute);
        return;
      }
    }

    // Navigate to route
    if (arguments != null) {
      Get.toNamed(route, arguments: arguments);
    } else {
      Get.toNamed(route);
    }
  }

  /// Navigate to role-specific dashboard
  Future<void> navigateToDashboard(BuildContext context) async {
    if (!isAuthenticated) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final userId = currentUserId!;
    final userRole = await _authService.getUserRole(userId);

    if (userRole == null) {
      await _auth.signOut();
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final dashboardRoute = AppRoutes.getInitialRoute(userRole.value);
    Get.offAllNamed(dashboardRoute);
  }

  /// Get navigation items for current user
  Future<List<NavItem>> getNavigationItems() async {
    if (!isAuthenticated) return [];

    final userId = currentUserId!;
    final userRole = await _authService.getUserRole(userId);

    if (userRole == null) return [];

    return AppRoutes.getNavigationItems(userRole.value);
  }

  /// Logout and navigate to login
  Future<void> logout() async {
    final notificationService = NotificationService();

    // Unsubscribe from all topics
    await notificationService.unsubscribeFromTopic('all_users');
    await notificationService.unsubscribeFromTopic('urgent_notices');
    await notificationService.unsubscribeFromTopic('citizen_updates');
    await notificationService.unsubscribeFromTopic('contractor_updates');
    await notificationService.unsubscribeFromTopic('admin_updates');

    // Delete FCM token from current device
    await notificationService.deleteToken();

    await _auth.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  /// Show access denied dialog
  void _showAccessDeniedDialog() {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text(
          'You do not have permission to access this page.',
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

  /// Route guard middleware
  /// Returns true if navigation should proceed, false otherwise
  Future<bool> routeGuard(
    BuildContext context,
    String route,
  ) async {
    // Public routes
    if (!AppRoutes.requiresAuth(route)) {
      return true;
    }

    // Check authentication
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return false;
    }

    // Check role-based access
    final userId = currentUserId!;
    final userRole = await _authService.getUserRole(userId);

    if (userRole == null) {
      await _auth.signOut();
      Get.toNamed(AppRoutes.login);
      return false;
    }

    if (!AppRoutes.isAccessibleByRole(route, userRole.value)) {
      _showAccessDeniedDialog();
      return false;
    }

    return true;
  }

  /// Get current user role
  Future<UserRole?> getCurrentUserRole() async {
    if (!isAuthenticated) return null;

    final userId = currentUserId!;
    return await _authService.getUserRole(userId);
  }

  /// Check if current user has permission
  Future<bool> hasPermission(String permission) async {
    final role = await getCurrentUserRole();
    if (role == null) return false;

    switch (permission) {
      case 'createContractor':
        return role.canCreateContractors;
      case 'assignComplaint':
        return role.canAssignComplaints;
      case 'viewAllComplaints':
        return role.canViewAllComplaints;
      case 'updateComplaintStatus':
        return role.canUpdateComplaintStatus;
      case 'manageUsers':
        return role.canManageUsers;
      default:
        return false;
    }
  }

  /// Launch external URL
  Future<void> launchURL(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Extension for easy navigation context
extension NavigationExtension on BuildContext {
  RouteManager get routeManager => RouteManager();

  Future<void> navigateToWithRoleCheck(String route,
      {Map<String, dynamic>? arguments}) {
    return routeManager.navigateWithRoleCheck(this, route,
        arguments: arguments);
  }

  Future<void> navigateToDashboard() {
    return routeManager.navigateToDashboard(this);
  }

  Future<void> logout() {
    return routeManager.logout();
  }
}
