import 'package:flutter/material.dart';

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

extension ComplaintTypeExtension on ComplaintType {
  String get displayName {
    switch (this) {
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

  String get value {
    switch (this) {
      case ComplaintType.pothole:
        return 'pothole';
      case ComplaintType.brokenSign:
        return 'brokenSign';
      case ComplaintType.streetlight:
        return 'streetlight';
      case ComplaintType.drainage:
        return 'drainage';
      case ComplaintType.roadCrack:
        return 'roadCrack';
      case ComplaintType.accident:
        return 'accident';
      case ComplaintType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintType.pothole:
        return Icons.warning;
      case ComplaintType.brokenSign:
        return Icons.broken_image;
      case ComplaintType.streetlight:
        return Icons.lightbulb;
      case ComplaintType.drainage:
        return Icons.water_damage;
      case ComplaintType.roadCrack:
        return Icons.call_split;
      case ComplaintType.accident:
        return Icons.car_crash;
      case ComplaintType.other:
        return Icons.more_horiz;
    }
  }
}

extension ComplaintStatusExtension on ComplaintStatus {
  String get value {
    switch (this) {
      case ComplaintStatus.pending:
        return 'pending';
      case ComplaintStatus.underReview:
        return 'underReview';
      case ComplaintStatus.inProgress:
        return 'inProgress';
      case ComplaintStatus.resolved:
        return 'resolved';
      case ComplaintStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
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

  Color get color {
    switch (this) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.underReview:
        return Colors.blue;
      case ComplaintStatus.inProgress:
        return Colors.purple;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.pending:
        return Icons.pending;
      case ComplaintStatus.underReview:
        return Icons.rate_review;
      case ComplaintStatus.inProgress:
        return Icons.construction;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }
}

class ComplaintEntity {
  final String id;
  final String userId;
  final String userName;
  final ComplaintType type;
  final String description;
  final List<String> mediaUrls;
  final Map<String, double>? location; // {lat, lng}
  final String? area; // Area/location name for assignment
  final String? landmark; // Nearby landmark for easier identification
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
    this.landmark,
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

  // String get statusText {
  //   switch (status) {
  //     case ComplaintStatus.pending:
  //       return 'Pending';
  //     case ComplaintStatus.underReview:
  //       return 'Under Review';
  //     case ComplaintStatus.inProgress:
  //       return 'In Progress';
  //     case ComplaintStatus.resolved:
  //       return 'Resolved';
  //     case ComplaintStatus.rejected:
  //       return 'Rejected';
  //   }
  // }

  // String get typeText {
  //   switch (type) {
  //     case ComplaintType.pothole:
  //       return 'Pothole';
  //     case ComplaintType.brokenSign:
  //       return 'Broken Sign';
  //     case ComplaintType.streetlight:
  //       return 'Streetlight';
  //     case ComplaintType.drainage:
  //       return 'Drainage';
  //     case ComplaintType.roadCrack:
  //       return 'Road Crack';
  //     case ComplaintType.accident:
  //       return 'Accident';
  //     case ComplaintType.other:
  //       return 'Other';
  //   }
  // }
}
