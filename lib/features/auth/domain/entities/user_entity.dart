class UserEntity {
  final String id;
  final String nid;
  final String fullName;
  final DateTime? dob;
  final String? address;
  final String? bloodGroup;

  UserEntity({
    required this.id,
    required this.nid,
    required this.fullName,
    this.dob,
    this.address,
    this.bloodGroup,
  });
}
