import '../repositories/dashboard_repository.dart';

/// Use case for marking a notice as read
class MarkNoticeAsRead {
  final DashboardRepository repository;

  MarkNoticeAsRead(this.repository);

  /// Mark a notice as read for a specific user
  ///
  /// [userId] - The ID of the user marking the notice as read
  /// [noticeId] - The ID of the notice to mark as read
  Future<void> call(String userId, String noticeId) async {
    return await repository.markNoticeAsRead(userId, noticeId);
  }
}
