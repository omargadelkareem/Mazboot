class Technician {
  const Technician({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.profession,
    required this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.completedJobs,
    required this.distanceKm,
    required this.visitFee,
    required this.isAvailable,
    required this.isVerified,
    required this.experienceYears,
    required this.bio,
    required this.services,
    required this.portfolioUrls,
    this.imageBase64,
    this.phone = '',
    this.governorate = '',
    this.area = '',
    this.latitude = 0,
    this.longitude = 0,
    this.approvalStatus = 'approved',
    this.subscriptionActive = true,
    this.isActive = true,
    this.subscriptionStartedAt = 0,
    this.subscriptionExpiresAt = 0,
    this.lastPaymentAt = 0,
  });

  final String id;
  final String name;
  final String categoryId;
  final String profession;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final int completedJobs;
  final double distanceKm;
  final int visitFee;
  final bool isAvailable;
  final bool isVerified;
  final int experienceYears;
  final String bio;
  final List<String> services;
  final List<String> portfolioUrls;
  final String? imageBase64;
  final String phone;
  final String governorate;
  final String area;
  final double latitude;
  final double longitude;
  final String approvalStatus;
  final bool subscriptionActive;
  final bool isActive;
  final int subscriptionStartedAt;
  final int subscriptionExpiresAt;
  final int lastPaymentAt;

  bool get canReceiveOrders =>
      approvalStatus == 'approved' &&
      subscriptionActive &&
      isActive &&
      isAvailable;

  factory Technician.fromMap(String id, Map<Object?, Object?> map) {
    List<String> strings(String key) {
      final value = map[key];
      if (value is List<Object?>)
        return value.map((item) => item.toString()).toList();
      if (value is Map<Object?, Object?>) {
        return value.values.map((item) => item.toString()).toList();
      }
      return const <String>[];
    }

    return Technician(
      id: id,
      name: map['name']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      profession: map['profession']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 0,
      completedJobs: (map['completedJobs'] as num?)?.toInt() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      visitFee: (map['visitFee'] as num?)?.toInt() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? false,
      isVerified: map['isVerified'] as bool? ?? false,
      experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 0,
      bio: map['bio']?.toString() ?? '',
      services: strings('services'),
      portfolioUrls: strings('portfolioUrls'),
      imageBase64: map['imageBase64']?.toString(),
      phone: map['phone']?.toString() ?? '',
      governorate: map['governorate']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      approvalStatus: map['approvalStatus']?.toString() ?? 'pending',
      subscriptionActive: map['subscriptionActive'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      subscriptionStartedAt:
          (map['subscriptionStartedAt'] as num?)?.toInt() ?? 0,
      subscriptionExpiresAt:
          (map['subscriptionExpiresAt'] as num?)?.toInt() ?? 0,
      lastPaymentAt: (map['lastPaymentAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'categoryId': categoryId,
    'profession': profession,
    'imageUrl': imageUrl,
    'rating': rating,
    'reviewsCount': reviewsCount,
    'completedJobs': completedJobs,
    'distanceKm': distanceKm,
    'visitFee': visitFee,
    'isAvailable': isAvailable,
    'isVerified': isVerified,
    'experienceYears': experienceYears,
    'bio': bio,
    'services': services,
    'portfolioUrls': portfolioUrls,
    if (imageBase64?.isNotEmpty == true) 'imageBase64': imageBase64,
    'phone': phone,
    'governorate': governorate,
    'area': area,
    'latitude': latitude,
    'longitude': longitude,
    'approvalStatus': approvalStatus,
    'subscriptionActive': subscriptionActive,
    'isActive': isActive,
    if (subscriptionStartedAt > 0)
      'subscriptionStartedAt': subscriptionStartedAt,
    if (subscriptionExpiresAt > 0)
      'subscriptionExpiresAt': subscriptionExpiresAt,
    if (lastPaymentAt > 0) 'lastPaymentAt': lastPaymentAt,
  };

  Technician copyWith({
    String? name,
    bool? isAvailable,
    int? experienceYears,
    String? bio,
    List<String>? services,
  }) {
    return Technician(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId,
      profession: profession,
      imageUrl: imageUrl,
      rating: rating,
      reviewsCount: reviewsCount,
      completedJobs: completedJobs,
      distanceKm: distanceKm,
      visitFee: visitFee,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      services: services ?? this.services,
      portfolioUrls: portfolioUrls,
      imageBase64: imageBase64,
      phone: phone,
      governorate: governorate,
      area: area,
      latitude: latitude,
      longitude: longitude,
      approvalStatus: approvalStatus,
      subscriptionActive: subscriptionActive,
      isActive: isActive,
      subscriptionStartedAt: subscriptionStartedAt,
      subscriptionExpiresAt: subscriptionExpiresAt,
      lastPaymentAt: lastPaymentAt,
    );
  }
}
