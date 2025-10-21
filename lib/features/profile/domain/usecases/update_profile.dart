import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<void> call({
    required String userId,
    required String fullName,
    required String phone,
    required String address,
    required String bloodGroup,
    required DateTime dob,
  }) async {
    try {
      await repository.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        address: address,
        bloodGroup: bloodGroup,
        dob: dob,
      );
    } catch (e) {
      print('Error in UpdateProfile use case: $e');
      rethrow;
    }
  }
}
