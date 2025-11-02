import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:srscs/core/constants/user_roles.dart';
import 'package:srscs/core/routes/app_routes.dart';
import 'package:srscs/core/routes/route_manager.dart';
import 'package:srscs/core/theme/app_theme_provider.dart';
import 'package:srscs/services/auth_service.dart';
import '../../domain/entities/complaint_entity.dart';
import '../providers/complaint_provider.dart';
import 'complaint_detail_screen.dart';

class ComplaintTrackingScreen extends StatefulWidget {
  const ComplaintTrackingScreen({super.key});

  @override
  State<ComplaintTrackingScreen> createState() =>
      _ComplaintTrackingScreenState();
}

class _ComplaintTrackingScreenState extends State<ComplaintTrackingScreen> {
  UserRole? userRole;
  @override
  void initState() {
    super.initState();
    // Schedule loading after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComplaints();
    });
  }

  Future<void> _loadComplaints() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      userRole = await AuthService().getUserRole(user.uid);
      if (userRole == UserRole.contractor) {
        await provider.loadContractorComplaints(user.uid);
        return;
      } else {
        await provider.loadCitizenComplaints(user.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintProvider>(context);
    final isLoading = provider.state == ComplaintState.loading;
    final theme = Provider.of<AppThemeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        backgroundColor: theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await provider.syncComplaints();
              await _loadComplaints();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No complaints yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadComplaints,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = provider.complaints[index];
                      return _buildComplaintCard(complaint);
                    },
                  ),
                ),
    );
  }

  Widget _buildComplaintCard(ComplaintEntity complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => ComplaintDetailScreen(complaint: complaint),
          //   ),
          // );
          if (userRole == UserRole.citizen) {
            RouteManager().navigateWithRoleCheck(
                context, AppRoutes.complaintDetail,
                arguments: {'complaintId': complaint.id});
          } else if (userRole == UserRole.contractor) {
            RouteManager().navigateWithRoleCheck(
                context, AppRoutes.contractorTaskDetail,
                arguments: {'complaintId': complaint.id});
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.type.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(complaint.status),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                complaint.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // Location (if available)
              if (complaint.location != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Lat: ${complaint.location!['lat']!.toStringAsFixed(4)}, Lng: ${complaint.location!['lng']!.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(complaint.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              // Media count
              if (complaint.mediaUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${complaint.mediaUrls.length} file(s) attached',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              // Admin notes (if any)
              if (complaint.adminNotes != null &&
                  complaint.adminNotes!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin Note: ${complaint.adminNotes}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ComplaintStatus status) {
    return Chip(
      avatar: Icon(status.icon, size: 16, color: Colors.white),
      label: Text(
        status.displayName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: status.color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
