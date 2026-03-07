class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.roleType,
    required this.ratingOverall,
    required this.ratings,
    required this.comment,
    this.serviceId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final String roleType;
  final double ratingOverall;
  final Map<String, num> ratings;
  final String comment;
  final String? serviceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReviewModel.fromJson(Map<String, dynamic> m) {
    final ratingsRaw = m['ratings'];
    final normalizedRatings = <String, num>{};
    if (ratingsRaw is Map<String, dynamic>) {
      ratingsRaw.forEach((key, value) {
        if (value is num) normalizedRatings[key] = value;
      });
    }
    final createdAtRaw = m['createdAt']?.toString();
    final updatedAtRaw = m['updatedAt']?.toString();
    return ReviewModel(
      id: (m['id'] ?? '').toString(),
      bookingId: (m['bookingId'] ?? '').toString(),
      reviewerId: (m['reviewerId'] ?? '').toString(),
      revieweeId: (m['revieweeId'] ?? '').toString(),
      roleType: (m['roleType'] ?? '').toString(),
      ratingOverall: (m['ratingOverall'] as num?)?.toDouble() ?? 0,
      ratings: normalizedRatings,
      comment: (m['comment'] ?? '').toString(),
      serviceId: m['serviceId']?.toString(),
      createdAt: createdAtRaw != null && createdAtRaw.isNotEmpty ? DateTime.tryParse(createdAtRaw) : null,
      updatedAt: updatedAtRaw != null && updatedAtRaw.isNotEmpty ? DateTime.tryParse(updatedAtRaw) : null,
    );
  }
}
