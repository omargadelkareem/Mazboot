class TechnicianReview {
  const TechnicianReview({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final int rating;
  final String comment;
  final int createdAt;

  factory TechnicianReview.fromMap(String id, Map<Object?, Object?> map) =>
      TechnicianReview(
        id: id,
        orderId: map['orderId']?.toString() ?? '',
        customerId: map['customerId']?.toString() ?? '',
        customerName: map['customerName']?.toString() ?? 'عميل مظبوط',
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        comment: map['comment']?.toString() ?? '',
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => {
    'orderId': orderId,
    'customerId': customerId,
    'customerName': customerName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt,
  };
}
