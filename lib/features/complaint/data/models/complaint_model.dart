import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/complaint_entity.dart';

class ComplaintModel extends ComplaintEntity {
  ComplaintModel({
    required String id,
    required String userId,
    required String userName,
    required ComplaintType type,
    required String description,
    List<String> mediaUrls = const [],
    Map<String, double>? location,
    String? area,
    ComplaintStatus status = ComplaintStatus.pending,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? completedAt,
    String? adminNotes,
    String? contractorNotes,
  }) : super(
          id: id,
          userId: userId,
          userName: userName,
          type: type,
          description: description,
          mediaUrls: mediaUrls,
          location: location,
          area: area,
          status: status,
          createdAt: createdAt,
          updatedAt: updatedAt,
          assignedTo: assignedTo,
          assignedBy: assignedBy,
          assignedAt: assignedAt,
          completedAt: completedAt,
          adminNotes: adminNotes,
          contractorNotes: contractorNotes,
        );

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
      'type': type.toString().split('.').last,
      'description': description,
      'mediaUrls': mediaUrls,
      'location': location,
      'area': area,
      'status': status.toString().split('.').last,
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
      'type': type.toString().split('.').last,
      'description': description,
      'mediaUrls': mediaUrls.join(','),
      'locationLat': location?['lat'],
      'locationLng': location?['lng'],
      'area': area,
      'status': status.toString().split('.').last,
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
