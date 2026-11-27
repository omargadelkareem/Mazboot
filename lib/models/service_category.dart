import 'package:flutter/material.dart';

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.roomIds,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final List<String> roomIds;
  final bool isActive;
  final int sortOrder;

  factory ServiceCategory.fromMap(String id, Map<Object?, Object?> map) {
    final roomIds = (map['roomIds'] as List<Object?>? ?? const <Object?>[])
        .map((item) => item.toString())
        .toList();
    return ServiceCategory(
      id: id,
      name: map['name']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      icon: iconFromName(map['icon']?.toString()),
      backgroundColor: colorFromHex(map['color']?.toString()),
      roomIds: roomIds,
      isActive: map['isActive'] as bool? ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'subtitle': subtitle,
    'icon': iconName(icon),
    'color':
        '#${backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'roomIds': roomIds,
    'isActive': isActive,
    'sortOrder': sortOrder,
  };

  static Color colorFromHex(String? value) {
    if (value == null || value.isEmpty) return const Color(0xFFEAF4FB);
    final cleaned = value.replaceFirst('#', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFFEAF4FB);
  }

  static IconData iconFromName(String? value) => switch (value) {
    'plumbing' => Icons.plumbing_rounded,
    'ac' => Icons.ac_unit_rounded,
    'carpentry' => Icons.carpenter_rounded,
    'painting' => Icons.format_paint_rounded,
    'cleaning' => Icons.cleaning_services_rounded,
    'appliances' => Icons.home_repair_service_rounded,
    'satellite' => Icons.satellite_alt_rounded,
    'aluminum' => Icons.window_rounded,
    'gypsum' => Icons.dashboard_customize_rounded,
    'pest' => Icons.pest_control_rounded,
    'moving' => Icons.local_shipping_outlined,
    'locksmith' => Icons.key_rounded,
    'security' => Icons.videocam_outlined,
    _ => Icons.bolt_rounded,
  };

  static String iconName(IconData icon) {
    if (icon == Icons.plumbing_rounded) return 'plumbing';
    if (icon == Icons.ac_unit_rounded) return 'ac';
    if (icon == Icons.carpenter_rounded) return 'carpentry';
    if (icon == Icons.format_paint_rounded) return 'painting';
    if (icon == Icons.cleaning_services_rounded) return 'cleaning';
    if (icon == Icons.home_repair_service_rounded) return 'appliances';
    if (icon == Icons.satellite_alt_rounded) return 'satellite';
    if (icon == Icons.window_rounded) return 'aluminum';
    if (icon == Icons.dashboard_customize_rounded) return 'gypsum';
    if (icon == Icons.pest_control_rounded) return 'pest';
    if (icon == Icons.local_shipping_outlined) return 'moving';
    if (icon == Icons.key_rounded) return 'locksmith';
    if (icon == Icons.videocam_outlined) return 'security';
    return 'electricity';
  }
}
