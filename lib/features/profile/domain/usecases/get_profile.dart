import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;

  GetProfile(this.repository);

  Future<ProfileEntity> call(String userId) async {
    try {
      return await repository.getProfile(userId);
    } catch (e) {
      print('Error in GetProfile use case: $e');
      rethrow;
    }
  }
}
