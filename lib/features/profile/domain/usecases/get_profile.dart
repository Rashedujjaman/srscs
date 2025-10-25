import 'package:srscs/features/profile/data/models/profile_model.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;

  GetProfile(this.repository);

  Future<ProfileModel> call(String userId) async {
    try {
      return await repository.getProfile(userId);
    } catch (e) {
      rethrow;
    }
  }
}
