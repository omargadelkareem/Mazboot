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
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.29),
    );
    canvas.drawRRect(background, Paint()..color = AppColors.primary);

    final roofPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final roof = Path()
      ..moveTo(point(0.2, 0.47).dx, point(0.2, 0.47).dy)
      ..lineTo(point(0.5, 0.21).dx, point(0.5, 0.21).dy)
      ..lineTo(point(0.8, 0.47).dx, point(0.8, 0.47).dy);
    canvas.drawPath(roof, roofPaint);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final check = Path()
      ..moveTo(point(0.31, 0.58).dx, point(0.31, 0.58).dy)
      ..lineTo(point(0.45, 0.7).dx, point(0.45, 0.7).dy)
      ..lineTo(point(0.72, 0.43).dx, point(0.72, 0.43).dy);
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
      AppConstants.appName,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: compact ? 23 : 38,
        height: 1,
      ),
    );

    if (compact) {
      return Row(
        textDirection: TextDirection.rtl,
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
