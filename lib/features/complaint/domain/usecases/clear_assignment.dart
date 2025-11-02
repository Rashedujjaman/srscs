import 'package:srscs/features/complaint/domain/repositories/complaint_repository.dart';

/// Clears the assignment for a specific complaint
class ClearAssignment {
  final ComplaintRepository repository;

  ClearAssignment(this.repository);

  Future<void> call(String complaintId) async {
    return repository.clearAssignment(complaintId);
  }
}
