import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nid;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? imageUrl;
  final bool? isActive;

  UserModel({
    required this.uid,
    required this.nid,
    required this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.imageUrl,
    this.isActive,
  });

  // Convert a UserModel object into a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nid': nid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  // Create a UserModel object from a Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nid: map['nid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? false,
    );
  }

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nid: data['nid'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? false,
    );
  }
}
