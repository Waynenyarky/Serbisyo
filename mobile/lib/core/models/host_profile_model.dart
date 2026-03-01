class HostProfile {
  const HostProfile({
    required this.id,
    required this.fullName,
    required this.bio,
    required this.serviceArea,
    required this.avatarUrl,
    required this.isVerified,
  });

  final String id;
  final String fullName;
  final String bio;
  final String serviceArea;
  final String? avatarUrl;
  final bool isVerified;
}

