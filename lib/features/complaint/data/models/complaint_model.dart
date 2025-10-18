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
    ComplaintStatus status = ComplaintStatus.pending,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    String? adminNotes,
  }) : super(
          id: id,
          userId: userId,
          userName: userName,
          type: type,
          description: description,
          mediaUrls: mediaUrls,
          location: location,
          status: status,
          createdAt: createdAt,
          updatedAt: updatedAt,
          assignedTo: assignedTo,
          adminNotes: adminNotes,
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
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == 'ComplaintStatus.${data['status']}',
        orElse: () => ComplaintStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      assignedTo: data['assignedTo'],
      adminNotes: data['adminNotes'],
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
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'assignedTo': assignedTo,
      'adminNotes': adminNotes,
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
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'adminNotes': adminNotes,
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
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == 'ComplaintStatus.${map['status']}',
        orElse: () => ComplaintStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      assignedTo: map['assignedTo'],
      adminNotes: map['adminNotes'],
    );
  }
}
