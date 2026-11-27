import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF00B8D4);
  static const Color primaryDark = Color(0xFF008B9B);
  static const Color primarySoft = Color(0xFFE8FAFD);
  static const Color ink = Color(0xFF102A43);

  // Legacy aliases keep the existing business screens compatible while the
  // whole product follows the new white + cyan مظبوط identity.
  static const Color navy = ink;
  static const Color navyDark = Color(0xFF071C2E);
  static const Color orange = primary;
  static const Color orangeSoft = primarySoft;
  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Colors.white;
  static const Color text = ink;
  static const Color textMuted = Color(0xFF6C7C8D);
  static const Color border = Color(0xFFE5EDF1);
  static const Color powderBlue = primarySoft;
  static const Color powderPurple = Color(0xFFF2F0FF);
  static const Color powderGreen = Color(0xFFEAF8F1);
  static const Color powderPeach = Color(0xFFFFF5E8);
  static const Color success = Color(0xFF19A463);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFE5484D);
}
