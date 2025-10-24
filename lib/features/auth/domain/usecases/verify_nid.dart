import 'package:srscs/features/auth/data/models/user_model.dart';
import '../repositories/auth_repository.dart';

class VerifyNid {
  final AuthRepository repository;

  VerifyNid(this.repository);

  Future<UserModel> call({required String nid, required String dob}) async {
    return await repository.verifyNid(nid: nid, dob: dob);
  }
}
