/// Dashboard statistics entity representing citizen's complaint metrics
class DashboardStatistics {
  final int totalComplaints;
  final int pendingComplaints;
  final int underReviewComplaints;
  final int inProgressComplaints;
  final int resolvedComplaints;
  final int rejectedComplaints;
  final double averageResponseTime; // in hours
  final Map<String, int> complaintsByCategory;
  final List<String> recentComplaintIds;

  DashboardStatistics({
    required this.totalComplaints,
    required this.pendingComplaints,
    required this.underReviewComplaints,
    required this.inProgressComplaints,
    required this.resolvedComplaints,
    required this.rejectedComplaints,
    required this.averageResponseTime,
    required this.complaintsByCategory,
    required this.recentComplaintIds,
  });

  /// Calculate percentage of resolved complaints
  double get resolutionRate {
    if (totalComplaints == 0) return 0.0;
    return (resolvedComplaints / totalComplaints) * 100;
  }

  /// Calculate percentage of active complaints (pending + under review + in progress)
  double get activeRate {
    if (totalComplaints == 0) return 0.0;
    final active =
        pendingComplaints + underReviewComplaints + inProgressComplaints;
    return (active / totalComplaints) * 100;
  }

  /// Get most frequent complaint category
  String get mostFrequentCategory {
    if (complaintsByCategory.isEmpty) return 'N/A';

    final sortedEntries = complaintsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.first.key;
  }
}
