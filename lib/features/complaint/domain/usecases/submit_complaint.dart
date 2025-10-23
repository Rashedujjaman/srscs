import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class SubmitComplaint {
  final ComplaintRepository repository;

  SubmitComplaint(this.repository);

  Future<String> call({
    required String userId,
    required String userName,
    required ComplaintType type,
    required String description,
    required List<String> mediaFiles,
    Map<String, double>? location,
    String? area,
    String? landmark,
  }) async {
    return await repository.submitComplaint(
      userId: userId,
      userName: userName,
      type: type,
      description: description,
      mediaFiles: mediaFiles,
      location: location,
      area: area,
      landmark: landmark,
    );
  }
}
