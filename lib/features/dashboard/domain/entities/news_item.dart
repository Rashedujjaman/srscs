/// News or announcement entity from government/admin
class NewsItem {
  final String id;
  final String title;
  final String content;
  final String? thumbnailUrl;
  final DateTime publishedAt;
  final String source; // e.g., "RHD", "Ministry of Transport"
  final String? externalLink;
  final int priority; // 1-5, higher = more important

  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    this.thumbnailUrl,
    required this.publishedAt,
    required this.source,
    this.externalLink,
    this.priority = 3,
  });

  /// Check if news is recent (within last 7 days)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inDays <= 7;
  }

  /// Format published date as relative time
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
