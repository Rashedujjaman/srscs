import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dashboard_statistics.dart';

class DashboardStatisticsModel extends DashboardStatistics {
  DashboardStatisticsModel({
    required super.totalComplaints,
    required super.pendingComplaints,
    required super.underReviewComplaints,
    required super.inProgressComplaints,
    required super.resolvedComplaints,
    required super.rejectedComplaints,
    required super.averageResponseTime,
    required super.complaintsByCategory,
    required super.recentComplaintIds,
  });

  /// Create from Firestore document
  factory DashboardStatisticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DashboardStatisticsModel(
      totalComplaints: data['totalComplaints'] ?? 0,
      pendingComplaints: data['pendingComplaints'] ?? 0,
      underReviewComplaints: data['underReviewComplaints'] ?? 0,
      inProgressComplaints: data['inProgressComplaints'] ?? 0,
      resolvedComplaints: data['resolvedComplaints'] ?? 0,
      rejectedComplaints: data['rejectedComplaints'] ?? 0,
      averageResponseTime: (data['averageResponseTime'] ?? 0.0).toDouble(),
      complaintsByCategory:
          Map<String, int>.from(data['complaintsByCategory'] ?? {}),
      recentComplaintIds: List<String>.from(data['recentComplaintIds'] ?? []),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'totalComplaints': totalComplaints,
      'pendingComplaints': pendingComplaints,
      'underReviewComplaints': underReviewComplaints,
      'inProgressComplaints': inProgressComplaints,
      'resolvedComplaints': resolvedComplaints,
      'rejectedComplaints': rejectedComplaints,
      'averageResponseTime': averageResponseTime,
      'complaintsByCategory': complaintsByCategory,
      'recentComplaintIds': recentComplaintIds,
    };
  }

  /// Create from domain entity
  factory DashboardStatisticsModel.fromEntity(DashboardStatistics entity) {
    return DashboardStatisticsModel(
      totalComplaints: entity.totalComplaints,
      pendingComplaints: entity.pendingComplaints,
      underReviewComplaints: entity.underReviewComplaints,
      inProgressComplaints: entity.inProgressComplaints,
      resolvedComplaints: entity.resolvedComplaints,
      rejectedComplaints: entity.rejectedComplaints,
      averageResponseTime: entity.averageResponseTime,
      complaintsByCategory: entity.complaintsByCategory,
      recentComplaintIds: entity.recentComplaintIds,
    );
  }
}
