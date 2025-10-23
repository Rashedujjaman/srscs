import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:srscs/core/routes/app_routes.dart';
import 'package:srscs/core/routes/route_manager.dart';
import '../providers/dashboard_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/statistics_card.dart';
import '../widgets/news_card.dart';
import '../widgets/notice_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load all dashboard data after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider =
          Provider.of<DashboardProvider>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      dashboardProvider.loadDashboardData();
      profileProvider.loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FF),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          final dashboardProvider =
              Provider.of<DashboardProvider>(context, listen: false);
          await dashboardProvider.refreshDashboard();
        },
        child: Consumer2<DashboardProvider, ProfileProvider>(
          builder: (context, dashboardProvider, profileProvider, child) {
            // Loading state
            if (dashboardProvider.isLoading &&
                dashboardProvider.statistics == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (dashboardProvider.error != null &&
                dashboardProvider.statistics == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      dashboardProvider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => dashboardProvider.loadDashboardData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final profile = profileProvider.profile;
            final statistics = dashboardProvider.statistics;
            final newsList = dashboardProvider.newsList;
            final noticesList = dashboardProvider.noticesList;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
                    profile != null
                        ? "Hello, ${profile.fullName.split(' ').last}!"
                        : "Hello, Citizen!",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Welcome to Smart Road Safety Complaint System',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Statistics Card
                  if (statistics != null)
                    StatisticsCard(statistics: statistics)
                  else
                    _buildLoadingCard(),

                  const SizedBox(height: 24),

                  // Urgent Notices Section
                  if (dashboardProvider.urgentNotices.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '⚠️ Urgent Notices',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        if (dashboardProvider.unreadNoticeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${dashboardProvider.unreadNoticeCount} new',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...dashboardProvider.urgentNotices.map(
                      (notice) => NoticeCard(
                        notice: notice,
                        onTap: () => _showNoticeDetails(context, notice),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // News Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Latest News',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (newsList.isNotEmpty)
                        TextButton(
                          onPressed: () => _showAllNews(context, newsList),
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (dashboardProvider.isLoadingNews)
                    const Center(child: CircularProgressIndicator())
                  else if (newsList.isEmpty)
                    _buildEmptyState(
                        'No news available', Icons.article_outlined)
                  else
                    ...newsList.take(3).map(
                          (news) => NewsCard(
                            news: news,
                            onTap: () => _showNewsDetails(context, news),
                          ),
                        ),

                  const SizedBox(height: 24),

                  // All Notices Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Notices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (noticesList.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              _showAllNotices(context, noticesList),
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (dashboardProvider.isLoadingNotices)
                    const Center(child: CircularProgressIndicator())
                  else if (noticesList.isEmpty)
                    _buildEmptyState(
                        'No notices available', Icons.notifications_none)
                  else
                    ...noticesList.take(3).map(
                          (notice) => NoticeCard(
                            notice: notice,
                            onTap: () => _showNoticeDetails(context, notice),
                          ),
                        ),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/submit-complaint'),
        tooltip: 'Submit Complaint',
        backgroundColor: const Color(0xFF9F7AEA),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Build AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      title: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/profile'),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFE5D4FF),
                  radius: 24,
                  backgroundImage: profileProvider.profile?.profilePhotoUrl !=
                          null
                      ? NetworkImage(profileProvider.profile!.profilePhotoUrl!)
                      : null,
                  child: profileProvider.profile?.profilePhotoUrl == null
                      ? const Icon(Icons.person, color: Colors.black)
                      : null,
                ),
              ),
              const Text(
                'SRSCS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Consumer<DashboardProvider>(
                builder: (context, dashboardProvider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          _showAllNotices(
                              context, dashboardProvider.noticesList);
                        },
                      ),
                      if (dashboardProvider.unreadNoticeCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${dashboardProvider.unreadNoticeCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Build Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    final navItems = AppRoutes.getNavigationItems('citizen');

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color(0xFF9F7AEA),
      onTap: (index) {
        RouteManager().navigateWithRoleCheck(
          context,
          navItems[index].route,
        );
      },
      items: navItems
          .map((item) => BottomNavigationBarItem(
                icon: item.icon,
                label: item.label,
              ))
          .toList(),
    );
  }

  // Build loading card
  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 150,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Show news details
  void _showNewsDetails(BuildContext context, news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                news.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Meta info
              Row(
                children: [
                  Icon(Icons.account_balance,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    news.source,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    news.timeAgo,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Content
              Text(
                news.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              if (news.externalLink != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open external link
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Read More'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F7AEA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Show notice details
  void _showNoticeDetails(BuildContext context, notice) {
    // Mark notice as read
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.markNoticeAsRead(notice.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNoticeIcon(notice.type),
              color: _getNoticeColor(notice.type),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notice.message,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (notice.affectedAreas != null &&
                  notice.affectedAreas!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Affected Areas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: notice.affectedAreas!
                      .map<Widget>((area) => Chip(
                            label: Text(area),
                            backgroundColor: Colors.grey[200],
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show all news
  void _showAllNews(BuildContext context, List newsList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('All News'),
            backgroundColor: const Color(0xFF9F7AEA),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return NewsCard(
                news: news,
                onTap: () => _showNewsDetails(context, news),
              );
            },
          ),
        ),
      ),
    );
  }

  // Show all notices
  void _showAllNotices(BuildContext context, List noticesList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('All Notices'),
            backgroundColor: const Color(0xFF9F7AEA),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: noticesList.length,
            itemBuilder: (context, index) {
              final notice = noticesList[index];
              return NoticeCard(
                notice: notice,
                onTap: () => _showNoticeDetails(context, notice),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper methods for notice icons and colors
  IconData _getNoticeIcon(type) {
    switch (type.toString()) {
      case 'NoticeType.emergency':
        return Icons.emergency;
      case 'NoticeType.warning':
        return Icons.warning_amber_rounded;
      case 'NoticeType.maintenance':
        return Icons.engineering;
      default:
        return Icons.info_outline;
    }
  }

  Color _getNoticeColor(type) {
    switch (type.toString()) {
      case 'NoticeType.emergency':
        return Colors.red;
      case 'NoticeType.warning':
        return Colors.orange;
      case 'NoticeType.maintenance':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
