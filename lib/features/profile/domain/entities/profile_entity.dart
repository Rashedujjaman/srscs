class ProfileEntity {
  final String id;
  final String nid;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? bloodGroup;
  final DateTime? dob;
  final String? profilePhotoUrl;
  final DateTime? updatedAt;

  ProfileEntity({
    required this.id,
    required this.nid,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.bloodGroup,
    this.dob,
    this.profilePhotoUrl,
    this.updatedAt,
  });

  ProfileEntity copyWith({
    String? id,
    String? nid,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? bloodGroup,
    DateTime? dob,
    String? profilePhotoUrl,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      nid: nid ?? this.nid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dob: dob ?? this.dob,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
