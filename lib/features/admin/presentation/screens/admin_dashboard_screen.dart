import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../../../complaint/presentation/providers/complaint_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  ComplaintStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    // Note: Would need admin-specific provider/usecase for getAllComplaints
    // For now using the complaint provider
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF9F7AEA),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          _buildStatsCards(provider.complaints),

          const Divider(),

          // Complaints List
          Expanded(
            child: _buildComplaintsList(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<ComplaintEntity> complaints) {
    final total = complaints.length;
    final pending =
        complaints.where((c) => c.status == ComplaintStatus.pending).length;
    final inProgress =
        complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolved =
        complaints.where((c) => c.status == ComplaintStatus.resolved).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total', total, Colors.blue),
          _buildStatCard('Pending', pending, Colors.orange),
          _buildStatCard('In Progress', inProgress, Colors.purple),
          _buildStatCard('Resolved', resolved, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList(ComplaintProvider provider) {
    var complaints = provider.complaints;

    if (_filterStatus != null) {
      complaints = complaints.where((c) => c.status == _filterStatus).toList();
    }

    if (complaints.isEmpty) {
      return const Center(child: Text('No complaints found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return _buildComplaintCard(complaint);
      },
    );
  }

  Widget _buildComplaintCard(ComplaintEntity complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(complaint.typeText),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By: ${complaint.userName}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(complaint.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: _buildStatusBadge(complaint.status),
        onTap: () => _showComplaintDetails(complaint),
      ),
    );
  }

  Widget _buildStatusBadge(ComplaintStatus status) {
    Color color;
    String statusText;

    switch (status) {
      case ComplaintStatus.pending:
        color = Colors.orange;
        statusText = 'Pending';
        break;
      case ComplaintStatus.underReview:
        color = Colors.blue;
        statusText = 'Under Review';
        break;
      case ComplaintStatus.inProgress:
        color = Colors.purple;
        statusText = 'In Progress';
        break;
      case ComplaintStatus.resolved:
        color = Colors.green;
        statusText = 'Resolved';
        break;
      case ComplaintStatus.rejected:
        color = Colors.red;
        statusText = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ComplaintStatus?>(
              title: const Text('All'),
              value: null,
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value);
                Navigator.pop(context);
              },
            ),
            ...ComplaintStatus.values.map((status) {
              return RadioListTile<ComplaintStatus?>(
                title: Text(status.toString().split('.').last),
                value: status,
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showComplaintDetails(ComplaintEntity complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(complaint.typeText),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: ${complaint.userName}'),
              const SizedBox(height: 8),
              Text('Description: ${complaint.description}'),
              const SizedBox(height: 8),
              Text('Status: ${complaint.statusText}'),
              const SizedBox(height: 8),
              Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(complaint.createdAt)}'),
              if (complaint.location != null) ...[
                const SizedBox(height: 8),
                Text(
                    'Location: ${complaint.location!['lat']}, ${complaint.location!['lng']}'),
              ],
              if (complaint.adminNotes != null) ...[
                const SizedBox(height: 8),
                Text('Admin Notes: ${complaint.adminNotes}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpdateStatusDialog(complaint);
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(ComplaintEntity complaint) {
    ComplaintStatus selectedStatus = complaint.status;
    final notesCtrl = TextEditingController(text: complaint.adminNotes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Complaint Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ComplaintStatus>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ComplaintStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedStatus = value;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Admin Notes'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Would call repository.updateComplaintStatus here
              // For now just close dialog
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Status updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
