/// Contractor model - Data layer
///
/// Firestore serialization for ContractorEntity

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/contractor_entity.dart';

class ContractorModel extends ContractorEntity {
  ContractorModel({
    required String id,
    required String email,
    required String fullName,
    required String phoneNumber,
    required String assignedArea,
    required String createdBy,
    required DateTime createdAt,
    bool isActive = true,
  }) : super(
          id: id,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          assignedArea: assignedArea,
          createdBy: createdBy,
          createdAt: createdAt,
          isActive: isActive,
        );

  /// Create from Firestore document
  factory ContractorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContractorModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      assignedArea: data['assignedArea'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'assignedArea': assignedArea,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'role': 'contractor', // Always contractor
    };
  }

  /// Create a copy with updated fields
  ContractorModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? assignedArea,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ContractorModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      assignedArea: assignedArea ?? this.assignedArea,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
