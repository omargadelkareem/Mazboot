import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _BrandMarkPainter()),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Offset point(double x, double y) => Offset(size.width * x, size.height * y);

    final shield = Path()
      ..moveTo(size.width * 0.5, size.height * 0.07)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.07,
        size.width * 0.12,
        size.height * 0.22,
        size.width * 0.12,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.68,
        size.width * 0.5,
        size.height * 0.95,
        size.width * 0.5,
        size.height * 0.95,
      )
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.95,
        size.width * 0.88,
        size.height * 0.68,
        size.width * 0.88,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.22,
        size.width * 0.72,
        size.height * 0.07,
        size.width * 0.5,
        size.height * 0.07,
      )
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.navy);

    final house = Path()
      ..moveTo(point(0.27, 0.41).dx, point(0.27, 0.41).dy)
      ..lineTo(point(0.5, 0.22).dx, point(0.5, 0.22).dy)
      ..lineTo(point(0.73, 0.41).dx, point(0.73, 0.41).dy)
      ..lineTo(point(0.73, 0.68).dx, point(0.73, 0.68).dy)
      ..quadraticBezierTo(
        point(0.5, 0.76).dx,
        point(0.5, 0.76).dy,
        point(0.27, 0.68).dx,
        point(0.27, 0.68).dy,
      )
      ..close();
    canvas.drawPath(house, Paint()..color = Colors.white);

    final roofPaint = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final roof = Path()
      ..moveTo(point(0.22, 0.4).dx, point(0.22, 0.4).dy)
      ..lineTo(point(0.5, 0.17).dx, point(0.5, 0.17).dy)
      ..lineTo(point(0.78, 0.4).dx, point(0.78, 0.4).dy);
    canvas.drawPath(roof, roofPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.66,
          size.height * 0.2,
          size.width * 0.1,
          size.height * 0.18,
        ),
        Radius.circular(size.width * 0.02),
      ),
      Paint()..color = AppColors.orange,
    );

    final checkPaint = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final check = Path()
      ..moveTo(point(0.34, 0.51).dx, point(0.34, 0.51).dy)
      ..lineTo(point(0.46, 0.63).dx, point(0.46, 0.63).dy)
      ..lineTo(point(0.68, 0.4).dx, point(0.68, 0.4).dy);
    canvas.drawPath(check, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.compact = false,
    this.markSize = 72,
  });

  final bool compact;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final wordmark = Text(
      AppConstants.appName.toUpperCase(),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w700,
        fontSize: compact ? 20 : 36,
        height: 1,
        letterSpacing: compact ? 0.7 : 1.4,
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: markSize),
          const SizedBox(width: 8),
          wordmark,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(height: 10),
        wordmark,
      ],
    );
  }
}
