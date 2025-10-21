import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notice_item.dart';

class NoticeItemModel extends NoticeItem {
  NoticeItemModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    required super.createdAt,
    super.expiresAt,
    super.isActive,
    super.affectedAreas,
  });

  /// Create from Firestore document
  factory NoticeItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NoticeItemModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNoticeType(data['type']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      affectedAreas: data['affectedAreas'] != null
          ? List<String>.from(data['affectedAreas'])
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'affectedAreas': affectedAreas,
    };
  }

  /// Create from domain entity
  factory NoticeItemModel.fromEntity(NoticeItem entity) {
    return NoticeItemModel(
      id: entity.id,
      title: entity.title,
      message: entity.message,
      type: entity.type,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      isActive: entity.isActive,
      affectedAreas: entity.affectedAreas,
    );
  }

  /// Parse notice type from string
  static NoticeType _parseNoticeType(String? typeString) {
    switch (typeString) {
      case 'emergency':
        return NoticeType.emergency;
      case 'warning':
        return NoticeType.warning;
      case 'maintenance':
        return NoticeType.maintenance;
      default:
        return NoticeType.info;
    }
  }
}
