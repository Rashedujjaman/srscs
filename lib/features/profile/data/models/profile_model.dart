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
    super.role,
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
      role: data['role'] ?? 'citizen',
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
      'role': role,
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
      role: entity.role,
    );
  }

  ProfileModel copyWith({
    String? id,
    String? nid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? bloodGroup,
    String? dob,
    String? profilePhotoUrl,
    DateTime? updatedAt,
    String? role,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      nid: nid ?? this.nid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dob: dob ?? this.dob,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }
}
