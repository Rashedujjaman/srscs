import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:srscs/core/theme/app_theme_provider.dart';
import 'package:srscs/features/complaint/data/models/complaint_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/complaint_entity.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintEntity? complaint;

  const ComplaintDetailScreen({super.key, this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  ComplaintEntity? complaint;
  String? complaintId;

  @override
  void initState() {
    super.initState();
    complaint = widget.complaint;
    complaintId = complaint?.id ?? Get.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    if (complaintId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Complaint Details'),
          backgroundColor: theme.primaryColor,
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
              backgroundColor: theme.primaryColor,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Complaint Details'),
              backgroundColor: theme.primaryColor,
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
            backgroundColor: theme.primaryColor,
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.share),
            //     onPressed: () {
            //       // TODO: Implement share functionality
            //     },
            //   ),
            // ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                _buildStatusBanner(complaint.status),

                // Main Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Complaint Type & Date
                      _buildHeader(complaint),
                      const SizedBox(height: 20),

                      // Description
                      _buildSection(
                        title: 'Description',
                        child: Text(
                          complaint.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location Map
                      if (complaint.location != null) ...[
                        _buildSection(
                          title: 'Location',
                          child: _buildLocationMap(context, complaint),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Attached Media
                      if (complaint.mediaUrls.isNotEmpty) ...[
                        _buildSection(
                          title:
                              'Attached Media (${complaint.mediaUrls.length})',
                          child: _buildMediaGrid(complaint),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Admin Notes
                      // if (complaint.adminNotes != null &&
                      //     complaint.adminNotes!.isNotEmpty) ...[
                      //   _buildSection(
                      //     title: 'Admin Notes',
                      //     child: Container(
                      //       padding: const EdgeInsets.all(12),
                      //       decoration: BoxDecoration(
                      //         color: Colors.blue[50],
                      //         borderRadius: BorderRadius.circular(8),
                      //         border: Border.all(color: Colors.blue[200]!),
                      //       ),
                      //       child: Row(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           const Icon(Icons.info_outline,
                      //               color: Colors.blue, size: 20),
                      //           const SizedBox(width: 12),
                      //           Expanded(
                      //             child: Text(
                      //               complaint.adminNotes!,
                      //               style: const TextStyle(
                      //                 fontSize: 14,
                      //                 color: Colors.blue,
                      //                 height: 1.5,
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      //   const SizedBox(height: 20),
                      // ],

                      // Assigned To
                      // if (complaint.assignedTo != null &&
                      //     complaint.assignedTo!.isNotEmpty)
                      //   _buildInfoCard(
                      //     icon: Icons.person_outline,
                      //     title: 'Assigned To',
                      //     value: complaint.assignedTo!,
                      //   ),

                      // Timestamps
                      _buildInfoCard(
                        icon: Icons.access_time,
                        title: 'Created At',
                        value: DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(complaint.createdAt),
                      ),
                      if (complaint.updatedAt != null)
                        _buildInfoCard(
                          icon: Icons.update,
                          title: 'Last Updated',
                          value: DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(complaint.updatedAt!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(ComplaintStatus status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ComplaintStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
      case ComplaintStatus.underReview:
        statusColor = Colors.blue;
        statusIcon = Icons.rate_review;
        statusText = 'Under Review';
        break;
      case ComplaintStatus.inProgress:
        statusColor = Colors.purple;
        statusIcon = Icons.construction;
        statusText = 'In Progress';
        break;
      case ComplaintStatus.resolved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Resolved';
        break;
      case ComplaintStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border(
          bottom:
              BorderSide(color: statusColor.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Text(
            'Status: $statusText',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ComplaintEntity complaint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getTypeIcon(complaint.type),
              size: 32,
              color: const Color(0xFF9F7AEA),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                complaint.type.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              DateFormat('EEEE, MMM dd, yyyy').format(complaint.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getTypeIcon(ComplaintType type) {
    switch (type) {
      case ComplaintType.pothole:
        return Icons.warning;
      case ComplaintType.brokenSign:
        return Icons.broken_image;
      case ComplaintType.streetlight:
        return Icons.lightbulb_outline;
      case ComplaintType.drainage:
        return Icons.water_damage;
      case ComplaintType.roadCrack:
        return Icons.trending_down;
      case ComplaintType.accident:
        return Icons.car_crash;
      case ComplaintType.other:
        return Icons.report_problem;
    }
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9F7AEA),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildLocationMap(BuildContext context, ComplaintEntity complaint) {
    final lat = complaint.location!['lat']!;
    final lng = complaint.location!['lng']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactive Map with actual location
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
                          width: 50.0,
                          height: 50.0,
                          point: LatLng(lat, lng),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFE53E3E),
                            size: 50,
                            shadows: [
                              Shadow(
                                blurRadius: 3,
                                color: Colors.black26,
                              ),
                            ],
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
                    color: Colors.white.withValues(alpha: 0.7),
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
                    onPressed: () => _openInMaps(lat, lng),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F7AEA),
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
              onPressed: () => _copyCoordinates(context, lat, lng),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaGrid(ComplaintEntity complaint) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: complaint.mediaUrls.length,
      itemBuilder: (context, index) {
        final mediaUrl = complaint.mediaUrls[index];
        return _buildMediaThumbnail(mediaUrl, index);
      },
    );
  }

  Widget _buildMediaThumbnail(String mediaUrl, int index) {
    final isImage = _isImageUrl(mediaUrl);
    final isVideo = _isVideoUrl(mediaUrl);
    final isAudio = _isAudioUrl(mediaUrl);

    return GestureDetector(
      onTap: () => _openMedia(mediaUrl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isImage)
                CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                )
              else if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_outline,
                      size: 40, color: Colors.white),
                )
              else if (isAudio)
                const Center(
                  child: Icon(Icons.audiotrack, size: 40, color: Colors.grey),
                )
              else
                const Center(
                  child: Icon(Icons.insert_drive_file,
                      size: 40, color: Colors.grey),
                ),
              // Overlay for video/audio
              if (isVideo || isAudio)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Icon(
                      isVideo ? Icons.play_circle_outline : Icons.audiotrack,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Index badge
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9F7AEA), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isImageUrl(String url) {
    final ext = url.toLowerCase().split('.').last.split('?').first;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  bool _isVideoUrl(String url) {
    final ext = url.toLowerCase().split('.').last.split('?').first;
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  bool _isAudioUrl(String url) {
    final ext = url.toLowerCase().split('.').last.split('?').first;
    return ['mp3', 'wav', 'm4a', 'aac'].contains(ext);
  }

  Future<void> _openInMaps(double lat, double lng) async {
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
            print('Successfully launched: $urlString');
            break;
          }
        } catch (e) {
          print('Failed to launch $urlString: $e');
          continue;
        }
      }

      if (!launched) {
        print('Could not launch any map URL');
      }
    } catch (e) {
      print('Error opening maps: $e');
    }
  }

  Future<void> _copyCoordinates(
      BuildContext context, double lat, double lng) async {
    try {
      final coordinates =
          '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      await Clipboard.setData(ClipboardData(text: coordinates));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coordinates copied: $coordinates'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error copying coordinates: $e');
      if (context.mounted) {
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

  Future<void> _openMedia(String mediaUrl) async {
    try {
      final uri = Uri.parse(mediaUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening media: $e');
    }
  }
}
