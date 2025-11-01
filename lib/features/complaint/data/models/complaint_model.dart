import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/complaint_entity.dart';

class ComplaintModel extends ComplaintEntity {
  ComplaintModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.type,
    required super.description,
    super.mediaUrls,
    super.location,
    super.area,
    super.landmark,
    super.status,
    required super.createdAt,
    super.updatedAt,
    super.assignedTo,
    super.assignedBy,
    super.assignedAt,
    super.completedAt,
    super.adminNotes,
    super.contractorNotes,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: ComplaintType.values.firstWhere(
        (e) => e.toString() == 'ComplaintType.${data['type']}',
        orElse: () => ComplaintType.other,
      ),
      description: data['description'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      location: data['location'] != null
          ? Map<String, double>.from(data['location'])
          : null,
      area: data['area'],
      landmark: data['landmark'],
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == 'ComplaintStatus.${data['status']}',
        orElse: () => ComplaintStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      assignedTo: data['assignedTo'],
      assignedBy: data['assignedBy'],
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      adminNotes: data['adminNotes'],
      contractorNotes: data['contractorNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.value,
      'description': description,
      'mediaUrls': mediaUrls,
      'location': location,
      'area': area,
      'landmark': landmark,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'adminNotes': adminNotes,
      'contractorNotes': contractorNotes,
    };
  }

  // For SQLite offline storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'type': type.value,
      'description': description,
      'mediaUrls': mediaUrls.join(','),
      'locationLat': location?['lat'],
      'locationLng': location?['lng'],
      'area': area,
      'landmark': landmark,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'adminNotes': adminNotes,
      'contractorNotes': contractorNotes,
      'synced': 0, // 0 = not synced, 1 = synced
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: ComplaintType.values.firstWhere(
        (e) => e.toString() == 'ComplaintType.${map['type']}',
        orElse: () => ComplaintType.other,
      ),
      description: map['description'] ?? '',
      mediaUrls: map['mediaUrls'] != null
          ? (map['mediaUrls'] as String).split(',')
          : [],
      location: map['locationLat'] != null && map['locationLng'] != null
          ? {'lat': map['locationLat'], 'lng': map['locationLng']}
          : null,
      area: map['area'],
      landmark: map['landmark'],
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == 'ComplaintStatus.${map['status']}',
        orElse: () => ComplaintStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      assignedTo: map['assignedTo'],
      assignedBy: map['assignedBy'],
      assignedAt:
          map['assignedAt'] != null ? DateTime.parse(map['assignedAt']) : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      adminNotes: map['adminNotes'],
      contractorNotes: map['contractorNotes'],
    );
  }
}
