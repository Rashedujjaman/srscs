enum ComplaintType {
  pothole,
  brokenSign,
  streetlight,
  drainage,
  roadCrack,
  accident,
  other
}

enum ComplaintStatus { pending, underReview, inProgress, resolved, rejected }

class ComplaintEntity {
  final String id;
  final String userId;
  final String userName;
  final ComplaintType type;
  final String description;
  final List<String> mediaUrls; // photo, video, audio URLs
  final Map<String, double>? location; // {lat, lng}
  final String? area; // Area/location name for assignment
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Assignment fields for contractor management
  final String? assignedTo; // Contractor ID
  final String? assignedBy; // Admin ID who assigned
  final DateTime? assignedAt; // When it was assigned
  final DateTime? completedAt; // When contractor completed it

  final String? adminNotes;
  final String? contractorNotes; // Notes from contractor

  ComplaintEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.description,
    this.mediaUrls = const [],
    this.location,
    this.area,
    this.status = ComplaintStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.assignedBy,
    this.assignedAt,
    this.completedAt,
    this.adminNotes,
    this.contractorNotes,
  });

  String get statusText {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.underReview:
        return 'Under Review';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  String get typeText {
    switch (type) {
      case ComplaintType.pothole:
        return 'Pothole';
      case ComplaintType.brokenSign:
        return 'Broken Sign';
      case ComplaintType.streetlight:
        return 'Streetlight';
      case ComplaintType.drainage:
        return 'Drainage';
      case ComplaintType.roadCrack:
        return 'Road Crack';
      case ComplaintType.accident:
        return 'Accident';
      case ComplaintType.other:
        return 'Other';
    }
  }
}
