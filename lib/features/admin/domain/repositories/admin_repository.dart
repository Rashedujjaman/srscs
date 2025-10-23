import 'package:srscs/features/complaint/domain/entities/complaint_entity.dart';

/// Admin Repository Interface
///
/// Defines the contract for admin data operations
abstract class AdminRepository {
  /// Get all complaints in the system
  Stream<List<ComplaintEntity>> getAllComplaints();

  Stream<List<ComplaintEntity>> getRecentComplaints();

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStatistics();

  /// Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminNotes,
  });

  /// Get complaint by ID
  Future<Map<String, dynamic>?> getComplaintById(String complaintId);
}
