import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required String id,
    required String nid,
    required String fullName,
    required String email,
    String? phone,
    String? address,
    String? bloodGroup,
    DateTime? dob,
    String? profilePhotoUrl,
    DateTime? updatedAt,
  }) : super(
          id: id,
          nid: nid,
          fullName: fullName,
          email: email,
          phone: phone,
          address: address,
          bloodGroup: bloodGroup,
          dob: dob,
          profilePhotoUrl: profilePhotoUrl,
          updatedAt: updatedAt,
        );

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProfileModel(
      id: doc.id,
      nid: data['nid']?.toString() ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      address: data['address'],
      bloodGroup: data['bloodGroup'],
      dob:
          data['dob'] is Timestamp ? (data['dob'] as Timestamp).toDate() : null,
      profilePhotoUrl: data['imageUrl'],
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
      'phone': phone,
      'address': address,
      'bloodGroup': bloodGroup,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
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
      phone: entity.phone,
      address: entity.address,
      bloodGroup: entity.bloodGroup,
      dob: entity.dob,
      profilePhotoUrl: entity.profilePhotoUrl,
      updatedAt: entity.updatedAt,
    );
  }
}
