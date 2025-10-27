import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../../../complaint/data/models/complaint_model.dart';

/// Contractor Completed Tasks Screen
///
/// Shows list of completed tasks by contractor
class ContractorCompletedTasksScreen extends StatefulWidget {
  const ContractorCompletedTasksScreen({super.key});

  @override
  State<ContractorCompletedTasksScreen> createState() =>
      _ContractorCompletedTasksScreenState();
}

class _ContractorCompletedTasksScreenState
    extends State<ContractorCompletedTasksScreen> {
  final _firestore = FirebaseFirestore.instance;
  final contractorColor = UserRoleExtension(UserRole.contractor).color;
  final _searchController = TextEditingController();

  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        backgroundColor: contractorColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_dateRange != null) _buildDateRangeChip(),
          Expanded(child: _buildCompletedTasksList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by type, location, or description...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildDateRangeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Filtered: ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Chip(
            label: Text(
              '${DateFormat('MMM d').format(_dateRange!.start)} - '
              '${DateFormat('MMM d, yyyy').format(_dateRange!.end)}',
            ),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() => _dateRange = null);
            },
            backgroundColor: contractorColor.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please login'));
    }

    Query query = _firestore
        .collection('complaints')
        .where('assignedTo', isEqualTo: userId)
        .where('status',
            isEqualTo: ComplaintStatus.resolved.toString().split('.').last)
        .orderBy('completedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No Completed Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed tasks will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Convert to complaints and apply filters
        List<ComplaintEntity> complaints = snapshot.data!.docs
            .map((doc) => ComplaintModel.fromFirestore(doc))
            .toList();

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          complaints = complaints.where((complaint) {
            final searchLower = _searchQuery.toLowerCase();
            return complaint.typeText.toLowerCase().contains(searchLower) ||
                complaint.description.toLowerCase().contains(searchLower) ||
                (complaint.area?.toLowerCase().contains(searchLower) ??
                    false) ||
                (complaint.landmark?.toLowerCase().contains(searchLower) ??
                    false);
          }).toList();
        }

        // Apply date range filter
        if (_dateRange != null) {
          complaints = complaints.where((complaint) {
            final completedDate = complaint.completedAt ??
                complaint.updatedAt ??
                complaint.createdAt;
            return completedDate.isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1))) &&
                completedDate
                    .isBefore(_dateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No Results Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildStatistics(complaints),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  return _buildCompletedTaskCard(complaints[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatistics(List<ComplaintEntity> complaints) {
    // Calculate statistics
    final totalTasks = complaints.length;

    // Group by type
    final Map<ComplaintType, int> typeCount = {};
    for (var complaint in complaints) {
      typeCount[complaint.type] = (typeCount[complaint.type] ?? 0) + 1;
    }

    // Find most common type
    ComplaintType? mostCommonType;
    int maxCount = 0;
    typeCount.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonType = type;
      }
    });

    // Calculate completion rate (tasks completed this month)
    final thisMonth = DateTime.now().month;
    final thisYear = DateTime.now().year;
    final thisMonthCount = complaints.where((c) {
      final completedDate = c.completedAt ?? c.updatedAt ?? c.createdAt;
      return completedDate.month == thisMonth && completedDate.year == thisYear;
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: contractorColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Total',
                  value: totalTasks.toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  label: 'This Month',
                  value: thisMonthCount.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: _getTypeIcon(mostCommonType ?? ComplaintType.other),
                  label: 'Most Common',
                  value: _getTypeText(mostCommonType ?? ComplaintType.other),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskCard(ComplaintEntity complaint) {
    final completedAt =
        complaint.completedAt ?? complaint.updatedAt ?? complaint.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTypeIcon(complaint.type),
                      size: 24,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.typeText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completed ${_formatDate(completedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (complaint.area != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint.area!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (complaint.contractorNotes != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complaint.contractorNotes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (complaint.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${complaint.mediaUrls.length} photo${complaint.mediaUrls.length > 1 ? 's' : ''} attached',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: contractorColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
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

  String _getTypeText(ComplaintType type) {
    switch (type) {
      case ComplaintType.pothole:
        return 'Pothole';
      case ComplaintType.brokenSign:
        return 'Broken Sign';
      case ComplaintType.streetlight:
        return 'Streetlight';
      case ComplaintType.drainage:
        return 'Drainage';
      case ComplaintType.roadCrack:
        return 'Road Crack';
      case ComplaintType.accident:
        return 'Accident';
      case ComplaintType.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
