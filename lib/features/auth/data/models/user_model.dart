import '../../domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends UserEntity {
  UserModel({
    required String id,
    required String nid,
    required String fullName,
    DateTime? dob,
    String? address,
    String? bloodGroup,
    String? imageUrl,
    String? phoneNumber,
    String? email,
  }) : super(
          id: id,
          nid: nid,
          fullName: fullName,
          dob: dob,
          address: address,
          bloodGroup: bloodGroup,
          imageUrl: imageUrl,
          phoneNumber: phoneNumber,
          email: email,
        );

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final Timestamp? ts = data['dob'] as Timestamp?;
    return UserModel(
        id: doc.id,
        nid: data['nid']?.toString() ?? '',
        fullName: data['fullName'] ?? '',
        dob: ts?.toDate(),
        address: data['address'],
        bloodGroup: data['bloodGroup'],
        imageUrl: data['imageUrl'],
        phoneNumber: data['phoneNumber'],
        email: data['email']);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nid': nid,
      'fullName': fullName,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'address': address,
      'bloodGroup': bloodGroup,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }
}
