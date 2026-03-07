class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.providerId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.refundedAmount,
    this.providerRef,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String userId;
  final String providerId;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final double refundedAmount;
  final String? providerRef;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentModel.fromJson(Map<String, dynamic> m) {
    final createdAtRaw = m['createdAt']?.toString();
    final updatedAtRaw = m['updatedAt']?.toString();
    return PaymentModel(
      id: (m['id'] ?? '').toString(),
      bookingId: (m['bookingId'] ?? '').toString(),
      userId: (m['userId'] ?? '').toString(),
      providerId: (m['providerId'] ?? '').toString(),
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      currency: (m['currency'] ?? 'PHP').toString(),
      method: (m['method'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      refundedAmount: (m['refundedAmount'] as num?)?.toDouble() ?? 0,
      providerRef: m['providerRef']?.toString(),
      createdAt: createdAtRaw != null && createdAtRaw.isNotEmpty ? DateTime.tryParse(createdAtRaw) : null,
      updatedAt: updatedAtRaw != null && updatedAtRaw.isNotEmpty ? DateTime.tryParse(updatedAtRaw) : null,
    );
  }
}
