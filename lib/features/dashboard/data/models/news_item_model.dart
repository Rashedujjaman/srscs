import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/news_item.dart';

class NewsItemModel extends NewsItem {
  NewsItemModel({
    required super.id,
    required super.title,
    required super.content,
    super.thumbnailUrl,
    required super.publishedAt,
    required super.source,
    super.externalLink,
    super.priority,
  });

  /// Create from Firestore document
  factory NewsItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NewsItemModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      source: data['source'] ?? 'Admin',
      externalLink: data['externalLink'],
      priority: data['priority'] ?? 3,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'source': source,
      'externalLink': externalLink,
      'priority': priority,
    };
  }

  /// Create from domain entity
  factory NewsItemModel.fromEntity(NewsItem entity) {
    return NewsItemModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      thumbnailUrl: entity.thumbnailUrl,
      publishedAt: entity.publishedAt,
      source: entity.source,
      externalLink: entity.externalLink,
      priority: entity.priority,
    );
  }
}
