/// A bookable service or service offering from a provider.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.pricePerHour,
    required this.providerName,
    this.description,
    this.providerId,
    this.status,
    this.offers,
    this.locationDescription,
    this.availability,
    this.thingsToKnow,
    this.createdAt,
  });

  final String id;
  final String title;
  final String categoryId;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final double pricePerHour;
  final String providerName;
  final String? description;
  /// Provider user id (for creating bookings).
  final String? providerId;
  /// 'draft' | 'active' — only present for GET /mine.
  final String? status;
  /// Rich detail for premium service page.
  final String? offers;
  final String? locationDescription;
  final String? availability;
  final String? thingsToKnow;
  /// Service creation timestamp from backend.
  final DateTime? createdAt;
}
