import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../../../complaint/data/models/complaint_model.dart';
import '../../../contractor/data/models/contractor_model.dart';
import '../../../../services/assignment_service.dart';
import '../../../../services/contractor_service.dart';
import '../../../../core/routes/app_routes.dart';

/// Admin Assignment Screen
///
/// Interface for assigning complaints to contractors
class AdminAssignmentScreen extends StatefulWidget {
  const AdminAssignmentScreen({super.key});

  @override
  State<AdminAssignmentScreen> createState() => _AdminAssignmentScreenState();
}

class _AdminAssignmentScreenState extends State<AdminAssignmentScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final ContractorService _contractorService = ContractorService();

  String? _selectedArea;
  bool _showOnlyUnassigned = true;

  // Keys for refreshing
  int _complaintsRefreshKey = 0;
  int _contractorsRefreshKey = 0;
  @override
  void initState() {
    super.initState();
    // Load data when area changes
  }

  @override
  Widget build(BuildContext context) {
    final adminColor = UserRoleExtension(UserRole.admin).color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Complaints'),
        backgroundColor: adminColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showOnlyUnassigned
                ? Icons.filter_list
                : Icons.filter_list_off),
            onPressed: () {
              setState(() {
                _showOnlyUnassigned = !_showOnlyUnassigned;
              });
            },
            tooltip: _showOnlyUnassigned ? 'Show All' : 'Show Unassigned Only',
          ),
          if (_selectedArea != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildAreaSelector(adminColor),
          if (_selectedArea != null)
            Expanded(
              child: Column(
                children: [
                  // Left panel - Complaints
                  Expanded(
                    flex: 3,
                    child: _buildComplaintsPanel(),
                  ),
                  VerticalDivider(width: 1, color: Colors.grey[300]),
                  // Right panel - Contractors
                  Expanded(
                    flex: 2,
                    child: _buildContractorsPanel(),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.place, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Select an area to view complaints',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _refreshData() {
    setState(() {
      _complaintsRefreshKey++;
      _contractorsRefreshKey++;
    });
  }

  Widget _buildAreaSelector(Color adminColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city, color: adminColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Select Area',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedArea,
            decoration: InputDecoration(
              hintText: 'Choose area to manage assignments',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            isExpanded: true,
            items: AvailableAreas.areas.map((area) {
              return DropdownMenuItem(
                value: area,
                child: Text(area),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedArea = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Complaints',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_showOnlyUnassigned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Text(
                    'Unassigned',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildComplaintsList(),
        ),
      ],
    );
  }

  Widget _buildComplaintsList() {
    return FutureBuilder<List<ComplaintModel>>(
      key: ValueKey('complaints_$_complaintsRefreshKey'),
      future: _loadComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading complaints...', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  const Text(
                    'Error loading complaints',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  _showOnlyUnassigned
                      ? 'No unassigned complaints in this area'
                      : 'No complaints in this area',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return _buildComplaintCard(complaints[index]);
            },
          ),
        );
      },
    );
  }

  Future<List<ComplaintModel>> _loadComplaints() async {
    try {
      if (_selectedArea == null) {
        return [];
      }

      // Simple query without complex indexing
      final query = await FirebaseFirestore.instance
          .collection('complaints')
          .where('area', isEqualTo: _selectedArea)
          .orderBy('createdAt', descending: true)
          .limit(100) // Limit for performance
          .get();

      var complaints = query.docs
          .map((doc) {
            try {
              return ComplaintModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing complaint: $e');
              return null;
            }
          })
          .whereType<ComplaintModel>()
          .toList();

      // Client-side filtering for unassigned
      if (_showOnlyUnassigned) {
        complaints = complaints.where((c) => c.assignedTo == null).toList();
      }

      return complaints;
    } catch (e) {
      debugPrint('Error loading complaints: $e');
      rethrow;
    }
  }

  Widget _buildComplaintCard(ComplaintEntity complaint) {
    final statusColor = _getStatusColor(complaint.status);
    final isAssigned = complaint.assignedTo != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isAssigned ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAssigned ? Colors.grey[300]! : statusColor.withOpacity(0.3),
          width: isAssigned ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.adminComplaintDetail,
            arguments: complaint.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusText(complaint.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getTypeText(complaint.type),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(_getTypeIcon(complaint.type),
                      size: 16, color: Colors.grey[600]),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.userName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(complaint.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
              if (isAssigned) ...[
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('contractors')
                      .doc(complaint.assignedTo)
                      .get(),
                  builder: (context, snapshot) {
                    String contractorName = 'Loading...';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final contractor =
                          ContractorModel.fromFirestore(snapshot.data!);
                      contractorName = contractor.fullName;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.assignment_ind,
                              size: 12, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Assigned to: $contractorName',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAssignDialog(complaint),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Reassign',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAssignDialog(complaint),
                    icon: const Icon(Icons.assignment_ind, size: 16),
                    label: const Text('Assign', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: Colors.blue[600]!),
                      foregroundColor: Colors.blue[600],
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

  Widget _buildContractorsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.people, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Available Contractors',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildContractorsList(),
        ),
      ],
    );
  }

  Widget _buildContractorsList() {
    if (_selectedArea == null) {
      return const Center(
        child: Text('Select an area first'),
      );
    }

    return FutureBuilder<List<ContractorModel>>(
      key: ValueKey('contractors_$_contractorsRefreshKey'),
      future: _loadContractors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading contractors...', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  const Text(
                    'Error loading contractors',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final contractors = snapshot.data ?? [];

        if (contractors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No contractors in this area',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: contractors.length,
            itemBuilder: (context, index) {
              return _buildContractorCard(contractors[index]);
            },
          ),
        );
      },
    );
  }

  Future<List<ContractorModel>> _loadContractors() async {
    try {
      if (_selectedArea == null) {
        return [];
      }

      // Load contractors from Firestore
      final query = await FirebaseFirestore.instance
          .collection('contractors')
          .where('assignedArea', isEqualTo: _selectedArea)
          .get();

      final contractors = query.docs
          .map((doc) {
            try {
              return ContractorModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing contractor: $e');
              return null;
            }
          })
          .whereType<ContractorModel>()
          .toList();

      return contractors;
    } catch (e) {
      debugPrint('Error loading contractors: $e');
      rethrow;
    }
  }

  Widget _buildContractorCard(ContractorModel contractor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  radius: 20,
                  child: Icon(Icons.person, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contractor.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        contractor.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: contractor.isActive
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contractor.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: contractor.isActive
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_city, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  contractor.assignedArea ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const Spacer(),
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  contractor.phoneNumber,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: _getContractorActiveTasksCount(contractor.id),
              builder: (context, snapshot) {
                final activeTasksCount = snapshot.data ?? 0;

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment,
                              size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            snapshot.connectionState == ConnectionState.waiting
                                ? 'Active Tasks: ...'
                                : 'Active Tasks: $activeTasksCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Workload: ${_getWorkloadLevel(activeTasksCount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getWorkloadColor(activeTasksCount),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignDialog(ComplaintEntity complaint) async {
    if (_selectedArea == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          complaint.assignedTo != null
              ? 'Reassign Complaint'
              : 'Assign Complaint',
        ),
        content: StreamBuilder<List<ContractorModel>>(
          stream: _contractorService.getContractorsByArea(_selectedArea!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No contractors available in this area',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              );
            }

            final contractors = snapshot.data!;

            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a contractor:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: contractors.length,
                      itemBuilder: (context, index) {
                        final contractor = contractors[index];
                        final isCurrentlyAssigned =
                            complaint.assignedTo == contractor.id;

                        return FutureBuilder<int>(
                          future: _getContractorActiveTasksCount(contractor.id),
                          builder: (context, taskSnapshot) {
                            final activeTasksCount = taskSnapshot.data ?? 0;

                            return Card(
                              color: isCurrentlyAssigned
                                  ? Colors.blue[50]
                                  : Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.person,
                                      color: Colors.blue[700]),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        contractor.fullName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentlyAssigned)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[200],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Current',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue[900],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contractor.email,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Active Tasks: $activeTasksCount · ${_getWorkloadLevel(activeTasksCount)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            _getWorkloadColor(activeTasksCount),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: contractor.isActive
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                                enabled: contractor.isActive,
                                onTap: contractor.isActive
                                    ? () {
                                        Navigator.pop(context);
                                        _assignToContractor(
                                            complaint.id, contractor.id);
                                      }
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignToContractor(
      String complaintId, String contractorId) async {
    try {
      await _assignmentService.assignComplaint(
        complaintId: complaintId,
        contractorId: contractorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Complaint assigned successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<int> _getContractorActiveTasksCount(String contractorId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('complaints')
          .where('assignedTo', isEqualTo: contractorId)
          .where('status', whereIn: ['inProgress', 'underReview']).get();

      return query.docs.length;
    } catch (e) {
      debugPrint('Error getting contractor tasks: $e');
      return 0;
    }
  }

  String _getWorkloadLevel(int activeTasksCount) {
    if (activeTasksCount == 0) return 'Available';
    if (activeTasksCount <= 3) return 'Light';
    if (activeTasksCount <= 6) return 'Medium';
    return 'Heavy';
  }

  Color _getWorkloadColor(int activeTasksCount) {
    if (activeTasksCount == 0) return Colors.green[700]!;
    if (activeTasksCount <= 3) return Colors.blue[700]!;
    if (activeTasksCount <= 6) return Colors.orange[700]!;
    return Colors.red[700]!;
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

  String _getStatusText(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.underReview:
        return 'Under Review';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
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
      return DateFormat('MMM d').format(date);
    }
  }
}
