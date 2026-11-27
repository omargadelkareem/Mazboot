class ProviderConversation {
  const ProviderConversation({
    required this.orderId,
    required this.customerId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String orderId;
  final String customerId;
  final String lastMessage;
  final int lastMessageAt;
  final int unreadCount;

  String get timeLabel {
    if (lastMessageAt <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(lastMessageAt);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${date.hour >= 12 ? 'م' : 'ص'}';
    }
    return '${date.day}/${date.month}';
  }

  factory ProviderConversation.fromMap(
    String orderId,
    Map<Object?, Object?> map,
  ) {
    return ProviderConversation(
      orderId: orderId,
      customerId: map['customerId']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageAt: (map['lastMessageAt'] as num?)?.toInt() ?? 0,
      unreadCount: (map['technicianUnreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
