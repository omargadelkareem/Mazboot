import 'package:equatable/equatable.dart';

enum ServiceOrderStatus {
  sent,
  accepted,
  onTheWay,
  inProgress,
  completed,
  cancelled,
}

extension ServiceOrderStatusX on ServiceOrderStatus {
  String get label => switch (this) {
    ServiceOrderStatus.sent => 'تم الإرسال',
    ServiceOrderStatus.accepted => 'تم القبول',
    ServiceOrderStatus.onTheWay => 'في الطريق',
    ServiceOrderStatus.inProgress => 'بدأ التنفيذ',
    ServiceOrderStatus.completed => 'مكتمل',
    ServiceOrderStatus.cancelled => 'ملغي',
  };
}

class ServiceOrder extends Equatable {
  const ServiceOrder({
    required this.id,
    required this.technicianId,
    required this.categoryId,
    required this.problem,
    required this.address,
    required this.date,
    required this.time,
    required this.visitFee,
    required this.status,
    this.customerId = '',
    this.createdAt = 0,
    this.updatedAt = 0,
    this.problemImageBase64,
    this.cancellationReason,
  });

  final String id;
  final String technicianId;
  final String categoryId;
  final String problem;
  final String address;
  final String date;
  final String time;
  final int visitFee;
  final ServiceOrderStatus status;
  final String customerId;
  final int createdAt;
  final int updatedAt;
  final String? problemImageBase64;
  final String? cancellationReason;

  ServiceOrder copyWith({
    ServiceOrderStatus? status,
    String? cancellationReason,
    int? updatedAt,
  }) {
    return ServiceOrder(
      id: id,
      technicianId: technicianId,
      categoryId: categoryId,
      problem: problem,
      address: address,
      date: date,
      time: time,
      visitFee: visitFee,
      status: status ?? this.status,
      customerId: customerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      problemImageBase64: problemImageBase64,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  factory ServiceOrder.fromMap(String id, Map<Object?, Object?> map) {
    return ServiceOrder(
      id: id,
      technicianId: map['technicianId']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      problem: map['problem']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      visitFee: (map['visitFee'] as num?)?.toInt() ?? 0,
      status: statusFromName(map['status']?.toString()),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
      problemImageBase64: map['problemImageBase64']?.toString(),
      cancellationReason: map['cancellationReason']?.toString(),
    );
  }

  Map<String, Object?> toMap() => {
    'technicianId': technicianId,
    'categoryId': categoryId,
    'customerId': customerId,
    'problem': problem,
    'address': address,
    'date': date,
    'time': time,
    'visitFee': visitFee,
    'status': status.name,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    if (problemImageBase64 != null) 'problemImageBase64': problemImageBase64,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
  };

  static ServiceOrderStatus statusFromName(String? name) => switch (name) {
    'sent' || 'pending' => ServiceOrderStatus.sent,
    'accepted' => ServiceOrderStatus.accepted,
    'onTheWay' || 'on_the_way' => ServiceOrderStatus.onTheWay,
    'inProgress' || 'in_progress' => ServiceOrderStatus.inProgress,
    'completed' => ServiceOrderStatus.completed,
    'cancelled' => ServiceOrderStatus.cancelled,
    _ => ServiceOrderStatus.sent,
  };

  @override
  List<Object?> get props => [
    id,
    technicianId,
    categoryId,
    problem,
    address,
    date,
    time,
    visitFee,
    status,
    customerId,
    createdAt,
    updatedAt,
    problemImageBase64,
    cancellationReason,
  ];
}
