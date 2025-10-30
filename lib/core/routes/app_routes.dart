import 'package:flutter/material.dart';

/// App Routes - Centralized route management for role-based navigation
///
/// This file defines all routes in the application organized by user role

class AppRoutes {
  // ==================== Auth Routes ====================
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String nidVerification = '/nid-verification';

  // ==================== Citizen Routes ====================
  static const String citizenDashboard = '/dashboard';
  static const String submitComplaint = '/submit-complaint';
  static const String trackComplaints = '/track-complaints';
  static const String citizenChat = '/chat';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // ==================== Contractor Routes ====================
  static const String contractorDashboard = '/contractor/dashboard';
  static const String contractorTasks = '/contractor/tasks';
  static const String contractorTaskDetail = '/contractor/task-detail';
  static const String contractorCompleted = '/contractor/completed';
  static const String contractorChat = '/contractor/chat';
  static const String contractorProfile = '/contractor/profile';

  // ==================== Admin Routes ====================
  static const String adminDashboard = '/admin/dashboard';
  static const String adminComplaints = '/admin/complaints';
  static const String adminComplaintDetail = '/admin/complaint-detail';
  static const String adminAssignment = '/admin/assignment';
  static const String adminContractors = '/admin/contractors';
  static const String adminContractorCreate = '/admin/contractors/create';
  static const String adminContractorDetail = '/admin/contractors/detail';
  static const String adminChatManagement = '/admin/chat';
  static const String adminChatDetail = '/admin/chat/detail';
  static const String adminSettings = '/admin/settings';

  /// Get initial route based on user role
  static String getInitialRoute(String role) {
    switch (role.toLowerCase()) {
      case 'citizen':
        return citizenDashboard;
      case 'contractor':
        return contractorDashboard;
      case 'admin':
        return adminDashboard;
      default:
        return login;
    }
  }

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    return route != login && route != register && route != forgotPassword;
  }

  /// Check if route is accessible by role
  static bool isAccessibleByRole(String route, String role) {
    final roleLower = role.toLowerCase();

    // Admin can access all routes
    if (roleLower == 'admin') return true;

    // Contractor routes
    if (route.startsWith('/contractor')) {
      return roleLower == 'contractor';
    }

    // Admin-only routes
    if (route.startsWith('/admin')) {
      return roleLower == 'admin';
    }

    // Citizen routes (default accessible)
    return roleLower == 'citizen';
  }

  /// Get navigation items for bottom navigation based on role
  static List<NavItem> getNavigationItems(String role) {
    switch (role.toLowerCase()) {
      case 'citizen':
        return [
          NavItem(
              label: 'Dashboard',
              route: citizenDashboard,
              icon: Icon(Icons.dashboard)),
          NavItem(
              label: 'Track',
              route: trackComplaints,
              icon: Icon(Icons.track_changes)),
          NavItem(label: 'Chat', route: citizenChat, icon: Icon(Icons.chat)),
          NavItem(label: 'Profile', route: profile, icon: Icon(Icons.person)),
        ];

      case 'contractor':
        return [
          NavItem(
              label: 'Dashboard',
              route: contractorDashboard,
              icon: Icon(Icons.dashboard)),
          NavItem(
              label: 'Tasks',
              route: contractorTasks,
              icon: Icon(Icons.assignment)),
          NavItem(
              label: 'Completed',
              route: contractorCompleted,
              icon: Icon(Icons.check)),
          NavItem(label: 'Chat', route: contractorChat, icon: Icon(Icons.chat)),
          NavItem(
              label: 'Profile',
              route: contractorProfile,
              icon: Icon(Icons.person)),
        ];

      case 'admin':
        return [
          NavItem(
              label: 'Dashboard',
              route: adminDashboard,
              icon: Icon(Icons.dashboard)),
          NavItem(
              label: 'Complaints',
              route: adminComplaints,
              icon: Icon(Icons.list)),
          NavItem(
              label: 'Assign',
              route: adminAssignment,
              icon: Icon(Icons.assignment_ind)),
          NavItem(
              label: 'Contractors',
              route: adminContractors,
              icon: Icon(Icons.engineering)),
          NavItem(
              label: 'Chat',
              route: adminChatManagement,
              icon: Icon(Icons.chat)),
        ];

      default:
        return [];
    }
  }

  /// Get route title for app bar
  static String getRouteTitle(String route) {
    switch (route) {
      // Auth
      case login:
        return 'Login';
      case register:
        return 'Register';
      case forgotPassword:
        return 'Forgot Password';
      case nidVerification:
        return 'NID Verification';

      // Citizen
      case citizenDashboard:
        return 'Dashboard';
      case submitComplaint:
        return 'Submit Complaint';
      case trackComplaints:
        return 'Track Complaints';
      case citizenChat:
        return 'Chat with Admin';
      case profile:
        return 'Profile';

      // Contractor
      case contractorDashboard:
        return 'Contractor Dashboard';
      case contractorTasks:
        return 'My Tasks';
      case contractorTaskDetail:
        return 'Task Details';
      case contractorCompleted:
        return 'Completed Tasks';
      case contractorChat:
        return 'Chat with Admin';
      case contractorProfile:
        return 'Profile';

      // Admin
      case adminDashboard:
        return 'Admin Dashboard';
      case adminComplaints:
        return 'All Complaints';
      case adminComplaintDetail:
        return 'Complaint Details';
      case adminAssignment:
        return 'Assign Complaints';
      case adminContractors:
        return 'Manage Contractors';
      case adminContractorCreate:
        return 'Create Contractor';
      case adminContractorDetail:
        return 'Contractor Details';
      case adminChatManagement:
        return 'Chat Management';
      case adminChatDetail:
        return 'Chat Details';
      case adminSettings:
        return 'Settings';

      default:
        return 'SRSCS';
    }
  }
}

/// Navigation item model for bottom navigation
class NavItem {
  final String label;
  final String route;
  final Icon icon;

  NavItem({
    required this.label,
    required this.route,
    required this.icon,
  });
}
