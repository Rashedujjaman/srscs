import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/route_manager.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../../../complaint/data/models/complaint_model.dart';

/// Contractor Dashboard Screen
///
/// Main screen for contractors showing:
/// - Task statistics
/// - Assigned complaints
/// - Quick actions
class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});

  @override
  State<ContractorDashboardScreen> createState() =>
      _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState extends State<ContractorDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final contractorColor = UserRoleExtension(UserRole.contractor).color;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Dashboard'),
        backgroundColor: contractorColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => RouteManager().logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(userId),
              _buildStatistics(userId),
              _buildRecentTasks(userId),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(String userId) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [contractorColor, contractorColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('contractors').doc(userId).get(),
        builder: (context, snapshot) {
          final name = snapshot.data?.get('fullName') ?? 'Contractor';
          // final specialization =
          // snapshot.data?.get('specialization') ?? 'General';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Row(
              //   children: [
              //     Icon(Icons.work_outline,
              //         size: 16, color: Colors.white.withOpacity(0.9)),
              //     const SizedBox(width: 6),
              // Text(
              //   specialization,
              //   style: TextStyle(
              //     color: Colors.white.withOpacity(0.9),
              //     fontSize: 14,
              //   ),
              // ),
              //   ],
              // ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatistics(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('complaints')
          .where('assignedTo', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final complaints = snapshot.data!.docs
            .map((doc) => ComplaintModel.fromFirestore(doc))
            .toList();

        final pendingCount = complaints
            .where((c) => c.status == ComplaintStatus.underReview)
            .length;
        final inProgressCount = complaints
            .where((c) => c.status == ComplaintStatus.inProgress)
            .length;
        final completedCount = complaints
            .where((c) => c.status == ComplaintStatus.resolved)
            .length;
        final totalCount = complaints.length;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.assignment,
                      label: 'Total Tasks',
                      value: totalCount.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_actions,
                      label: 'Pending',
                      value: pendingCount.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.build,
                      label: 'In Progress',
                      value: inProgressCount.toString(),
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      label: 'Completed',
                      value: completedCount.toString(),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasks(String userId) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.contractorTasks);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('complaints')
                .where('assignedTo', isEqualTo: userId)
                .where('status', whereIn: ['underReview', 'inProgress'])
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No active tasks',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'New assignments will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final complaints = snapshot.data!.docs
                  .map((doc) => ComplaintModel.fromFirestore(doc))
                  .toList();

              return Column(
                children: complaints
                    .map((complaint) => _buildTaskCard(complaint))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(ComplaintEntity complaint) {
    final statusColor = _getStatusColor(complaint.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.contractorTaskDetail,
            arguments: {'complaintId': complaint.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      complaint.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      complaint.typeText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(_getTypeIcon(complaint.type),
                      size: 20, color: Colors.grey[600]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (complaint.area != null) ...[
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint.area!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(complaint.assignedAt ?? complaint.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final navItems = AppRoutes.getNavigationItems('contractor');

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
      selectedItemColor: contractorColor,
    );
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
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

  IconData _getTypeIcon(ComplaintType type) {
    switch (type) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
