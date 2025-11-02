import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class GetContractorComplaints {
  final ComplaintRepository repository;

  GetContractorComplaints(this.repository);

  Future<List<ComplaintEntity>> call(String contractorId) async {
    return await repository.getContractorComplaints(contractorId);
  }
}
