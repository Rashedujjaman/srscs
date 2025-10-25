import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required super.id,
    required super.nid,
    required super.fullName,
    required super.email,
    super.phoneNumber,
    super.address,
    super.bloodGroup,
    super.dob,
    super.profilePhotoUrl,
    super.updatedAt,
  });

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProfileModel(
      id: doc.id,
      nid: data['nid']?.toString() ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      dob: data['dob'] ?? '',
      profilePhotoUrl: data['imageUrl'] ?? '',
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nid': nid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'bloodGroup': bloodGroup,
      'dob': dob,
      'imageUrl': profilePhotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      id: entity.id,
      nid: entity.nid,
      fullName: entity.fullName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      address: entity.address,
      bloodGroup: entity.bloodGroup,
      dob: entity.dob,
      profilePhotoUrl: entity.profilePhotoUrl,
      updatedAt: entity.updatedAt,
    );
  }
}
