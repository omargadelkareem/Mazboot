class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final int createdAt;
  final String? orderId;
  final bool isRead;

  factory AppNotification.fromMap(String id, Map<Object?, Object?> map) =>
      AppNotification(
        id: id,
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
        orderId: map['orderId']?.toString(),
        isRead: map['isRead'] as bool? ?? false,
      );
}
