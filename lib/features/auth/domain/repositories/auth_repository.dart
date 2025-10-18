import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Verify NID and DOB. Returns a UserEntity on success or throws on failure.
  Future<UserEntity> verifyNid({required String nid, required DateTime dob});
}
