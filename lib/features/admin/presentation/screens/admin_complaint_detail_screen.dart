import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../../../complaint/data/models/complaint_model.dart';
import '../../../../services/assignment_service.dart';
import '../../../../services/contractor_service.dart';
import '../../../contractor/data/models/contractor_model.dart';

/// Admin Complaint Detail Screen
///
/// Shows detailed information about a specific complaint for admin
class AdminComplaintDetailScreen extends StatefulWidget {
  const AdminComplaintDetailScreen({super.key});

  @override
  State<AdminComplaintDetailScreen> createState() =>
      _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState
    extends State<AdminComplaintDetailScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final ContractorService _contractorService = ContractorService();
  final TextEditingController _notesController = TextEditingController();

  String? complaintId;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    complaintId = Get.arguments as String?;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminColor = UserRoleExtension(UserRole.admin).color;

    if (complaintId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Complaint Details'),
          backgroundColor: adminColor,
        ),
        body: const Center(
          child: Text('Invalid complaint ID'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Complaint Details'),
              backgroundColor: adminColor,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Complaint Details'),
              backgroundColor: adminColor,
            ),
            body: const Center(
              child: Text('Complaint not found'),
            ),
          );
        }

        final complaint = ComplaintModel.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Complaint Details'),
            backgroundColor: adminColor,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'assign' && complaint.area != null) {
                    _showAssignDialog(complaint);
                  } else if (value == 'reject') {
                    _updateStatus(complaint.id, ComplaintStatus.rejected);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(complaint.id);
                  }
                },
                itemBuilder: (context) => [
                  if (complaint.assignedTo == null && complaint.area != null)
                    const PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.assignment_ind, size: 20),
                          SizedBox(width: 8),
                          Text('Assign to Contractor'),
                        ],
                      ),
                    ),
                  if (complaint.status != ComplaintStatus.rejected)
                    const PopupMenuItem(
                      value: 'reject',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Reject Complaint'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _isUpdating
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(complaint, adminColor),
                      _buildInfoSection(complaint),
                      if (complaint.mediaUrls.isNotEmpty)
                        _buildMediaSection(complaint),
                      if (complaint.location != null)
                        _buildLocationSection(complaint),
                      _buildStatusSection(complaint),
                      if (complaint.assignedTo != null)
                        _buildAssignmentSection(complaint),
                      _buildNotesSection(complaint),
                      _buildActionsSection(complaint),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(ComplaintEntity complaint, Color adminColor) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(complaint.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(complaint.status)),
                ),
                child: Text(
                  _getStatusText(complaint.status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(complaint.status),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(_getTypeIcon(complaint.type), size: 24, color: adminColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTypeText(complaint.type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ID: ${complaint.id}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ComplaintEntity complaint) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.person, 'Submitted by', complaint.userName),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            'Submitted on',
            DateFormat('MMM d, yyyy - hh:mm a').format(complaint.createdAt),
          ),
          if (complaint.area != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_city, 'Area', complaint.area!),
          ],
          if (complaint.landmark != null && complaint.landmark!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.place, 'Landmark', complaint.landmark!),
          ],
          if (complaint.updatedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.update,
              'Last updated',
              DateFormat('MMM d, yyyy - hh:mm a').format(complaint.updatedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection(ComplaintEntity complaint) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library, size: 20),
              const SizedBox(width: 8),
              Text(
                'Media (${complaint.mediaUrls.length})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: complaint.mediaUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _viewMedia(complaint.mediaUrls[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: complaint.mediaUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ComplaintEntity complaint) {
    final lat = complaint.location!['lat']!;
    final lng = complaint.location!['lng']!;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // FlutterMap widget showing actual location
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.srscs',
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Attribution text (required for OpenStreetMap)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 8, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Open in Maps button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(lat, lng),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyCoordinates(lat, lng),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ComplaintEntity complaint) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ComplaintStatus.values.map((status) {
              final isSelected = complaint.status == status;
              return ChoiceChip(
                label: Text(_getStatusText(status)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && !isSelected) {
                    _updateStatus(complaint.id, status);
                  }
                },
                selectedColor: _getStatusColor(status).withOpacity(0.3),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? _getStatusColor(status) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection(ComplaintEntity complaint) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('contractors')
          .doc(complaint.assignedTo)
          .get(),
      builder: (context, snapshot) {
        String contractorName = 'Loading...';
        if (snapshot.hasData && snapshot.data!.exists) {
          final contractor = ContractorModel.fromFirestore(snapshot.data!);
          contractorName = contractor.fullName;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assignment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_ind,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Assigned Contractor',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAssignDialog(complaint),
                          child: const Text('Reassign',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contractorName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (complaint.assignedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned on ${DateFormat('MMM d, yyyy').format(complaint.assignedAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              if (complaint.completedAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completed on ${DateFormat('MMM d, yyyy').format(complaint.completedAt!)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.green[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesSection(ComplaintEntity complaint) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (complaint.adminNotes != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Admin Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(complaint.adminNotes!,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (complaint.contractorNotes != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.construction,
                          size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Contractor Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(complaint.contractorNotes!,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add admin notes...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _addAdminNotes(complaint.id),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UserRoleExtension(UserRole.admin).color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ComplaintEntity complaint) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (complaint.assignedTo == null && complaint.area != null)
            ElevatedButton.icon(
              onPressed: () => _showAssignDialog(complaint),
              icon: const Icon(Icons.assignment_ind),
              label: const Text('Assign to Contractor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          if (complaint.status == ComplaintStatus.resolved)
            const SizedBox(height: 12),
          if (complaint.status == ComplaintStatus.resolved)
            OutlinedButton.icon(
              onPressed: () => _showDeleteConfirmation(complaint.id),
              icon: const Icon(Icons.archive, color: Colors.orange),
              label: const Text(
                'Archive Complaint',
                style: TextStyle(color: Colors.orange),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String complaintId, ComplaintStatus status) async {
    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_getStatusText(status)}'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _addAdminNotes(String complaintId) async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter notes')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'adminNotes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notes saved successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving notes: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _showAssignDialog(ComplaintEntity complaint) async {
    if (complaint.area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot assign: No area specified for this complaint'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Contractor'),
        content: StreamBuilder<List<ContractorModel>>(
          stream: _contractorService.getContractorsByArea(complaint.area!),
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
              return const Text(
                'No contractors available in this area',
                style: TextStyle(fontSize: 14),
              );
            }

            final contractors = snapshot.data!;

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: contractors.length,
                itemBuilder: (context, index) {
                  final contractor = contractors[index];
                  return ListTile(
                    style: ListTileStyle.drawer,
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, color: Colors.blue[700]),
                    ),
                    title: Text(contractor.fullName),
                    subtitle: Text(contractor.email),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _assignToContractor(complaint.id, contractor.id);
                    },
                  );
                },
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
    setState(() => _isUpdating = true);

    try {
      await _assignmentService.assignComplaint(
        complaintId: complaintId,
        contractorId: contractorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Complaint assigned successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning complaint: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _showDeleteConfirmation(String complaintId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint'),
        content: const Text(
          'Are you sure you want to delete this complaint? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteComplaint(complaintId);
    }
  }

  Future<void> _deleteComplaint(String complaintId) async {
    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Complaint deleted successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
        Get.back();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting complaint: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
      setState(() => _isUpdating = false);
    }
  }

  void _viewMedia(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Media'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    try {
      // Try multiple map URL schemes in order of preference
      final urls = [
        // Google Maps app (if installed)
        'google.navigation:q=$lat,$lng',
        // Geo URI (works on most Android devices)
        'geo:$lat,$lng?q=$lat,$lng',
        // Web fallback
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      ];

      bool launched = false;
      for (final urlString in urls) {
        try {
          final uri = Uri.parse(urlString);
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _copyCoordinates(double lat, double lng) async {
    try {
      final coordinates =
          '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      await Clipboard.setData(ClipboardData(text: coordinates));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coordinates copied: $coordinates'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy coordinates'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
}
