import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:srscs/features/complaint/domain/entities/complaint_entity.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/route_manager.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load statistics when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: UserRoleExtension(UserRole.admin).color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminProvider>().loadStatistics();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => RouteManager().logout(context),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.statistics == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.statistics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadStatistics(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadStatistics(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),

                  // Complaint Statistics
                  _buildSectionTitle('Complaint Overview'),
                  const SizedBox(height: 12),
                  _buildComplaintStats(provider),
                  const SizedBox(height: 24),

                  // System Statistics
                  _buildSectionTitle('System Statistics'),
                  const SizedBox(height: 12),
                  _buildSystemStats(provider),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Recent Activity
                  _buildSectionTitle('Recent Complaints'),
                  const SizedBox(height: 12),
                  _buildRecentComplaints(provider),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              UserRoleExtension(UserRole.admin).color,
              UserRoleExtension(UserRole.admin).color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  size: 35, color: Color(0xFFF56565)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'System Management Dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildComplaintStats(AdminProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                provider.totalComplaints.toString(),
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                provider.pendingComplaints.toString(),
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'In Progress',
                provider.inProgressComplaints.toString(),
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolved',
                provider.resolvedComplaints.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Under Review',
                provider.underReviewComplaints.toString(),
                Icons.search,
                Colors.blue[700]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rejected',
                provider.rejectedComplaints.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemStats(AdminProvider provider) {
    return Column(
      children: [
        _buildInfoTile(
          'Total Citizens',
          provider.totalCitizens.toString(),
          Icons.people,
          Colors.indigo,
        ),
        const SizedBox(height: 8),
        _buildInfoTile(
          'Total Contractors',
          '${provider.activeContractors} / ${provider.totalContractors}',
          Icons.engineering,
          Colors.teal,
          subtitle: 'Active / Total',
        ),
        const SizedBox(height: 8),
        _buildInfoTile(
          'Assigned Complaints',
          provider.assignedComplaints.toString(),
          Icons.assignment_ind,
          Colors.deepPurple,
        ),
        const SizedBox(height: 8),
        _buildInfoTile(
          'Unassigned Complaints',
          provider.unassignedComplaints.toString(),
          Icons.assignment_late,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _buildActionCard(
          'View All Complaints',
          Icons.list_alt,
          Colors.blue,
          () => Get.toNamed(AppRoutes.adminComplaints),
        ),
        _buildActionCard(
          'Assign Complaints',
          Icons.assignment_ind,
          Colors.purple,
          () => Get.toNamed(AppRoutes.adminAssignment),
        ),
        _buildActionCard(
          'Manage Contractors',
          Icons.engineering,
          Colors.teal,
          () => Get.toNamed(AppRoutes.adminContractors),
        ),
        _buildActionCard(
          'Chat Management',
          Icons.chat,
          Colors.orange,
          () => Get.toNamed(AppRoutes.adminChatManagement),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentComplaints(AdminProvider provider) {
    return StreamBuilder<List<ComplaintEntity>>(
      stream: provider.streamAllComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No complaints yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final recentComplaints = snapshot.data!.take(5).toList();

        return Column(
          children: recentComplaints.map((complaint) {
            return _buildComplaintCard(complaint);
          }).toList(),
        );
      },
    );
  }

  Widget _buildComplaintCard(ComplaintEntity complaint) {
    final status = complaint.status;
    final color = _getStatusColor(status.toString().split('.').last);
    final createdAt = complaint.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            _getStatusIcon(status.toString().split('.').last),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          complaint.type.toString().split('.').last,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              complaint.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  complaint.userName,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(createdAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            )
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(status.toString().split('.').last),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Get.toNamed(AppRoutes.adminComplaintDetail, arguments: complaint);
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'underReview':
        return Colors.blue;
      case 'inProgress':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'underReview':
        return Icons.search;
      case 'inProgress':
        return Icons.trending_up;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'underReview':
        return 'Under Review';
      case 'inProgress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Widget _buildBottomNav() {
    final navItems = AppRoutes.getNavigationItems('admin');

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      items: navItems
          .map((item) => BottomNavigationBarItem(
                icon: item.icon,
                label: item.label,
              ))
          .toList(),
      onTap: (index) {
        RouteManager().navigateWithRoleCheck(
          context,
          navItems[index].route,
        );
      },
      selectedItemColor: UserRoleExtension(UserRole.admin).color,
    );
  }
}
