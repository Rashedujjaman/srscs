import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../services/contractor_service.dart';
import '../../../contractor/data/models/contractor_model.dart';

/// Admin Contractor Detail Screen
///
/// Shows detailed information about a specific contractor
class AdminContractorDetailScreen extends StatefulWidget {
  const AdminContractorDetailScreen({super.key});

  @override
  State<AdminContractorDetailScreen> createState() =>
      _AdminContractorDetailScreenState();
}

class _AdminContractorDetailScreenState
    extends State<AdminContractorDetailScreen> {
  final ContractorService _contractorService = ContractorService();
  late ContractorModel contractor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    contractor = Get.arguments as ContractorModel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Details'),
        backgroundColor: UserRoleExtension(UserRole.admin).color,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      contractor.isActive ? Icons.block : Icons.check_circle,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(contractor.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_area',
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 8),
                    Text('Change Area'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card with avatar
                  _buildHeaderCard(),

                  const SizedBox(height: 16),

                  // Contact Information
                  _buildSectionCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    children: [
                      _buildInfoRow(Icons.email, 'Email', contractor.email),
                      _buildInfoRow(
                          Icons.phone, 'Phone', contractor.phoneNumber),
                      _buildInfoRow(Icons.location_on, 'Assigned Area',
                          contractor.assignedArea ?? 'N/A'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Account Status
                  _buildSectionCard(
                    title: 'Account Status',
                    icon: Icons.info,
                    children: [
                      _buildInfoRow(
                        Icons.verified_user,
                        'Status',
                        contractor.isActive ? 'Active' : 'Inactive',
                        valueColor:
                            contractor.isActive ? Colors.green : Colors.red,
                      ),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Created',
                        _formatDate(contractor.createdAt),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Statistics (placeholder for future implementation)
                  _buildSectionCard(
                    title: 'Performance Statistics',
                    icon: Icons.bar_chart,
                    children: [
                      _buildStatRow('Total Assigned', '0'),
                      _buildStatRow('Completed', '0'),
                      _buildStatRow('In Progress', '0'),
                      _buildStatRow('Pending', '0'),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            UserRoleExtension(UserRole.admin).color,
            UserRoleExtension(UserRole.admin).color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              contractor.fullName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: UserRoleExtension(UserRole.admin).color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            contractor.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: contractor.isActive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              contractor.isActive ? 'ACTIVE' : 'INACTIVE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: UserRoleExtension(UserRole.admin).color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleMenuAction(String action) async {
    if (action == 'toggle_status') {
      await _toggleStatus();
    } else if (action == 'change_area') {
      await _showChangeAreaDialog();
    }
  }

  Future<void> _toggleStatus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contractor.isActive
            ? 'Deactivate Contractor'
            : 'Activate Contractor'),
        content: Text(
          contractor.isActive
              ? 'Are you sure you want to deactivate ${contractor.fullName}? They will no longer receive new assignments.'
              : 'Are you sure you want to activate ${contractor.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: contractor.isActive ? Colors.red : Colors.green,
            ),
            child: Text(contractor.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _contractorService.toggleContractorStatus(contractor.id);
        setState(() {
          contractor = contractor.copyWith(isActive: !contractor.isActive);
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Contractor ${contractor.isActive ? "activated" : "deactivated"} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showChangeAreaDialog() async {
    String? selectedArea = contractor.assignedArea;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Assigned Area'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Area: ${contractor.assignedArea}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedArea,
                  decoration: const InputDecoration(
                    labelText: 'New Area',
                    border: OutlineInputBorder(),
                  ),
                  items: AvailableAreas.areas
                      .map((area) => DropdownMenuItem(
                            value: area,
                            child: Text(area),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedArea = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: UserRoleExtension(UserRole.admin).color,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        selectedArea != null &&
        selectedArea != contractor.assignedArea) {
      setState(() => _isLoading = true);
      try {
        await _contractorService.updateContractorArea(
            contractor.id, selectedArea!);
        setState(() {
          contractor = contractor.copyWith(assignedArea: selectedArea);
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Area updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
