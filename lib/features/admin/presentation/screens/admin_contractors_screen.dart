import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../services/contractor_service.dart';
import '../../../contractor/data/models/contractor_model.dart';

/// Admin Contractors Screen
///
/// Shows list of all contractors with management capabilities
class AdminContractorsScreen extends StatefulWidget {
  const AdminContractorsScreen({super.key});

  @override
  State<AdminContractorsScreen> createState() => _AdminContractorsScreenState();
}

class _AdminContractorsScreenState extends State<AdminContractorsScreen> {
  final ContractorService _contractorService = ContractorService();
  String _filterArea = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractors'),
        backgroundColor: UserRoleExtension(UserRole.admin).color,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.toNamed(AppRoutes.adminContractorCreate);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<ContractorModel>>(
              stream: _contractorService.getAllContractors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.engineering,
                          size: 100,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contractors yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.toNamed(AppRoutes.adminContractorCreate);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Contractor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                UserRoleExtension(UserRole.admin).color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter contractors
                List<ContractorModel> contractors = snapshot.data!;

                if (_filterArea != 'All') {
                  contractors = contractors
                      .where((c) => c.assignedArea == _filterArea)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  contractors = contractors.where((c) {
                    return c.fullName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        c.email
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        c.phoneNumber.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: contractors.length,
                  itemBuilder: (context, index) {
                    return _buildContractorCard(contractors[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),

          // Area filter
          Row(
            children: [
              const Text('Filter by Area: ',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      ...AvailableAreas.areas
                          .take(10)
                          .map((area) => _buildFilterChip(area)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String area) {
    final isSelected = _filterArea == area;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(area),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterArea = area;
          });
        },
        selectedColor: UserRoleExtension(UserRole.admin).color.withOpacity(0.3),
        checkmarkColor: UserRoleExtension(UserRole.admin).color,
      ),
    );
  }

  Widget _buildContractorCard(ContractorModel contractor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contractor.isActive ? Colors.green : Colors.grey,
          child: Text(
            contractor.fullName[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          contractor.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(contractor.assignedArea),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(contractor.phoneNumber),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: contractor.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                contractor.isActive ? 'Active' : 'Inactive',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Get.toNamed(
            AppRoutes.adminContractorDetail,
            arguments: contractor,
          );
        },
      ),
    );
  }
}
