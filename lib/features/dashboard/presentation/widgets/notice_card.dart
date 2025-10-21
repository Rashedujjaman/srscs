import 'package:flutter/material.dart';
import '../../domain/entities/notice_item.dart';

class NoticeCard extends StatelessWidget {
  final NoticeItem notice;
  final VoidCallback? onTap;

  const NoticeCard({
    super.key,
    required this.notice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _getBackgroundColor(notice.type),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(notice.type),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(notice.type),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(notice.type),
                  color: _getIconColor(notice.type),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with urgency badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildUrgencyBadge(notice.urgency),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notice.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Affected areas (if any)
                    if (notice.affectedAreas != null &&
                        notice.affectedAreas!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: notice.affectedAreas!
                            .take(3)
                            .map((area) => Chip(
                                  label: Text(
                                    area,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(NoticeUrgency urgency) {
    if (urgency == NoticeUrgency.low) return const SizedBox.shrink();

    String text;
    Color color;

    switch (urgency) {
      case NoticeUrgency.critical:
        text = 'CRITICAL';
        color = Colors.red;
        break;
      case NoticeUrgency.high:
        text = 'URGENT';
        color = Colors.orange;
        break;
      case NoticeUrgency.medium:
        text = 'IMPORTANT';
        color = Colors.blue;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getIcon(NoticeType type) {
    switch (type) {
      case NoticeType.emergency:
        return Icons.emergency;
      case NoticeType.warning:
        return Icons.warning_amber_rounded;
      case NoticeType.maintenance:
        return Icons.engineering;
      case NoticeType.info:
        return Icons.info_outline;
    }
  }

  Color _getBackgroundColor(NoticeType type) {
    switch (type) {
      case NoticeType.emergency:
        return Colors.red[50]!;
      case NoticeType.warning:
        return Colors.orange[50]!;
      case NoticeType.maintenance:
        return Colors.blue[50]!;
      case NoticeType.info:
        return Colors.grey[100]!;
    }
  }

  Color _getBorderColor(NoticeType type) {
    switch (type) {
      case NoticeType.emergency:
        return Colors.red[200]!;
      case NoticeType.warning:
        return Colors.orange[200]!;
      case NoticeType.maintenance:
        return Colors.blue[200]!;
      case NoticeType.info:
        return Colors.grey[300]!;
    }
  }

  Color _getIconBackgroundColor(NoticeType type) {
    switch (type) {
      case NoticeType.emergency:
        return Colors.red[100]!;
      case NoticeType.warning:
        return Colors.orange[100]!;
      case NoticeType.maintenance:
        return Colors.blue[100]!;
      case NoticeType.info:
        return Colors.grey[200]!;
    }
  }

  Color _getIconColor(NoticeType type) {
    switch (type) {
      case NoticeType.emergency:
        return Colors.red[900]!;
      case NoticeType.warning:
        return Colors.orange[900]!;
      case NoticeType.maintenance:
        return Colors.blue[900]!;
      case NoticeType.info:
        return Colors.grey[700]!;
    }
  }
}
