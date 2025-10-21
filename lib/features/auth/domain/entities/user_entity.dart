class UserEntity {
  final String id;
  final String nid;
  final String fullName;
  final DateTime? dob;
  final String? address;
  final String? bloodGroup;
  final String? imageUrl;
  final String? phoneNumber;
  final String? email;

  UserEntity({
    required this.id,
    required this.nid,
    required this.fullName,
    this.dob,
    this.address,
    this.bloodGroup,
    this.imageUrl,
    this.phoneNumber,
    this.email,
  });
}
