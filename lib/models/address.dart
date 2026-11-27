class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.details,
    required this.governorate,
    required this.area,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String details;
  final String governorate;
  final String area;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  factory CustomerAddress.fromMap(String id, Map<Object?, Object?> map) {
    return CustomerAddress(
      id: id,
      label: map['label']?.toString() ?? 'المنزل',
      details: map['details']?.toString() ?? '',
      governorate: map['governorate']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => {
    'label': label,
    'details': details,
    'governorate': governorate,
    'area': area,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'isDefault': isDefault,
  };
}
