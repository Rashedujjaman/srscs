/// Contractor entity - Domain layer
///
/// Represents a contractor user who can be assigned complaints by admins

class ContractorEntity {
  final String id; // Firebase Auth UID
  final String email;
  final String fullName;
  final String phoneNumber;
  final String assignedArea; // Area where contractor works
  final String createdBy; // Admin ID who created this contractor
  final DateTime createdAt;
  final bool isActive; // Can be deactivated by admin

  ContractorEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.assignedArea,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  /// Get status display text
  String get statusText => isActive ? 'Active' : 'Inactive';

  /// Check if contractor can be assigned tasks
  bool get canBeAssigned => isActive;
}
