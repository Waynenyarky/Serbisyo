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
    this.imageUrl,
  });

  final String id;
  final String serviceId;
  final String serviceTitle;
  final String providerName;
  final String scheduledDate;
  final String scheduledTime;
  final String address;
  final String status; // e.g. 'upcoming', 'completed', 'cancelled'
  final double totalAmount;
  final String? imageUrl;
}
