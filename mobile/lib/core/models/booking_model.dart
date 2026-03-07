/// A booking made by the customer.
class BookingModel {
  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.providerName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.address,
    required this.status,
    required this.totalAmount,
    this.scheduledAt,
    this.userId,
    this.providerId,
    this.imageUrl,
    this.statusReason,
    this.respondedAt,
    this.cancelledAt,
    this.completedAt,
    this.statusUpdatedBy,
    this.cancelledByRole,
    this.cancellationPolicy = 'flexible',
    this.refundAmount = 0,
    this.paymentStatus = 'unpaid',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String serviceId;
  final String serviceTitle;
  final String providerName;
  final String scheduledDate;
  final String scheduledTime;
  final String address;
  final String status; // pending|confirmed|declined|cancelled|ongoing|completed
  final double totalAmount;
  final DateTime? scheduledAt;
  final String? userId;
  final String? providerId;
  final String? imageUrl;
  final String? statusReason;
  final DateTime? respondedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final String? statusUpdatedBy;
  final String? cancelledByRole;
  final String cancellationPolicy;
  final double refundAmount;
  final String paymentStatus; // unpaid|authorized|paid|refunded|failed
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
