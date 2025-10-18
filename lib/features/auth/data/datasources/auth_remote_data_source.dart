import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> fetchByNid({required String nid, required DateTime dob});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> fetchByNid(
      {required String nid, required DateTime dob}) async {
    final ts = Timestamp.fromDate(DateTime(dob.year, dob.month, dob.day, 6));
    final query = await firestore
        .collection('nid_sample')
        .where('nid', isEqualTo: nid)
        // .where('dob', isEqualTo: ts)
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('No matching NID found');

    return UserModel.fromFirestore(query.docs.first);
  }
}
