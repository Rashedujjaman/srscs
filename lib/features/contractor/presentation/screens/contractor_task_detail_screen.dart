import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../core/constants/user_roles.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../../../complaint/data/models/complaint_model.dart';

/// Contractor Task Detail Screen
///
/// Shows detailed information about a specific assigned task
class ContractorTaskDetailScreen extends StatefulWidget {
  const ContractorTaskDetailScreen({super.key});

  @override
  State<ContractorTaskDetailScreen> createState() =>
      _ContractorTaskDetailScreenState();
}

class _ContractorTaskDetailScreenState
    extends State<ContractorTaskDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();
  final contractorColor = UserRoleExtension(UserRole.contractor).color;

  bool _isUploading = false;
  bool _isUpdating = false;

  String? _complaintId;

  @override
  void initState() {
    super.initState();
    // Get complaintId from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      _complaintId = args?['complaintId'];
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_complaintId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
          backgroundColor: contractorColor,
        ),
        body: const Center(child: Text('Invalid task')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('complaints').doc(_complaintId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Task Details'),
              backgroundColor: contractorColor,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Task Details'),
              backgroundColor: contractorColor,
            ),
            body: const Center(child: Text('Task not found')),
          );
        }

        final complaint = ComplaintModel.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            backgroundColor: contractorColor,
            actions: [
              if (complaint.status == ComplaintStatus.inProgress)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _showCompleteDialog(complaint),
                  tooltip: 'Mark as Complete',
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(complaint),
                _buildDetails(complaint),
                _buildMediaGallery(complaint),
                _buildLocation(complaint),
                _buildNotes(complaint),
                _buildActionButtons(complaint),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ComplaintEntity complaint) {
    final statusColor = _getStatusColor(complaint.status);
    final isUrgent = complaint.type == ComplaintType.accident ||
        complaint.type == ComplaintType.streetlight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [contractorColor, contractorColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  complaint.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(_getTypeIcon(complaint.type), size: 32, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  complaint.typeText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned ${_formatDate(complaint.assignedAt ?? complaint.createdAt)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(ComplaintEntity complaint) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: TextStyle(fontSize: 15, color: Colors.grey[800]),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.person,
            label: 'Reported by',
            value: complaint.userName,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.location_on,
            label: 'Location',
            value: complaint.area ?? 'Not specified',
          ),
          if (complaint.landmark != null) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.place,
              label: 'Landmark',
              value: complaint.landmark!,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.calendar_today,
            label: 'Reported on',
            value: DateFormat('MMM dd, yyyy - hh:mm a')
                .format(complaint.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: contractorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGallery(ComplaintEntity complaint) {
    if (complaint.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attached Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: complaint.mediaUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showImageFullScreen(complaint.mediaUrls[index]),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        complaint.mediaUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLocation(ComplaintEntity complaint) {
    if (complaint.location == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location on Map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${complaint.location!['lat']!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Lng: ${complaint.location!['lng']!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open in maps app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening in maps...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation, size: 16),
                    label: const Text('Open in Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: contractorColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNotes(ComplaintEntity complaint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (complaint.contractorNotes != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                complaint.contractorNotes!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Add notes about your work...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                onPressed: _isUpdating ? null : () => _saveNotes(complaint.id),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ComplaintEntity complaint) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (complaint.status == ComplaintStatus.underReview)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _startWork(complaint.id),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Work'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: contractorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (complaint.status == ComplaintStatus.inProgress) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    _isUpdating ? null : () => _showCompleteDialog(complaint),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _uploadProgressPhoto,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: const Text('Upload Progress Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: contractorColor,
                  side: BorderSide(color: contractorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startWork(String complaintId) async {
    setState(() => _isUpdating = true);

    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': ComplaintStatus.inProgress.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work started successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _saveNotes(String complaintId) async {
    if (_notesController.text.trim().isEmpty) return;

    setState(() => _isUpdating = true);

    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'contractorNotes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _notesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _uploadProgressPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final userId = FirebaseAuth.instance.currentUser!.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('contractor_progress')
          .child(userId)
          .child(fileName);

      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Add to mediaUrls array
      await _firestore.collection('complaints').doc(_complaintId).update({
        'mediaUrls': FieldValue.arrayUnion([downloadUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showCompleteDialog(ComplaintEntity complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Task'),
        content: const Text(
          'Are you sure you want to mark this task as complete? '
          'This will notify the admin for review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTask(complaint.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTask(String complaintId) async {
    setState(() => _isUpdating = true);

    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': ComplaintStatus.resolved.toString().split('.').last,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task marked as complete'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Get.back();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
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
