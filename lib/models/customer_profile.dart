import 'address.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.governorate,
    required this.area,
    this.email = '',
    this.avatarBase64,
    this.avatarUrl,
    this.createdAt = 0,
    this.addresses = const <CustomerAddress>[],
  });

  final String uid;
  final String name;
  final String phone;
  final String governorate;
  final String area;
  final String email;
  final String? avatarBase64;
  final String? avatarUrl;
  final int createdAt;
  final List<CustomerAddress> addresses;

  String get locationLabel {
    if (governorate.isEmpty && area.isEmpty) return 'حدد موقعك';
    return [governorate, area].where((value) => value.isNotEmpty).join('، ');
  }

  factory CustomerProfile.fromMap(String uid, Map<Object?, Object?> map) {
    final rawAddresses = map['addresses'];
    final addresses = <CustomerAddress>[];
    if (rawAddresses is Map<Object?, Object?>) {
      for (final entry in rawAddresses.entries) {
        if (entry.value is Map<Object?, Object?>) {
          addresses.add(
            CustomerAddress.fromMap(
              entry.key.toString(),
              entry.value! as Map<Object?, Object?>,
            ),
          );
        }
      }
    }
    return CustomerProfile(
      uid: uid,
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      governorate: map['governorate']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      avatarBase64: map['avatarBase64']?.toString(),
      avatarUrl: map['avatarUrl']?.toString(),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      addresses: addresses,
    );
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'phone': phone,
    'governorate': governorate,
    'area': area,
    'email': email,
    if (avatarBase64 != null) 'avatarBase64': avatarBase64,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'createdAt': createdAt,
  };

  CustomerProfile copyWith({
    String? name,
    String? phone,
    String? governorate,
    String? area,
    String? email,
    String? avatarBase64,
    String? avatarUrl,
    List<CustomerAddress>? addresses,
  }) {
    return CustomerProfile(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
      email: email ?? this.email,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      addresses: addresses ?? this.addresses,
    );
  }
}
