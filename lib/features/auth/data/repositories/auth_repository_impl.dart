import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({required this.remote, FirebaseFirestore? firestore}) : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserEntity> verifyNid({required String nid, required DateTime dob}) async {
    final userModel = await remote.fetchByNid(nid: nid, dob: dob);

    // Check if user already registered in 'citizens' collection
    final existing = await firestore.collection('citizens').where('nid', isEqualTo: nid).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Account already exists');
    }

    return userModel;
  }
}
