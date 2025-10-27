import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../providers/admin_provider.dart';
import '../../../../core/routes/app_routes.dart';

/// Admin Complaints Screen
///
/// Shows all complaints in the system for admin management
class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ComplaintStatus? _filterStatus;
  ComplaintType? _filterType;
  String? _filterArea;
  String _sortBy = 'date'; // date, status, type

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminColor = UserRoleExtension(UserRole.admin).color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Complaints'),
        backgroundColor: adminColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(adminColor),
          _buildActiveFilters(),
          Expanded(child: _buildComplaintsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color adminColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by type, description, user...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final hasFilters =
        _filterStatus != null || _filterType != null || _filterArea != null;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Filters: ',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_filterStatus != null)
                    _buildFilterChip(
                      label: _getStatusText(_filterStatus!),
                      onRemove: () => setState(() => _filterStatus = null),
                    ),
                  if (_filterType != null)
                    _buildFilterChip(
                      label: _getTypeText(_filterType!),
                      onRemove: () => setState(() => _filterType = null),
                    ),
                  if (_filterArea != null)
                    _buildFilterChip(
                      label: _filterArea!,
                      onRemove: () => setState(() => _filterArea = null),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _filterType = null;
                _filterArea = null;
              });
            },
            child: const Text('Clear All', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.blue[900]),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: Colors.blue[900]),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    return StreamBuilder<List<ComplaintEntity>>(
      stream: Provider.of<AdminProvider>(context, listen: false)
          .streamAllComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading complaints',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<ComplaintEntity> complaints = snapshot.data ?? [];

        // Apply filters
        complaints = _applyFilters(complaints);

        // Apply search
        if (_searchController.text.isNotEmpty) {
          complaints = _applySearch(complaints);
        }

        // Apply sort
        complaints = _applySort(complaints);

        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isNotEmpty ||
                          _filterStatus != null ||
                          _filterType != null
                      ? 'No complaints match your criteria'
                      : 'No complaints yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild with stream
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return _buildComplaintCard(complaints[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildComplaintCard(ComplaintEntity complaint) {
    final statusColor = _getStatusColor(complaint.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
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
                      _getStatusText(complaint.status),
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
                      _getTypeText(complaint.type),
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

              // Description
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),

              // Info Row
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.userName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (complaint.area != null) ...[
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      complaint.area!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(complaint.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),

              // Assignment Info
              if (complaint.assignedTo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_ind,
                          size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ],

              // Media Indicator
              if (complaint.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.photo_library,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${complaint.mediaUrls.length} attachment(s)',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Complaints'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ComplaintStatus>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'All Statuses',
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Statuses')),
                      ...ComplaintStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusText(status)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _filterStatus = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ComplaintType>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'All Types',
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Types')),
                      ...ComplaintType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getTypeText(type)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _filterType = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Area',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _filterArea,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'All Areas',
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Areas')),
                      ...AvailableAreas.areas.map((area) {
                        return DropdownMenuItem(
                          value: area,
                          child: Text(area),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _filterArea = value);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _filterType = null;
                _filterArea = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Apply filters
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UserRoleExtension(UserRole.admin).color,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date (Newest First)'),
              value: 'date',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Status'),
              value: 'status',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Type'),
              value: 'type',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<ComplaintEntity> _applyFilters(List<ComplaintEntity> complaints) {
    return complaints.where((complaint) {
      if (_filterStatus != null && complaint.status != _filterStatus) {
        return false;
      }
      if (_filterType != null && complaint.type != _filterType) {
        return false;
      }
      if (_filterArea != null && complaint.area != _filterArea) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ComplaintEntity> _applySearch(List<ComplaintEntity> complaints) {
    final query = _searchController.text.toLowerCase();
    return complaints.where((complaint) {
      return complaint.type.toString().toLowerCase().contains(query) ||
          complaint.description.toLowerCase().contains(query) ||
          complaint.userName.toLowerCase().contains(query) ||
          (complaint.area?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<ComplaintEntity> _applySort(List<ComplaintEntity> complaints) {
    final sorted = List<ComplaintEntity>.from(complaints);

    switch (_sortBy) {
      case 'date':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'status':
        sorted.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case 'type':
        sorted.sort((a, b) => a.type.index.compareTo(b.type.index));
        break;
    }

    return sorted;
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
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
