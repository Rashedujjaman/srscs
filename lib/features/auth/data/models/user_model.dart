import '../../domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.nid,
    required super.fullName,
    super.dob,
    super.address,
    super.bloodGroup,
    super.imageUrl,
    super.phoneNumber,
    super.email,
    super.honorScore,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      nid: data['nid']?.toString() ?? '',
      fullName: data['fullName'] ?? '',
      dob: data['dob'],
      address: data['address'],
      bloodGroup: data['bloodGroup'],
      imageUrl: data['imageUrl'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      honorScore: (data['honorScore']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nid': nid,
      'fullName': fullName,
      'dob': dob,
      'address': address,
      'bloodGroup': bloodGroup,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'email': email,
      'honorScore': honorScore,
    };
  }
}
