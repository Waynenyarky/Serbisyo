/// A chat thread with a provider.
class MessageThreadModel {
  const MessageThreadModel({
    required this.id,
    required this.providerName,
    required this.serviceTitle,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.type = 'direct',
  });

  final String id;
  final String providerName;
  final String serviceTitle;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;
  /// direct | support | booking
  final String type;
}
