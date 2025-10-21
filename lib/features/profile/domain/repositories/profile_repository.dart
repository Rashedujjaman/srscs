import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Get user profile by user ID
  Future<ProfileEntity> getProfile(String userId);

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String address,
    required String bloodGroup,
    required DateTime dob,
  });

  /// Upload profile photo and return download URL
  Future<String> uploadProfilePhoto({
    required String userId,
    required String photoPath,
  });

  /// Update profile photo URL in database
  Future<void> updateProfilePhotoUrl({
    required String userId,
    required String photoUrl,
  });
}
