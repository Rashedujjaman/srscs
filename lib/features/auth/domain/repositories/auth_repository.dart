import 'package:srscs/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  /// Verify NID and DOB. Returns a UserModel on success or throws on failure.
  Future<UserModel> verifyNid({required String nid, required String dob});
}
