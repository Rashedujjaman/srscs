import '../entities/complaint_entity.dart';

abstract class ComplaintRepository {
  /// Submit a new complaint (both online and offline)
  Future<String> submitComplaint({
    required String userId,
    required String userName,
    required ComplaintType type,
    required String description,
    required List<String> mediaFiles,
    Map<String, double>? location,
  });

  /// Get complaints for a specific user
  Future<List<ComplaintEntity>> getUserComplaints(String userId);

  /// Get all complaints (for admin)
  Future<List<ComplaintEntity>> getAllComplaints();

  /// Update complaint status (admin only)
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminNotes,
    String? assignedTo,
  });

  /// Sync offline complaints to server
  Future<void> syncOfflineComplaints();

  /// Get unsynced complaints count
  Future<int> getUnsyncedCount();
}
