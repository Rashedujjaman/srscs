/// User role definitions for role-based access control
///
/// This file defines the user roles used throughout the application
/// for implementing role-based authentication and authorization.

import 'package:flutter/material.dart';

/// Available user roles in the system
enum UserRole {
  /// Regular citizens who can submit and track complaints
  citizen,

  /// Contractors who handle assigned complaints
  contractor,

  /// Administrators who manage the system
  admin,
}

/// Extension to provide utility methods for UserRole
extension UserRoleExtension on UserRole {
  /// Get the display name for the role
  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.contractor:
        return 'Contractor';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// Get the database value for the role (lowercase string)
  String get value {
    switch (this) {
      case UserRole.citizen:
        return 'citizen';
      case UserRole.contractor:
        return 'contractor';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// Get the color associated with each role
  Color get color {
    switch (this) {
      case UserRole.citizen:
        return const Color(0xFF9F7AEA); // Purple
      case UserRole.contractor:
        return const Color(0xFF4299E1); // Blue
      case UserRole.admin:
        return const Color(0xFFF56565); // Red
    }
  }

  /// Get the icon associated with each role
  IconData get icon {
    switch (this) {
      case UserRole.citizen:
        return Icons.person;
      case UserRole.contractor:
        return Icons.engineering;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  /// Check if this role is admin
  bool get isAdmin => this == UserRole.admin;

  /// Check if this role is contractor
  bool get isContractor => this == UserRole.contractor;

  /// Check if this role is citizen
  bool get isCitizen => this == UserRole.citizen;

  /// Check if this role can create contractors
  bool get canCreateContractors => isAdmin;

  /// Check if this role can assign complaints
  bool get canAssignComplaints => isAdmin;

  /// Check if this role can view all complaints
  bool get canViewAllComplaints => isAdmin;

  /// Check if this role can update complaint status
  bool get canUpdateComplaintStatus => isAdmin || isContractor;

  /// Check if this role can chat with admin
  bool get canChatWithAdmin => isCitizen || isContractor;

  /// Check if this role can manage users
  bool get canManageUsers => isAdmin;
}

/// Parse a string value to UserRole enum
UserRole? parseUserRole(String? value) {
  if (value == null) return null;

  switch (value.toLowerCase()) {
    case 'citizen':
      return UserRole.citizen;
    case 'contractor':
      return UserRole.contractor;
    case 'admin':
      return UserRole.admin;
    default:
      return null;
  }
}

/// Available areas/locations for complaint assignment
class AvailableAreas {
  static const List<String> areas = [
    'Bagerhat',
    'Bandarban',
    'Barguna',
    'Barisal',
    'Bhola',
    'Bogra',
    'Brahmanbaria',
    'Chandpur',
    'Chittagong',
    'Chuadanga',
    'Chapainawabganj',
    'Comilla',
    'Cox\'s Bazar',
    'Dhaka',
    'Dinajpur',
    'Faridpur',
    'Feni',
    'Gaibandha',
    'Gazipur',
    'Gopalganj',
    'Habiganj',
    'Jamalpur',
    'Jashore',
    'Jhalokati',
    'Jhenaidah',
    'Joypurhat',
    'Khagrachari',
    'Khulna',
    'Kishoreganj',
    'Kurigram',
    'Kushtia',
    'Lakshmipur',
    'Lalmonirhat',
    'Madaripur',
    'Magura',
    'Manikganj',
    'Meherpur',
    'Moulvibazar',
    'Munshiganj',
    'Mymensingh',
    'Naogaon',
    'Narail',
    'Narayanganj',
    'Narsingdi',
    'Natore',
    'Netrokona',
    'Nilphamari',
    'Noakhali',
    'Pabna',
    'Panchagarh',
    'Patuakhali',
    'Pirojpur',
    'Rajbari',
    'Rajshahi',
    'Rangamati',
    'Rangpur',
    'Satkhira',
    'Shariatpur',
    'Sherpur',
    'Sirajganj',
    'Sunamganj',
    'Sylhet',
    'Tangail',
    'Thakurgaon',
  ];

  /// Get area display name
  static String getDisplayName(String area) {
    return area.replaceAll('-', ' - ');
  }

  /// Check if area is valid
  static bool isValidArea(String area) {
    return areas.contains(area);
  }
}

/// Complaint status values
enum ComplaintStatus {
  /// Newly submitted, not yet reviewed
  pending,

  /// Admin has reviewed but not assigned
  underReview,

  /// Assigned to contractor and in progress
  inProgress,

  /// Work completed by contractor
  resolved,

  /// Rejected by admin
  rejected,
}

extension ComplaintStatusExtension on ComplaintStatus {
  String get displayName {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.underReview:
        return 'Under Review';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.underReview:
        return Colors.blue;
      case ComplaintStatus.inProgress:
        return Colors.purple;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.pending:
        return Icons.pending;
      case ComplaintStatus.underReview:
        return Icons.rate_review;
      case ComplaintStatus.inProgress:
        return Icons.construction;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }
}
