import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../datasources/complaint_local_data_source.dart';
import '../datasources/complaint_remote_data_source.dart';
import '../models/complaint_model.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  final ComplaintRemoteDataSource remote;
  final ComplaintLocalDataSource local;
  final Connectivity connectivity;

  ComplaintRepositoryImpl({
    required this.remote,
    required this.local,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  Future<bool> _isOnline() async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Future<String> submitComplaint({
    required String userId,
    required String userName,
    required ComplaintType type,
    required String description,
    required List<String> mediaFiles,
    Map<String, double>? location,
    String? area,
    String? landmark,
  }) async {
    final complaintId = const Uuid().v4();
    final now = DateTime.now();

    final complaint = ComplaintModel(
      id: complaintId,
      userId: userId,
      userName: userName,
      type: type,
      description: description,
      mediaUrls: [], // Will be filled after upload
      location: location,
      area: area,
      landmark: landmark,
      status: ComplaintStatus.pending,
      createdAt: now,
    );

    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        // Upload media files if any
        List<String> mediaUrls = [];
        if (mediaFiles.isNotEmpty) {
          mediaUrls = await remote.uploadMediaFiles(mediaFiles, complaintId);
        }

        // Create complaint with media URLs
        final onlineComplaint = ComplaintModel(
          id: complaintId,
          userId: userId,
          userName: userName,
          type: type,
          description: description,
          mediaUrls: mediaUrls,
          location: location,
          area: area,
          landmark: landmark,
          status: ComplaintStatus.pending,
          createdAt: now,
        );

        // Submit to Firestore
        await remote.submitComplaint(onlineComplaint);

        // Also save locally as synced
        final localComplaint = ComplaintModel(
          id: complaintId,
          userId: userId,
          userName: userName,
          type: type,
          description: description,
          mediaUrls: mediaUrls,
          location: location,
          area: area,
          landmark: landmark,
          status: ComplaintStatus.pending,
          createdAt: now,
        );
        await local.insertComplaint(localComplaint);
        await local.markAsSynced(complaintId);

        return complaintId;
      } catch (e) {
        // If online submit fails, save locally for later sync
        await local.insertComplaint(complaint);
        return complaintId;
      }
    } else {
      // Offline: save locally
      await local.insertComplaint(complaint);
      return complaintId;
    }
  }

  @override
  Future<List<ComplaintEntity>> getCitizenComplaints(String userId) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        return await remote.getCitizenComplaints(userId);
      } catch (e) {
        // Fall back to local data
        return await local.getCitizenComplaints(userId);
      }
    } else {
      return await local.getCitizenComplaints(userId);
    }
  }

  @override
  Future<List<ComplaintEntity>> getContractorComplaints(
      String contractorId) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        return await remote.getContractorComplaints(contractorId);
      } catch (e) {
        // Fall back to local data
        return await local.getContractorComplaints(contractorId);
      }
    } else {
      return await local.getContractorComplaints(contractorId);
    }
  }

  @override
  Future<List<ComplaintEntity>> getAllComplaints() async {
    return await remote.getAllComplaints();
  }

  @override
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminNotes,
    String? assignedTo,
  }) async {
    await remote.updateComplaintStatus(
      complaintId: complaintId,
      status: status,
      adminNotes: adminNotes,
      assignedTo: assignedTo,
    );
  }

  @override
  Future<void> syncOfflineComplaints() async {
    final isOnline = await _isOnline();
    if (!isOnline) return;

    final unsyncedComplaints = await local.getUnsyncedComplaints();

    for (final complaint in unsyncedComplaints) {
      try {
        // Upload to Firestore
        await remote.submitComplaint(complaint);
        // Mark as synced
        await local.markAsSynced(complaint.id);
      } catch (e) {
        // Skip this complaint and continue with others
        continue;
      }
    }
  }

  @override
  Future<int> getUnsyncedCount() async {
    return await local.getUnsyncedCount();
  }
}
