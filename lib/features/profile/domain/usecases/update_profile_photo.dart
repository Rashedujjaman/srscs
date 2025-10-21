import '../repositories/profile_repository.dart';

class UpdateProfilePhoto {
  final ProfileRepository repository;

  UpdateProfilePhoto(this.repository);

  Future<String> call({
    required String userId,
    required String photoPath,
  }) async {
    try {
      // Upload photo and get URL
      final photoUrl = await repository.uploadProfilePhoto(
        userId: userId,
        photoPath: photoPath,
      );

      // Update profile with new photo URL
      await repository.updateProfilePhotoUrl(
        userId: userId,
        photoUrl: photoUrl,
      );

      return photoUrl;
    } catch (e) {
      print('Error in UpdateProfilePhoto use case: $e');
      rethrow;
    }
  }
}
