class Conversation {
  const Conversation({
    this.orderId = '',
    required this.technicianId,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });

  final String orderId;
  final String technicianId;
  final String lastMessage;
  final String time;
  final int unreadCount;

  factory Conversation.fromMap(String orderId, Map<Object?, Object?> map) {
    return Conversation(
      orderId: orderId,
      technicianId: map['technicianId']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      time:
          map['lastMessageTimeLabel']?.toString() ??
          _timeLabel((map['lastMessageAt'] as num?)?.toInt() ?? 0),
      unreadCount: (map['customerUnreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  static String _timeLabel(int milliseconds) {
    if (milliseconds <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'م' : 'ص'}';
    }
    return '${date.day}/${date.month}';
  }
}
