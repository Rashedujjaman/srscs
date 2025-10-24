import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> fetchByNid({required String nid, required String dob});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> fetchByNid(
      {required String nid, required String dob}) async {
    try {
      final query = await firestore
          .collection('nid_sample')
          .where('nid', isEqualTo: nid)
          .where('dob', isEqualTo: dob)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('No matching NID found');
      }

      return UserModel.fromFirestore(query.docs.first);
    } catch (e) {
      if (e.toString().contains('No matching NID found')) {
        rethrow;
      }
      throw Exception('Failed to verify NID: ${e.toString()}');
    }
  }
}
