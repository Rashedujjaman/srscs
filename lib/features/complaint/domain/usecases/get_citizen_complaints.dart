import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class GetCitizenComplaints {
  final ComplaintRepository repository;

  GetCitizenComplaints(this.repository);

  Future<List<ComplaintEntity>> call(String userId) async {
    return await repository.getCitizenComplaints(userId);
  }
}
