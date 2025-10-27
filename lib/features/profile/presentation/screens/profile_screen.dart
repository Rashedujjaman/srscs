import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:srscs/core/constants/user_roles.dart';
import 'package:srscs/core/routes/app_routes.dart';
import 'package:srscs/core/theme/app_theme_provider.dart';
import 'package:srscs/features/complaint/data/models/complaint_model.dart';
import 'package:srscs/features/complaint/domain/entities/complaint_entity.dart';
import 'package:srscs/services/auth_service.dart';
import '../../../../services/notification_service.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ComplaintEntity> _recentComplaints = [];

  @override
  void initState() {
    super.initState();
    // Schedule loading after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      profileProvider.loadProfile();
      _loadComplaints();
    });
  }

  Future<void> _loadComplaints() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRole = await AuthService().getUserRole(uid);
        final Query query;
        if (userRole == UserRole.citizen) {
          query = _firestore
              .collection('complaints')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(5);
        } else if (userRole == UserRole.contractor) {
          query = _firestore
              .collection('complaints')
              .where('assignedTo', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(5);
        } else {
          query = _firestore
              .collection('complaints')
              .orderBy('createdAt', descending: true)
              .limit(5);
        }

        final querySnapshot = await query.get();

        if (mounted) {
          setState(() {
            _recentComplaints = querySnapshot.docs
                .map((doc) => ComplaintModel.fromFirestore(doc))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading complaints: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileProvider.profile;
          if (profile == null) {
            return const Center(
              child: Text('Unable to load profile'),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, profile, profileProvider),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStatsCards(),
                    const SizedBox(height: 20),
                    _buildPersonalInfo(profile),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildRecentComplaints(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ProfileEntity profile, ProfileProvider provider) {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: theme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: profile.profilePhotoUrl != null
                              ? CachedNetworkImageProvider(
                                  profile.profilePhotoUrl!)
                              : null,
                          child: profile.profilePhotoUrl == null ||
                                  profile.profilePhotoUrl!.isEmpty
                              ? Icon(Icons.person,
                                  size: 60, color: theme.primaryColor)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _updateProfilePhoto(provider),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt,
                                color: theme.primaryColor, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(profile: profile),
              ),
            );
            if (result == true) {
              provider.loadProfile();
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Complaints',
              _recentComplaints.length.toString(),
              Icons.report_problem,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Resolved',
              _recentComplaints
                  .where((c) => c.status == ComplaintStatus.resolved)
                  .length
                  .toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              _recentComplaints
                  .where((c) => c.status == ComplaintStatus.pending)
                  .length
                  .toString(),
              Icons.schedule,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(ProfileEntity profile) {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (profile.nid != '')
            _buildInfoTile(Icons.badge, 'NID Number', profile.nid),
          if (profile.phoneNumber != '')
            _buildInfoTile(Icons.phone, 'Phone', profile.phoneNumber),
          if (profile.address != '')
            _buildInfoTile(Icons.location_on, 'Address', profile.address),
          if (profile.dob != '')
            _buildInfoTile(Icons.cake, 'Date of Birth', profile.dob),
          if (profile.bloodGroup != null)
            _buildInfoTile(Icons.bloodtype, 'Blood Group', profile.bloodGroup),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: theme.primaryColor),
          ),
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
                const SizedBox(height: 2),
                Text(
                  value ?? 'Not specified',
                  style: const TextStyle(
                    fontSize: 15,
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

  Widget _buildQuickActions() {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Chat with Admin',
            color: Colors.blue,
            onTap: () {
              Get.toNamed(AppRoutes.citizenChat);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.history,
            label: 'View All Complaints',
            color: Colors.orange,
            onTap: () {
              Get.toNamed(AppRoutes.trackComplaints);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout,
            label: 'Logout',
            color: Colors.red,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  // Delete FCM token from current device before logout
                  await NotificationService().deleteToken();
                  print('✅ FCM token deleted on logout');
                } catch (e) {
                  print('⚠️ Error deleting FCM token on logout: $e');
                }

                await FirebaseAuth.instance.signOut();
                Get.offAllNamed(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentComplaints() {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    if (_recentComplaints.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No complaints yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Complaints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.trackComplaints);
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._recentComplaints.take(3).map((complaint) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getComplaintIcon(complaint.type),
                      color: theme.primaryColor,
                      size: 24,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy')
                              .format(complaint.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      complaint.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusTextColor(complaint.status),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _updateProfilePhoto(ProfileProvider provider) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Use ProfileProvider to update photo
      await provider.updateProfilePhoto(image.path);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusTextColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange[800]!;
      case ComplaintStatus.underReview:
        return Colors.blue[800]!;
      case ComplaintStatus.inProgress:
        return Colors.purple[800]!;
      case ComplaintStatus.resolved:
        return Colors.green[800]!;
      case ComplaintStatus.rejected:
        return Colors.red[800]!;
    }
  }

  IconData _getComplaintIcon(ComplaintType type) {
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

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange.withOpacity(0.2);
      case ComplaintStatus.underReview:
        return Colors.blue.withOpacity(0.2);
      case ComplaintStatus.inProgress:
        return Colors.purple.withOpacity(0.2);
      case ComplaintStatus.resolved:
        return Colors.green.withOpacity(0.2);
      case ComplaintStatus.rejected:
        return Colors.red.withOpacity(0.2);
    }
  }
}
