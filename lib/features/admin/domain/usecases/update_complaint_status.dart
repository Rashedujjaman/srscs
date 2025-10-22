import '../repositories/admin_repository.dart';

/// Update Complaint Status Use Case
///
/// Updates the status of a complaint with admin notes
class UpdateComplaintStatus {
  final AdminRepository repository;

  UpdateComplaintStatus(this.repository);

  Future<void> call({
    required String complaintId,
    required String status,
    String? adminNotes,
  }) {
    return repository.updateComplaintStatus(
      complaintId: complaintId,
      status: status,
      adminNotes: adminNotes,
    );
  }
}
