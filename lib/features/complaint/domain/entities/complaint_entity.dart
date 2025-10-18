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
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo;
  final String? adminNotes;

  ComplaintEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.description,
    this.mediaUrls = const [],
    this.location,
    this.status = ComplaintStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.adminNotes,
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
