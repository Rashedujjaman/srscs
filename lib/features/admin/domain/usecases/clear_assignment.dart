import '../repositories/admin_repository.dart';

/// Clears the assignment for a specific complaint
class ClearAssignment {
  final AdminRepository repository;

  ClearAssignment(this.repository);

  Future<void> call(String complaintId) async {
    return repository.clearAssignment(complaintId);
  }
}
