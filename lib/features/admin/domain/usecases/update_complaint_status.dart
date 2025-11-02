import 'package:srscs/features/complaint/domain/entities/complaint_entity.dart';

import '../repositories/admin_repository.dart';

/// Update Complaint Status Use Case
///
/// Updates the status of a complaint with admin notes
class UpdateComplaintStatus {
  final AdminRepository repository;

  UpdateComplaintStatus(this.repository);

  Future<void> call({
    required String complaintId,
    required ComplaintStatus status,
    String? adminNotes,
  }) {
    return repository.updateComplaintStatus(
      complaintId: complaintId,
      status: status,
      adminNotes: adminNotes,
    );
  }
}
