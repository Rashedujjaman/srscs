import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyNid {
  final AuthRepository repository;

  VerifyNid(this.repository);

  Future<UserEntity> call({required String nid, required DateTime dob}) async {
    return await repository.verifyNid(nid: nid, dob: dob);
  }
}
