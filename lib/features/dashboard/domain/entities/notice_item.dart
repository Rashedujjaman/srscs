/// Notice or alert entity for citizens
class NoticeItem {
  final String id;
  final String title;
  final String message;
  final NoticeType type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String>? affectedAreas; // Optional: specific locations

  NoticeItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.affectedAreas,
  });

  /// Check if notice is still valid
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Get urgency level based on type and expiry
  NoticeUrgency get urgency {
    if (!isValid) return NoticeUrgency.low;

    switch (type) {
      case NoticeType.emergency:
        return NoticeUrgency.critical;
      case NoticeType.warning:
        return NoticeUrgency.high;
      case NoticeType.info:
        return expiresAt != null &&
                DateTime.now().difference(expiresAt!).inHours.abs() < 24
            ? NoticeUrgency.medium
            : NoticeUrgency.low;
      case NoticeType.maintenance:
        return NoticeUrgency.medium;
    }
  }
}

enum NoticeType {
  emergency, // Critical alerts (e.g., road closure, accident)
  warning, // Important warnings (e.g., waterlogging alert)
  info, // General information
  maintenance // Scheduled maintenance notifications
}

enum NoticeUrgency { critical, high, medium, low }
