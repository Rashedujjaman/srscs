import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:srscs/features/auth/data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({required this.remote, FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> verifyNid(
      {required String nid, required String dob}) async {
    final userModel = await remote.fetchByNid(nid: nid, dob: dob);

    // Check if user already registered in 'citizens' collection
    final existing = await firestore
        .collection('citizens')
        .where('nid', isEqualTo: nid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Account already exists');
    }

    return userModel;
  }
}
