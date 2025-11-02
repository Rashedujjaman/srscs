class ProfileEntity {
  final String id;
  final String nid;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? bloodGroup;
  final String? dob;
  final String? profilePhotoUrl;
  final DateTime? updatedAt;
  final String? role; // 'citizen', 'contractor', 'admin'
  final int? honorScore;

  ProfileEntity({
    required this.id,
    required this.nid,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.address,
    this.bloodGroup,
    this.dob,
    this.profilePhotoUrl,
    this.updatedAt,
    this.role,
    this.honorScore,
  });
}
