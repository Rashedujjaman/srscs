/// Role-based helper utilities for authorization and routing
///
/// This file provides utility functions for role-based access control,
/// route determination, and permission checking.
library;

import 'package:flutter/material.dart';
import '../constants/user_roles.dart';

/// Helper class for role-based operations
class RoleHelper {
  /// Get the dashboard route based on user role
  static String getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return '/dashboard';
      case UserRole.contractor:
        return '/contractor/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
    }
  }

  /// Get the initial route after login based on role
  static String getInitialRoute(UserRole role) {
    return getDashboardRoute(role);
  }

  /// Check if user can access a specific route based on role
  static bool canAccessRoute(UserRole role, String route) {
    // Admin can access all routes
    if (role.isAdmin) return true;

    // Contractor routes
    if (route.startsWith('/contractor')) {
      return role.isContractor || role.isAdmin;
    }

    // Admin routes
    if (route.startsWith('/admin')) {
      return role.isAdmin;
    }

    // Citizen routes and shared routes
    return true;
  }

  /// Get navigation items based on user role
  static List<NavigationItem> getNavigationItems(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return [
          NavigationItem(
            label: 'Dashboard',
            icon: Icons.home,
            route: '/dashboard',
          ),
          NavigationItem(
            label: 'Submit',
            icon: Icons.add_box,
            route: '/submit-complaint',
          ),
          NavigationItem(
            label: 'Track',
            icon: Icons.track_changes,
            route: '/track-complaints',
          ),
          NavigationItem(
            label: 'Chat',
            icon: Icons.chat,
            route: '/chat',
          ),
          NavigationItem(
            label: 'Profile',
            icon: Icons.person,
            route: '/profile',
          ),
        ];

      case UserRole.contractor:
        return [
          NavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard,
            route: '/contractor/dashboard',
          ),
          NavigationItem(
            label: 'Tasks',
            icon: Icons.assignment,
            route: '/contractor/tasks',
          ),
          NavigationItem(
            label: 'Completed',
            icon: Icons.check_circle,
            route: '/contractor/completed',
          ),
          NavigationItem(
            label: 'Chat',
            icon: Icons.chat,
            route: '/contractor/chat',
          ),
          NavigationItem(
            label: 'Profile',
            icon: Icons.person,
            route: '/profile',
          ),
        ];

      case UserRole.admin:
        return [
          NavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_customize,
            route: '/admin/dashboard',
          ),
          NavigationItem(
            label: 'Complaints',
            icon: Icons.list_alt,
            route: '/admin/complaints',
          ),
          NavigationItem(
            label: 'Assign',
            icon: Icons.assignment_ind,
            route: '/admin/assign',
          ),
          NavigationItem(
            label: 'Contractors',
            icon: Icons.engineering,
            route: '/admin/contractors',
          ),
          NavigationItem(
            label: 'Chat',
            icon: Icons.chat_bubble,
            route: '/admin/chat',
          ),
        ];
    }
  }

  /// Get app bar title based on current route
  static String getAppBarTitle(String route) {
    if (route.startsWith('/contractor')) {
      if (route.contains('dashboard')) return 'Contractor Dashboard';
      if (route.contains('tasks')) return 'My Tasks';
      if (route.contains('completed')) return 'Completed Tasks';
      if (route.contains('chat')) return 'Chat with Admin';
    }

    if (route.startsWith('/admin')) {
      if (route.contains('dashboard')) return 'Admin Dashboard';
      if (route.contains('complaints')) return 'All Complaints';
      if (route.contains('assign')) return 'Assign Complaints';
      if (route.contains('contractors')) return 'Manage Contractors';
      if (route.contains('chat')) return 'Chat Management';
    }

    if (route.contains('dashboard')) return 'Dashboard';
    if (route.contains('submit')) return 'Submit Complaint';
    if (route.contains('track')) return 'Track Complaints';
    if (route.contains('chat')) return 'Chat with Admin';
    if (route.contains('profile')) return 'Profile';

    return 'SRSCS';
  }

  /// Show role badge widget
  static Widget buildRoleBadge(UserRole role, {double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.1),
        border: Border.all(color: role.color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: fontSize + 2, color: role.color),
          const SizedBox(width: 4),
          Text(
            role.displayName,
            style: TextStyle(
              color: role.color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Check if user can perform an action on a complaint
  static bool canPerformComplaintAction(
    UserRole userRole,
    String action,
    String? complainantId,
    String? assignedTo,
    String userId,
  ) {
    switch (action) {
      case 'view':
        // Admin can view all, contractor can view assigned, citizen can view own
        if (userRole.isAdmin) return true;
        if (userRole.isContractor) return assignedTo == userId;
        return complainantId == userId;

      case 'edit':
        // Only complainant can edit (before assignment)
        return complainantId == userId && assignedTo == null;

      case 'delete':
        // Only admin or complainant (before assignment) can delete
        return userRole.isAdmin ||
            (complainantId == userId && assignedTo == null);

      case 'assign':
        // Only admin can assign
        return userRole.isAdmin;

      case 'updateStatus':
        // Admin or assigned contractor can update status
        return userRole.isAdmin ||
            (userRole.isContractor && assignedTo == userId);

      case 'addNotes':
        // Admin or assigned contractor can add notes
        return userRole.isAdmin ||
            (userRole.isContractor && assignedTo == userId);

      default:
        return false;
    }
  }

  /// Validate contractor creation data
  static String? validateContractorData({
    required String email,
    required String fullName,
    required String phone,
    required String area,
  }) {
    if (email.isEmpty || !email.contains('@')) {
      return 'Please enter a valid email address';
    }

    if (fullName.isEmpty || fullName.length < 3) {
      return 'Full name must be at least 3 characters';
    }

    if (phone.isEmpty || phone.length < 10) {
      return 'Please enter a valid phone number';
    }

    if (!AvailableAreas.isValidArea(area)) {
      return 'Please select a valid area';
    }

    return null; // Valid
  }

  /// Get statistics label based on role
  static String getStatisticsLabel(UserRole role, String statType) {
    if (role.isContractor) {
      switch (statType) {
        case 'total':
          return 'Assigned Tasks';
        case 'pending':
          return 'Pending Tasks';
        case 'inProgress':
          return 'Active Tasks';
        case 'completed':
          return 'Completed Tasks';
        default:
          return statType;
      }
    }

    if (role.isAdmin) {
      switch (statType) {
        case 'total':
          return 'Total Complaints';
        case 'pending':
          return 'Unassigned';
        case 'inProgress':
          return 'In Progress';
        case 'completed':
          return 'Resolved';
        default:
          return statType;
      }
    }

    // Citizen
    switch (statType) {
      case 'total':
        return 'My Complaints';
      case 'pending':
        return 'Pending';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Resolved';
      default:
        return statType;
    }
  }
}

/// Navigation item model
class NavigationItem {
  final String label;
  final IconData icon;
  final String route;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
