import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.base64Data,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
  });

  final String url;
  final String? base64Data;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final memoryBytes = _decodeBase64(base64Data);
    if (memoryBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          memoryBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    if (url.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _fallback(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: AppColors.powderBlue,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.navy,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    width: width,
    height: height,
    color: AppColors.powderBlue,
    alignment: Alignment.center,
    child: const Icon(Icons.person_rounded, color: AppColors.navy, size: 34),
  );

  static Uint8List? _decodeBase64(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }
}
