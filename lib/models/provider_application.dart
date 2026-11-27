import 'package:equatable/equatable.dart';

enum ProviderApplicationStatus { pending, approved, rejected }

class ProviderApplication extends Equatable {
  const ProviderApplication({
    required this.id,
    required this.applicantUid,
    required this.name,
    required this.phone,
    required this.categoryId,
    required this.governorate,
    required this.area,
    required this.photoBase64,
    required this.submittedAt,
    this.status = ProviderApplicationStatus.pending,
    this.reviewNote = '',
    this.subscriptionActive = false,
    this.monthlySubscriptionAmount = 50,
    this.published = false,
    this.subscriptionStartedAt = 0,
    this.subscriptionExpiresAt = 0,
    this.lastPaymentAt = 0,
  });

  final String id;
  final String applicantUid;
  final String name;
  final String phone;
  final String categoryId;
  final String governorate;
  final String area;
  final String photoBase64;
  final int submittedAt;
  final ProviderApplicationStatus status;
  final String reviewNote;
  final bool subscriptionActive;
  final int monthlySubscriptionAmount;
  final bool published;
  final int subscriptionStartedAt;
  final int subscriptionExpiresAt;
  final int lastPaymentAt;

  bool get isFullyActive =>
      status == ProviderApplicationStatus.approved &&
      subscriptionActive &&
      published;

  factory ProviderApplication.fromMap(String id, Map<Object?, Object?> map) {
    return ProviderApplication(
      id: id,
      applicantUid: map['applicantUid']?.toString() ?? id,
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      governorate: map['governorate']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      photoBase64: map['photoBase64']?.toString() ?? '',
      submittedAt: (map['submittedAt'] as num?)?.toInt() ?? 0,
      status: _statusFromName(map['status']?.toString()),
      reviewNote: map['reviewNote']?.toString() ?? '',
      subscriptionActive: map['subscriptionActive'] as bool? ?? false,
      monthlySubscriptionAmount:
          (map['monthlySubscriptionAmount'] as num?)?.toInt() ?? 50,
      published: map['published'] as bool? ?? false,
      subscriptionStartedAt:
          (map['subscriptionStartedAt'] as num?)?.toInt() ?? 0,
      subscriptionExpiresAt:
          (map['subscriptionExpiresAt'] as num?)?.toInt() ?? 0,
      lastPaymentAt: (map['lastPaymentAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'applicantUid': applicantUid,
    'name': name,
    'phone': phone,
    'categoryId': categoryId,
    'governorate': governorate,
    'area': area,
    'photoBase64': photoBase64,
    'submittedAt': submittedAt,
    'status': status.name,
    'reviewNote': reviewNote,
    'subscriptionActive': subscriptionActive,
    'monthlySubscriptionAmount': monthlySubscriptionAmount,
    'published': published,
    if (subscriptionStartedAt > 0)
      'subscriptionStartedAt': subscriptionStartedAt,
    if (subscriptionExpiresAt > 0)
      'subscriptionExpiresAt': subscriptionExpiresAt,
    if (lastPaymentAt > 0) 'lastPaymentAt': lastPaymentAt,
  };

  static ProviderApplicationStatus _statusFromName(String? value) {
    return switch (value) {
      'approved' => ProviderApplicationStatus.approved,
      'rejected' => ProviderApplicationStatus.rejected,
      _ => ProviderApplicationStatus.pending,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    applicantUid,
    name,
    phone,
    categoryId,
    governorate,
    area,
    photoBase64,
    submittedAt,
    status,
    reviewNote,
    subscriptionActive,
    monthlySubscriptionAmount,
    published,
    subscriptionStartedAt,
    subscriptionExpiresAt,
    lastPaymentAt,
  ];
}
